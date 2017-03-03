require 'logger'
require './lib/octokit'

require 'byebug'
class ImageMaker
  @@log = Logger.new(STDOUT)

  @@default_git_cdn_repo = ENV['DEFAULT_GIT_CDN_REPO']

  if @@default_git_cdn_repo.nil? || @@default_git_cdn_repo.empty?
    @@log.warn "ERROR: Default github cdn was not provided"
  end
  
  def create_image(title, remote_path, image_path, git_cdn_repo = nil)
    git_cdn_repo = @@default_git_cdn_repo if git_cdn_repo.nil?
    image_path = image_path.path if image_path.respond_to?('path')

    @@log.info("Creating image '#{title}'...")
    @@log.info git_cdn_repo
    GithubClient.create_contents(
      git_cdn_repo,
      remote_image_path(remote_path),
      "Adding Image #{remote_path}",
      branch: "master",
      # branch: "gh-pages",
      file: image_path
    )
    { title: title, url: url(git_cdn_repo, remote_path) }
  end

  def remote_image_path(remote_path)
    "images/diatex/#{remote_path}"
  end

  def url(git_cdn_repo, remote_path)
    "https://gitcdn.bcaldwell.ca/#{remote_image_path(remote_path)}"
  end

  def exists?(remote_path)
    git_cdn_repo = @@default_git_cdn_repo if git_cdn_repo.nil?
    url = url(git_cdn_repo, remote_path)
    puts url
    res = Net::HTTP.get_response(URI(url))
    res.code == '200'
  end
end