require 'sinatra'
require 'json'
require 'logger'
# require "sinatra/json"
# require 'calculus'

require 'byebug'
require 'tmpdir'

require './lib/image_maker'


class Diatex < Sinatra::Base
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    username == 'diatex' and password == Application.secrets[:diatex_password]
  end

  get '/' do
    "Welcome to DiaTeX server"
  end

  get '/latex' do
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

    return { input: params[:latex], url: json_hash[:url] }.to_json
  end

  get '/diagram' do
    'diagram'
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