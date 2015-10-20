class UserSession
  include ActiveModel::Conversion
  include StaticModel
  extend ActiveModel::Naming

  def authenticate(auth_opts)
    network = Network.new
    user = network.authenticate(auth_opts)

    if user and user_permitted(user)
      user["access_token"] = auth_opts[:access_token]
      return User.new(user)
    else
      nil
    end

    user
  rescue
    nil
  end

  def user_permitted(user)
    groups = Network.new.groups({'private_token' => user['private_token']})
    groups.map! {|g| g['id'] }
    return !(groups & Settings.gitlab_ci.users.allow_login_only_from_groups).empty?
  end
end
