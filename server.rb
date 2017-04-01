require 'sinatra'
require 'json'

require './lib/image_maker'
require './lib/sequence_diagram'
require 'lib/github_client'

require 'sinatra/reloader' if development?

require 'byebug'

class Diatex < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  include SequenceDiagram
  unless development?
    use Rack::Auth::Basic, 'Restricted Area' do |username, password|
      username == 'diatex' && password == Application.secrets[:diatex_password]
    end
  end

  helpers do
    if development?
      def protected!
        nil
      end
    else
      def protected!
        return if authorized?
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        halt 401, "Not authorized\n"
      end

      def authorized?
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['diatex', Application.secrets[:diatex_password]]
      end
    end

    def parse_params
      @cdn_url = params[:cdn_url]
      @github_repo = params[:github_repo]
    end
  end

  get '/' do
    'Welcome to DiaTeX server'
  end

  post '/github/webhook' do
  end

  post '/latex' do
    protected!
    parse_params
    content_type :json

    if params[:latex].nil?
      status 422
      return { error: 'latex param was not found' }.to_json
    end

    latex = CGI.unescape(params[:latex])
    uid = Digest::MD5.hexdigest(latex)
    remote_path = "latex/#{uid}.png"

    Application.logger.info "Got latex #{latex}"

    image_maker = ImageMaker.new(cdn_url: @cdn_url, github_repo: @github_repo)

    # Check Cache First
    if cache = image_maker.image_cache(latex, remote_path)
      return cache
    end

    # Generate Image & send reponse
    exp = Calculus::Expression.new(latex, parse: false)
    new_path = File.join(Application.constants[:TEMP_IMAGES], "#{uid}.png")
    png = exp.to_png
    Application.logger.info 'Calculus'
    Application.logger.info png
    Application.logger.info exp.inspect
    FileUtils.mv(png, new_path)

    json_hash = image_maker.create_image("#{uid}.png", remote_path, new_path)

    FileUtils.rm(new_path)

    { input: params[:latex], url: json_hash[:url] }.to_json
  end

  post '/diagram' do
    protected!
    parse_params
    content_type :json

    diagram = params[:diagram]

    if diagram.nil?
      status 422
      return { error: 'diagram param was not found' }.to_json
    end

    uid = Digest::MD5.hexdigest(diagram)
    remote_path = "diagram/#{uid}.png"

    image_maker = ImageMaker.new(cdn_url: @cdn_url, github_repo: @github_repo)

    # Check Cache First
    if cache = image_maker.image_cache(diagram, remote_path)
      return cache
    end

    # Generate Image
    success, png_path = convert_mermaid_to_png(diagram)
    unless success
      status 500
      return { error: 'mermaid command did not succeed', input: diagram, output: png_path }.to_json
    end

    # Send response
    json_hash = image_maker.create_image("#{uid}.png", remote_path, png_path)
    { input: diagram, url: json_hash[:url] }.to_json
  end
end
