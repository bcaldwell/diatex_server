require 'tmpdir'
require 'logger'
require 'octokit'
require 'open3'
require 'pathname'
require 'json'
require 'jwt'


require 'byebug'
module Application
  # we don't want to instantiate this class - it's a singleton,
  # so just keep it as a self-extended module
  extend self

  @constants = {}
  @logger = Logger.new(STDOUT)
  @secrets = {}
  @GithubClient

  attr_accessor :constants, :secrets, :logger, :GithubClient
  # Main Path
  temp = Dir.tmpdir()
  output_temp_dir = File.join(temp, 'diatex').freeze
  FileUtils.mkdir_p(output_temp_dir) unless File.exist?(output_temp_dir)

  # Temporary Mermaid
  @constants[:TEMP_MERMAID] = "#{output_temp_dir}/mermaid".freeze
  FileUtils.mkdir_p(@constants[:TEMP_MERMAID]) unless File.exist?(@constants[:TEMP_MERMAID])

  # Temporary images folder
  @constants[:TEMP_IMAGES] = "#{output_temp_dir}/images".freeze
  FileUtils.mkdir_p(@constants[:TEMP_IMAGES]) unless File.exist?(@constants[:TEMP_IMAGES])

  def load_from_ejson(ejson_path)
    ejson_path = File.absolute_path(ejson_path) unless Pathname.new(ejson_path).absolute?
    raise "config file: #{ejson_path} not found" unless File.exist?(ejson_path)

    encrypted_json = JSON.parse(File.read(ejson_path))
    public_key = encrypted_json['_public_key']
    raise "Private key is not listed in #{private_key_path}." unless File.exist?("/opt/ejson/keys/#{public_key}")

    output, status = Open3.capture2e("ejson", "decrypt", ejson_path.to_s)
    raise "ejson: #{output}" unless status.success?

    secrets = JSON.parse(output)
    secrets = hash_symblize_keys(secrets)

    @secrets.merge!(secrets)
  end

  def load_from_env(keys)
    secrets = {}
    keys.each do |key|
      key = key.to_s
      next if key.start_with?("_")
      value = ENV[key.upcase]
      secrets[key] = value unless value.nil?
    end

    secrets = hash_symblize_keys(secrets)
    @secrets.merge!(secrets)
  end

  def check_required(required = [])
    required.each { |key| raise "required secrets not set: #{key}" if @secrets[key].nil? }
  end

  def hash_symblize_keys(hash)
    hash.keys.each do |key|
      hash[(begin
        key.to_sym
      rescue
        key
      end) || key] = hash.delete(key)
    end
    hash
  end

  ejson_path = ENV["EJSON_PATH"] || File.join(File.dirname(__FILE__), "secrets.benjamin.ejson")
  load_from_ejson(ejson_path)
  required = %i(diatex_password default_github_repo default_cdn_url github_private_pem)
  load_from_env(required)
  check_required(required)
end
