class GithubClient
  attr_reader :client

  @@cache = {}

  def initialize(installation: nil, username: nil)
    return @client = @@cache[username] if username && @@cache[username]
    installations = Application::JWT_Client.find_integration_installations
    if installation.nil? && !username.nil?
      user_install = installations.find do |install|
        install[:account][:login] == username
      end
      Application.logger.warn "Couldn't find installation for user #{username}" if user_install.nil?
      installation = user_install[:id]
    elsif !installation.nil?
      exists = installations.any? { |install| install[:id] == installation }
      Application.logger.warn "Couldn't find installation for access_tokens #{installation}" unless exists
    end

    token = Application::JWT_Client.create_integration_installation_access_token(installation)
    @client = Octokit::Client.new(access_token: token[:token])
    @@cache[username] = @client
  end

  def exists?(repo, path)
    !contents(repo, path).nil?
  end

  def contents(repo, path)
    @client.contents(repo, path: path)
  rescue Octokit::NotFound
    nil
  end
end
