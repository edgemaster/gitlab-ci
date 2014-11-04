class UserSession
  include ActiveModel::Conversion
  include StaticModel
  extend ActiveModel::Naming

  attr_accessor :url

  def authenticate(auth_opts)
    authenticate_via(auth_opts) do |url, network, options|
      network.authenticate(url, options)
    end
  end

  def authenticate_by_token(auth_opts)
    result = authenticate_via(auth_opts) do |url, network, options|
      network.authenticate_by_token(url, options)
    end

    result
  end

  private

  def authenticate_via(options, &block)
    url = options.delete(:url)

    return nil unless GitlabCi.config.gitlab_server.url.include?(url)

    user = block.call(url, Network.new, options)

    if user and user_permitted(url, user)
      return User.new(user.merge({"url" => url}))
    else
      nil
    end
  rescue
    nil
  end

  def user_permitted(url, user)
    groups = Network.new.groups(url, {'private_token' => user['private_token']})
    groups.map! {|g| g['id'] }
    return !(groups & Settings.users.allow_login_only_from_groups).empty?
  end
end
