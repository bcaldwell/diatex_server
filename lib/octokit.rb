require 'logger'
github_key = ENV["GITHUB_KEY"]

log = Logger.new(STDOUT)

if github_key.nil? || github_key.empty?
  log.warn "ERROR: Github Key was not provided"
end

GithubClient = Octokit::Client.new(access_token: github_key)