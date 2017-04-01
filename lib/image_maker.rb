require 'lib/github_client'
class ImageMaker
  def initialize(github_repo: Application.secrets[:default_github_repo], cdn_url: Application.secrets[:default_cdn_url], branch: 'master')
    @github_repo = github_repo
    @cdn_url = cdn_url
    @branch = branch

    username = @github_repo.split('/').first
    return if username.nil?
    Application.logger.info "Creating client for #{username}"

    @github = GithubClient.new(username: username)
  end

  def create_image(title, remote_path, image_path)
    image_path = image_path.path if image_path.respond_to?('path')

    Application.logger.info("Creating image '#{title}'...")
    Application.logger.info @github_repo

    @github.client.create_contents(
      @github_repo,
      remote_image_path(remote_path),
      "Adding Image #{remote_path}",
      branch: @branch,
      file: image_path
    )

    { title: title, url: url(remote_path) }
  end

  def remote_image_path(remote_path)
    "images/diatex/#{remote_path}"
  end

  def url(remote_path)
    remote_image = remote_image_path(remote_path)
		if @cdn_url
			"http://#{@cdn_url}/#{remote_image}"
  	else
			remote_image
		end
	end

  def exists?(remote_path)
    url = url(remote_path)
    puts url
    res = Net::HTTP.get_response(URI(url))
    res.code == '200'
  end

  def image_cache(param, remote_path)
    # Check for Cache
    if @cdn_url && exists?(remote_path)
      Application.logger.info 'Already made, sending cache'
      return { input: param, url: url(remote_path) }.to_json
    end

    if @github.exists?(@github_repo, remote_image_path(remote_path))
      Application.logger.info 'Already made, sending cache'
      return { input: param, url: url(remote_path) }.to_json
    end

    false
  end
end
