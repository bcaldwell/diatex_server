require 'sinatra'
require 'json'
require 'logger'
# require "sinatra/json"
# require 'calculus'

require 'byebug'
require 'tmpdir'

require './lib/image_maker'
require './lib/sequence_diagram'


class Diatex < Sinatra::Base
  include SequenceDiagram
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    username == 'diatex' and password == Application.secrets[:diatex_password]
  end

  get '/' do
    "Welcome to DiaTeX server"
  end

  post '/latex' do
    content_type :json
    if params[:latex].nil?
      status 422
      return {error: "latex param was not found"}.to_json
    end

    latex = CGI.unescape(params[:latex])
    uid = Digest::MD5.hexdigest(latex)
    remote_path = "latex/#{uid}.png"

    Application.logger.info "Got latex #{latex}"

    # Check Cache First
    if cache = image_cache(latex, remote_path)
      return cache
    end

    # Generate Image & send reponse
    exp = Calculus::Expression.new(latex, parse: false)
    new_path = File.join(Application.constants[:TEMP_IMAGES], "#{uid}.png")
    png = exp.to_png
    Application.logger.info "Calculus"
    Application.logger.info png
    Application.logger.info exp.inspect
    FileUtils.mv(png, new_path)

    json_hash = ImageMaker.new.create_image("#{uid}.png", remote_path, new_path)
    
    FileUtils.rm(new_path)

    { input: params[:latex], url: json_hash[:url] }.to_json
  end

  post '/diagram' do
    content_type :json

    diagram = params[:diagram]

    if diagram.nil?
      status 422
      return { error: "diagram param was not found" }.to_json
    end

    uid = Digest::MD5.hexdigest(diagram)
    remote_path = "diagram/#{uid}.png"

    # Check Cache First
    if cache = image_cache(diagram, remote_path)
      return cache
    end

    # Generate Image
    success, png_path = convert_mermaid_to_png(diagram)
    unless success
      status 500
      return { error: 'mermaid command did not succeed', input: diagram, output: png_path }.to_json
    end

    # Send response
    json_hash = ImageMaker.new.create_image("#{uid}.png", remote_path, png_path)
    { input: diagram, url: json_hash[:url] }.to_json
  end

  private

  def image_cache(param, remote_path)
    image_maker = ImageMaker.new

    # Check for Cache
    if image_maker.exists?(remote_path)
      Application.logger.info "Already made, sending cache"
      return { input: param, url: image_maker.url(remote_path) }.to_json
    end

    false
  end
end