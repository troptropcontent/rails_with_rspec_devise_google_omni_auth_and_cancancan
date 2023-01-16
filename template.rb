# adding usefull gems
gem 'devise'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'
gem 'cancancan'
inject_into_file 'Gemfile', after: 'group :development, :test do' do
  <<-RUBY
    gem 'rspec-rails'
    gem 'factory_bot_rails'
    gem 'byebug', platform: :mri
  RUBY
end

after_bundle do
  rails_command 'db:drop db:create db:migrate'
  git add: '.'
  git commit: %( -m 'Initial commit' )
  # seting up rspec
  run 'rm -rf test'
  generate('rspec:install')
  git add: '.'
  git commit: %( -m 'Set up rspec (automatic commit)' )

  # seting up devise
  generate('devise:install')
  generate('devise', 'User')
  generate('devise:views')
  rails_command 'db:migrate'
  git add: '.'
  git commit: %( -m 'Set up devise (automatic commit)' )

  # seting up omniauth with google
  generate('migration', 'AddOmniauthToUsers', 'provider:string', 'uid:string')
  rails_command 'db:migrate'

  inject_into_file 'config/initializers/devise.rb', after: '# ==> OmniAuth' do
    <<-RUBY

  config.omniauth :google_oauth2, Rails.application.credentials.google_oauth2.client_id, Rails.application.credentials.google_oauth2.client_secret
    RUBY
  end

  inject_into_file 'config/routes.rb', after: 'devise_for :users' do
    <<~RUBY
      , controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
    RUBY
  end

  inject_into_file 'app/models/user.rb', after: ':recoverable, :rememberable, :validatable' do
    <<~RUBY
      ,
      :omniauthable, omniauth_providers: %i[google_oauth2]

    RUBY
  end

  file 'app/controllers/users/omniauth_callbacks_controller.rb', <<~RUBY
    class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
      skip_before_action :verify_authenticity_token, only: :google_oauth2

      def google_oauth2
        @user = User.from_omniauth(request.env["omniauth.auth"])

        sign_in_and_redirect @user
      end

      def failure
        redirect_to root_path
      end
    end
  RUBY

  inject_into_file 'app/models/user.rb', before: /^end/ do
    <<-RUBY
  def self.from_omniauth(auth)
      find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
          user.email = auth.info.email
          user.password = Devise.friendly_token[0, 20]
      end
  end
    RUBY
  end

  gsub_file(
    'app/views/devise/shared/_links.html.erb',
    '<%= link_to "Sign in with #{OmniAuth::Utils.camelize(provider)}", omniauth_authorize_path(resource_name, provider), method: :post %><br />',
    '<%= button_to "Sign in with #{OmniAuth::Utils.camelize(provider)}", omniauth_authorize_path(resource_name, provider), method: :post, data: {turbo: :false} %><br />'
  )

  # sets up cancancan
  generate('cancan:ability')
end
