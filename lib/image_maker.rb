class ImageMaker
  def create_image(title, remote_path, image_path, git_cdn_repo = Application.secrets[:default_git_cdn_repo])
    image_path = image_path.path if image_path.respond_to?('path')

    Application.logger.info("Creating image '#{title}'...")
    Application.logger.info git_cdn_repo
    Application::GithubClient.create_contents(
      git_cdn_repo,
      remote_image_path(remote_path),
      "Adding Image #{remote_path}",
      branch: "master",
      # branch: "gh-pages",
      file: image_path
    )
    { title: title, url: url(remote_path) }
  end

  def remote_image_path(remote_path)
    "images/diatex/#{remote_path}"
  end

  def url(remote_path)
    "http://gitcdn.bcaldwell.ca/#{remote_image_path(remote_path)}"
  end

  def exists?(remote_path, git_cdn_repo = Application.secrets[:default_git_cdn_repo])
    url = url(remote_path)
    puts url
    res = Net::HTTP.get_response(URI(url))
    res.code == '200'
  end
end