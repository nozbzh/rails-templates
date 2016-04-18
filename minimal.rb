run "rm Gemfile"
file 'Gemfile', <<-RUBY
source 'https://rubygems.org'
ruby '2.3.0'

gem 'rails', '#{Rails.version}'
gem 'puma'
gem 'pg'
gem 'figaro'
gem 'jbuilder', '~> 2.0'
gem 'devise'#{Rails.version >= "5" ? ", github: 'plataformatec/devise'" : nil}
gem 'redis'

gem 'slim'
gem 'sass-rails'
gem 'jquery-rails'
gem 'uglifier'
gem 'bootstrap-sass'
gem 'font-awesome-sass'
gem 'simple_form'#{Rails.version >= "5" ? ", github: 'plataformatec/simple_form'" : nil}
gem 'autoprefixer-rails'

group :development, :test do
  gem 'binding_of_caller'
  gem 'better_errors'
  #{Rails.version >= "5" ? nil : "gem 'quiet_assets'"}
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'spring'
  #{Rails.version >= "5" ? "gem 'listen', '~> 3.0.5'" : nil}
  #{Rails.version >= "5" ? "gem 'spring-watcher-listen', '~> 2.0.0'" : nil}

  gem 'quiet_assets'

  %w[rspec-core rspec-expectations rspec-mocks rspec-rails rspec-support].each do |lib|
    gem lib, :git => "https://github.com/rspec/\#{lib}.git", :branch => 'master'
  end
  gem 'rails-controller-testing'
  gem 'faker'
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'database_cleaner'
end

group :production do
  gem 'rails_12factor'
end
RUBY

file 'Procfile', <<-YAML
web: bundle exec puma -C config/puma.rb
YAML

puma_file_content = <<-RUBY
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
RUBY

file 'config/puma.rb', puma_file_content, force: true

run "rm -rf app/assets/stylesheets"
run "curl -L https://github.com/lewagon/stylesheets/archive/master.zip > stylesheets.zip"
run "unzip stylesheets.zip -d app/assets && rm stylesheets.zip && mv app/assets/rails-stylesheets-master app/assets/stylesheets"

run 'rm app/assets/javascripts/application.js'
file 'app/assets/javascripts/application.js', <<-JS
//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require jquery-readyselector
//= require_tree .
JS

file 'vendor/assets/javascripts/jquery-readyselector.js', <<-JS
(function ($) {
  var ready = $.fn.ready;
  $.fn.ready = function (fn) {
    if (this.context === undefined) {
      // The $().ready(fn) case.
      ready(fn);
    } else if (this.selector) {
      ready($.proxy(function(){
        $(this.selector, this.context).each(fn);
      }, this));
    } else {
      ready($.proxy(function(){
        $(this).each(fn);
      }, this));
    }
  }
})(jQuery);
JS

if Rails.version >= "5"
  run "rm app/assets/javascripts/cable.coffee"
  file "app/assets/javascripts/cable.js", <<-JS
// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the rails generate channel command.
//
// Turn on the cable connection by removing the comments after the require statements (and ensure it's also on in config/routes.rb).
//
//= require action_cable
//= require_self
//= require_tree ./channels
// this.App || (this.App = {});
// App.cable = ActionCable.createConsumer();
  JS
end

gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

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

run 'rm app/views/layouts/application.html.erb'
file 'app/views/layouts/application.html.slim', <<-TXT
doctype html
html
  head
    title MyTitle
    = csrf_meta_tags
    = action_cable_meta_tag
    meta name="viewport" content="width=device-width, initial-scale=1"
    meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"
    = stylesheet_link_tag    'application', media: 'all'

  body class="\#{controller_name} \#{action_name}"
    = render 'shared/header'
    = render 'shared/notifications'
    .col-md-8.col-md-offset-2
      = yield
      = render 'shared/footer'
      = javascript_include_tag 'application'
TXT

file 'app/views/shared/_footer.slim', <<-TXT
.col-md-8.col-md-offset-2
  p.text-center I am the footer. Feed me!
TXT

file 'app/views/shared/_header.slim', <<-TXT
a href=root_path
  h1.text-center style="margin-bottom: 2em" MySite!
TXT

file 'app/views/shared/_notifications.slim', <<-TXT
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

after_bundle do
  run "spring stop"
  generate(:controller, 'pages', 'home', '--no-helper', '--no-assets', '--skip-routes')
  route "root to: 'pages#home'"
  run 'rm app/views/pages/home.html.erb'
  file 'app/views/pages/home.html.slim', <<-TXT
  h1 Pages#home
  p Find me in app/views/pages/home.html.slim
  TXT
  run "rm .gitignore"
  file '.gitignore', <<-TXT
.bundle
log/*.log
tmp/**/*
tmp/*
*.swp
.DS_Store
public/assets
TXT
  run "bundle exec figaro install"
  generate('simple_form:install', '--bootstrap')
  rake 'db:drop db:create db:migrate'
  run "bin/rails generate rspec:install"
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
