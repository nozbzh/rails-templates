run 'pgrep spring | xargs kill -9'

# GEMFILE
########################################
run 'rm Gemfile'
file 'Gemfile', <<-RUBY
source 'https://rubygems.org'
ruby '#{RUBY_VERSION}'

gem 'devise'
gem 'figaro'
gem 'jbuilder', '~> 2.0'
gem 'pg'
gem 'puma'
gem 'rails', '#{Rails.version}'
gem 'redis'

gem 'autoprefixer-rails'
gem 'bootstrap-sass'
gem 'font-awesome-sass'
gem 'jquery-rails'
gem 'sass-rails'
gem 'simple_form'
gem 'slim'
gem 'uglifier'

group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'listen', '~> 3.0.5'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'rspec-rails', '>= 3.5.2'
  gem 'faker'
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'database_cleaner'
end
RUBY

# Ruby version
########################################
file '.ruby-version', RUBY_VERSION

# Procfile
########################################
file 'Procfile', <<-YAML
web: bundle exec puma -C config/puma.rb
YAML

# Spring conf file
########################################
inject_into_file 'config/spring.rb', before: ').each { |path| Spring.watch(path) }' do
  '  config/application.yml\n'
end

# Assets
########################################
run 'rm -rf app/assets/stylesheets'
run 'rm -rf vendor'
run 'curl -L https://github.com/lewagon/stylesheets/archive/master.zip > stylesheets.zip'
run 'unzip stylesheets.zip -d app/assets && rm stylesheets.zip && mv app/assets/rails-stylesheets-master app/assets/stylesheets'

run 'rm app/assets/javascripts/application.js'
file 'app/assets/javascripts/application.js', <<-JS
//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require_tree .
JS

run 'rm app/assets/stylesheets/components/_alert.scss'
file 'app/assets/stylesheets/components/_alert.scss', <<-TXT
/* -------------------------------------
 * Your CSS code for flash notices and alerts
* ------------------------------------- */

.alert {
  margin: 0;
  text-align: center;
  color: white !important;
}
.alert-notice {
  background: $blue;
}
.alert-alert {
  background: $orange;
}
.alert-error {
  background: $red;
}
.alert-success {
  background: $green;
}
TXT

# Dev environment
########################################
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# Layout
########################################
run 'rm app/views/layouts/application.html.erb'
file 'app/views/layouts/application.html.slim', <<-TXT
doctype html
html
  head
    title TODO
    meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"
    meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"
    meta charset="UTF-8"
    = csrf_meta_tags
    = action_cable_meta_tag
    = stylesheet_link_tag 'application', media: 'all'

  body class="\#{controller_name} \#{action_name}"
    = render 'shared/navbar'
    = render 'shared/flashes'
    .col-md-8.col-md-offset-2
      = yield
      = render 'shared/footer'
      = javascript_include_tag 'application'
TXT

file 'app/views/shared/_footer.slim', <<-TXT
.col-md-8.col-md-offset-2
  p.text-center I am the footer. Feed me!
TXT

file 'app/views/shared/_flashes.slim', <<-TXT
- if (message = flash[:notice]).present?
  .container-fluid.alert.alert-notice style='padding: 20px;'
    button.close aria-label="Close" data-dismiss="alert" type="button"
      span aria-hidden="true" ×
    center: span= message.html_safe

- if (message = flash[:error]).present?
  .container-fluid.alert.alert-error style='padding: 20px;'
    button.close aria-label="Close" data-dismiss="alert" type="button"
      span aria-hidden="true" ×
    center: span= message.html_safe

- if (message = flash[:alert]).present?
  .container-fluid.alert.alert-alert style='padding: 20px;'
    button.close aria-label="Close" data-dismiss="alert" type="button"
      span aria-hidden="true" ×
    center: span= message.html_safe

- if (message = flash[:success]).present?
  .container-fluid.alert.alert-success style='padding: 20px;'
    button.close aria-label="Close" data-dismiss="alert" type="button"
      span aria-hidden="true" ×
    center: span= message.html_safe

- [:notice, :error, :alert, :success].each do |name|
  - flash[name] = nil
TXT

run "curl -L https://raw.githubusercontent.com/nozbzh/awesome-navbars/master/templates/_navbar_wagon.html.slim > app/views/shared/_navbar.html.slim"

# README
########################################
markdown_file_content = <<-MARKDOWN
Seriously, write a readme.
MARKDOWN
file 'README.md', markdown_file_content, force: true

# Generators
########################################
generators = <<-RUBY
config.generators do |generate|
      generate.assets false
      generate.helper false
    end
RUBY

environment generators

########################################
# AFTER BUNDLE
########################################
after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rake 'db:drop db:create db:migrate'
  generate('simple_form:install', '--bootstrap')
  generate(:controller, 'pages', 'home', '--skip-routes')

  # Routes
  ########################################
  route "root to: 'pages#home'"

  # Git ignore
  ########################################
  run 'rm .gitignore'
  file '.gitignore', <<-TXT
.bundle
log/*.log
tmp/**/*
tmp/*
*.swp
.DS_Store
public/assets
TXT

  # Devise install + user
  ########################################
  generate('devise:install')
  generate('devise', 'User')

  # App controller
  ########################################
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<-RUBY
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
end
RUBY

  # migrate + devise views
  ########################################
  rake 'db:migrate'
  generate('devise:views')

  # Pages Controller
  ########################################
  run 'rm app/controllers/pages_controller.rb'
  file 'app/controllers/pages_controller.rb', <<-RUBY
class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
  end
end
RUBY

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # Figaro
  ########################################
  run 'bundle binstubs figaro'
  run 'figaro install'

  # Rspec
  ########################################
  run "bin/rails generate rspec:install"

  # Slim
  ########################################
  run "gem install html2slim"
  run "for file in app/views/devise/**/*.erb; do erb2slim $file ${file%erb}slim && rm $file; done"

  # Git
  ########################################
  git :init
  git add: '.'
  git commit: "-m 'Initial commit'"
end










# run "pgrep spring | xargs kill -9"
# run "rm Gemfile"
# file 'Gemfile', <<-RUBY
# source 'https://rubygems.org'
# ruby '#{RUBY_VERSION}'

# gem 'rails', '#{Rails.version}'
# gem 'puma'
# gem 'pg'
# gem 'figaro'
# gem 'jbuilder', '~> 2.0'
# gem 'devise'#{Rails.version >= "5" ? ", github: 'plataformatec/devise'" : nil}
# gem 'redis'

# gem 'slim'
# gem 'sass-rails'
# gem 'jquery-rails'
# gem 'uglifier'
# gem 'bootstrap-sass'
# gem 'font-awesome-sass'
# gem 'simple_form'
# gem 'autoprefixer-rails'

# group :development, :test do
#   gem 'binding_of_caller'
#   gem 'better_errors'
#   #{Rails.version >= "5" ? nil : "gem 'quiet_assets'"}
#   gem 'pry-byebug'
#   gem 'pry-rails'
#   gem 'spring'
#   #{Rails.version >= "5" ? "gem 'listen', '~> 3.0.5'" : nil}
#   #{Rails.version >= "5" ? "gem 'spring-watcher-listen', '~> 2.0.0'" : nil}

#   %w[rspec-core rspec-expectations rspec-mocks rspec-rails rspec-support].each do |lib|
#     gem lib, :git => "https://github.com/rspec/\#{lib}.git", :branch => 'master'
#   end
#   gem 'rails-controller-testing'
#   gem 'faker'
#   gem 'factory_girl_rails'
#   gem 'capybara'
#   gem 'database_cleaner'
# end

# #{Rails.version < "5" ? "gem 'rails_12factor', group: :production" : nil}
# RUBY

# file ".ruby-version", RUBY_VERSION

# file 'Procfile', <<-YAML
# web: bundle exec puma -C config/puma.rb
# YAML

# if Rails.version < "5"
# puma_file_content = <<-RUBY
# threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i

# threads     threads_count, threads_count
# port        ENV.fetch("PORT") { 3000 }
# environment ENV.fetch("RAILS_ENV") { "development" }
# RUBY

# file 'config/puma.rb', puma_file_content, force: true
# end

# run "rm -rf app/assets/stylesheets"
# run "curl -L https://github.com/lewagon/stylesheets/archive/master.zip > stylesheets.zip"
# run "unzip stylesheets.zip -d app/assets && rm stylesheets.zip && mv app/assets/rails-stylesheets-master app/assets/stylesheets"

# run 'rm app/assets/javascripts/application.js'
# file 'app/assets/javascripts/application.js', <<-JS
# //= require jquery
# //= require jquery_ujs
# //= require bootstrap-sprockets
# //= require jquery-readyselector
# //= require_tree .
# JS

# file 'vendor/assets/javascripts/jquery-readyselector.js', <<-JS
# (function ($) {
#   var ready = $.fn.ready;
#   $.fn.ready = function (fn) {
#     if (this.context === undefined) {
#       // The $().ready(fn) case.
#       ready(fn);
#     } else if (this.selector) {
#       ready($.proxy(function(){
#         $(this.selector, this.context).each(fn);
#       }, this));
#     } else {
#       ready($.proxy(function(){
#         $(this).each(fn);
#       }, this));
#     }
#   }
# })(jQuery);
# JS

# gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# run 'rm app/assets/stylesheets/components/_alert.scss'
# file 'app/assets/stylesheets/components/_alert.scss', <<-TXT
# /* -------------------------------------
#  * Your CSS code for flash notices and alerts
# * ------------------------------------- */

# .alert {
#   margin: 0;
#   text-align: center;
#   color: white !important;
# }
# .alert-notice {
#   background: $blue;
# }
# .alert-alert {
#   background: $orange;
# }
# .alert-error {
#   background: $red;
# }
# .alert-success {
#   background: $green;
# }
# TXT

# run 'rm app/views/layouts/application.html.erb'
# file 'app/views/layouts/application.html.slim', <<-TXT
# doctype html
# html
#   head
#     title MyTitle
#     = csrf_meta_tags
#     = action_cable_meta_tag
#     meta name="viewport" content="width=device-width, initial-scale=1"
#     meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"
#     = stylesheet_link_tag    'application', media: 'all'

#   body class="\#{controller_name} \#{action_name}"
#     = render 'shared/navbar'
#     = render 'shared/notifications'
#     .col-md-8.col-md-offset-2
#       = yield
#       = render 'shared/footer'
#       = javascript_include_tag 'application'
# TXT

# file 'app/views/shared/_footer.slim', <<-TXT
# .col-md-8.col-md-offset-2
#   p.text-center I am the footer. Feed me!
# TXT

# file 'app/views/shared/_notifications.slim', <<-TXT
# - if (message = flash[:notice]).present?
#   .container-fluid.alert.alert-notice style='padding: 20px;'
#     button.close aria-label="Close" data-dismiss="alert" type="button"
#       span aria-hidden="true" ×
#     center: span= message.html_safe

# - if (message = flash[:error]).present?
#   .container-fluid.alert.alert-error style='padding: 20px;'
#     button.close aria-label="Close" data-dismiss="alert" type="button"
#       span aria-hidden="true" ×
#     center: span= message.html_safe

# - if (message = flash[:alert]).present?
#   .container-fluid.alert.alert-alert style='padding: 20px;'
#     button.close aria-label="Close" data-dismiss="alert" type="button"
#       span aria-hidden="true" ×
#     center: span= message.html_safe

# - if (message = flash[:success]).present?
#   .container-fluid.alert.alert-success style='padding: 20px;'
#     button.close aria-label="Close" data-dismiss="alert" type="button"
#       span aria-hidden="true" ×
#     center: span= message.html_safe

# - [:notice, :error, :alert, :success].each do |name|
#   - flash[name] = nil
# TXT

# run "curl -L https://raw.githubusercontent.com/nozbzh/awesome-navbars/master/templates/_navbar_wagon.html.slim > app/views/shared/_navbar.html.slim"

# after_bundle do
#   rake 'db:drop db:create db:migrate'
#   generate(:controller, 'pages', 'home', '--no-helper', '--no-assets', '--skip-routes')
#   route "root to: 'pages#home'"
#   run 'rm app/views/pages/home.html.erb'
#   file 'app/views/pages/home.html.slim', <<-TXT
#   h1 Pages#home
#   p Find me in app/views/pages/home.html.slim
#   TXT
#   run "rm .gitignore"
#   file '.gitignore', <<-TXT
# .bundle
# log/*.log
# tmp/**/*
# tmp/*
# *.swp
# .DS_Store
# public/assets
# TXT
#   run "bundle exec figaro install"
#   generate('simple_form:install', '--bootstrap')
#   generate('devise:install')
#   generate('devise', 'User')
#   rake 'db:migrate'
#   generate('devise:views')
#   run "gem install html2slim"
#   run "for file in app/views/devise/**/*.erb; do erb2slim $file ${file%erb}slim && rm $file; done"
#   environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
#   environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'
#   run "bin/rails generate rspec:install"
#   git :init
#   git add: "."
#   git commit: %Q{ -m 'Initial commit' }
# end
