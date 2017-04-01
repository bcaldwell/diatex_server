class GithubClient
  attr_reader :client

  @@cache = {}

  def initialize(installation: nil, username: nil)
    return @client = @@cache[username] if username && @@cache[username]
    installations = jwt_client.find_integration_installations
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

    token = jwt_client.create_integration_installation_access_token(installation)
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

  def jwt_client
    Octokit::Client.new(bearer_token: new_jwt_token)
  end

  private
  def new_jwt_token
    # to replace new lines with \n: awk '{printf "%s\\n", $0}' file
    private_pem = Application.secrets[:github_private_pem]
    private_key = OpenSSL::PKey::RSA.new(private_pem)

    payload = {}.tap do |opts|
      opts[:iat] = Time.now.to_i           # Issued at time.
      opts[:exp] = opts[:iat] + 600        # JWT expiration time is 10 minutes from issued time.
      opts[:iss] = 1943 # Integration's GitHub identifier.
    end

    JWT.encode(payload, private_key, 'RS256')
  end
end
