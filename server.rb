require 'sinatra'
require 'json'
require 'logger'
# require "sinatra/json"
# require 'calculus'
require 'byebug'
require 'tmpdir'

require './lib/image_maker'


class Diatex < Sinatra::Base
  log = Logger.new(STDOUT)

  diatex_password = ENV["DIATEX_PASSWORD"]
  raise "no diatex password set. Set DIATEX_PASSWORD env variable" if diatex_password.nil? || diatex_password.empty?

  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    username == 'diatex' and password == diatex_password
  end

  get '/' do
    "Welcome to diatex server"
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

    log.info "Got latex #{latex}"

    # Check Cache First
    return if image_cache(latex, remote_path)

    # Generate Image & send reponse
    exp = Calculus::Expression.new(latex, parse: false)
    new_path = File.join(TEMP_IMAGES, "#{uid}.png")
    png = exp.to_png
    log.info "Calculus"
    log.info png
    log.info exp.inspect
    FileUtils.mv(png, new_path)

    json_hash = ImageMaker.new.create_image("#{uid}.png", remote_path, new_path)
    
    FileUtils.rm(new_path)

    { input: params[:latex], url: json_hash[:url] }
  end

  get '/diagram' do
    'diagram'
  end

  private

  def image_cache(param, remote_path)
    image_maker = ImageMaker.new

    # Check for Cache
    if image_maker.exists?(remote_path)
      log.info "Already made, sending cache"
      # render json: { input: param, url: image_maker.url(remote_path) }
      return true
    end

    false
  end
end