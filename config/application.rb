require 'tmpdir'
require 'logger'
require 'octokit'

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

  @secrets[:diatex_password] = ENV["DIATEX_PASSWORD"]
  raise "no diatex password set. Set DIATEX_PASSWORD env variable" if @secrets[:diatex_password].nil? || @secrets[:diatex_password].empty?

  @secrets[:default_git_cdn_repo] = ENV['DEFAULT_GIT_CDN_REPO']

  if @secrets[:default_git_cdn_repo].nil? || @secrets[:default_git_cdn_repo].empty?
    @@log.warn "ERROR: Default github cdn was not provided"
  end

  github_key = ENV["GITHUB_KEY"]

  if github_key.nil? || github_key.empty?
    @logger.warn "ERROR: Github Key was not provided"
  end

  Application::GithubClient = Octokit::Client.new(access_token: github_key)
end