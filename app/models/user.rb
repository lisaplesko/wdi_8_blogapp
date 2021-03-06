class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :posts
  has_many :comments, through: :posts

  def self.from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.first_name = auth.info.first_name
      user.profile_url = (auth.info.image + "?type=large")
      user.email = auth.info.email
      user.name = auth.info.name
    end
  end

  # http://railscasts.com/episodes/235-devise-and-omniauth-revised?view=comments
  def self.new_with_session(params, session)
    if session["devise.user_attributes"]
      new(session["devise.user_attributes"], without_protection: true) do |user|
        user.attributes = params
        user.valid?
      end
    else
      super
    end
  end

  def password_required?
    # If signing in through omni auth, won't need to require a password
    super && provider.blank?
  end

  def update_with_password(params, *options)
    if encrypted_password.blank?
      update_attributes(params, *options)
    else
      super
    end
  end

  # This can later be refactored into method above
  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.info
    user = User.where(:provider => access_token.provider, :uid => access_token.uid ).first
    if user
      return user
    else
      registered_user = User.where(:email => access_token.info.email).first
      if registered_user
        return registered_user
      else
        user = User.create(name: data["name"],
          first_name: data["first_name"],
          provider:access_token.provider,
          email: data["email"],
          profile_url: data["image"].gsub!("sz=50", "sz=200"),
          uid: access_token.uid ,
          password: Devise.friendly_token[0,20],
        )
      end
   end
 end
end
