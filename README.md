# Rails Templates

Quickly generate a rails app with the default [Wagon](http://www.lewagon.org) configuration
using [Rails Templates](http://guides.rubyonrails.org/rails_application_templates.html).


## Minimal

Get a minimal rails app ready to be deployed on Heroku with Bootstrap, Simple form and
debugging gems.
My fork adds SLIM instead of ERB and the following gems:
* quiet-assets
* rpsec
* faker
* factory-girl-rails
* capybara
* database_cleaner

I also included a [javacript plugin](https://github.com/Verba/jquery-readyselector) that makes running javacript code on a specific page very easy.
It keeps all the javacript code in the assets folder and helps keeping views clean.

```bash
rails new \
  -T --database postgresql \
  -m https://raw.githubusercontent.com/lewagon/rails-templates/master/minimal.rb \
  CHANGE_THIS_TO_YOUR_RAILS_APP_NAME
```

## Devise

Same as minimal **plus** a Devise install with a generated `User` model.


```bash
rails new \
  -T --database postgresql \
  -m https://raw.githubusercontent.com/lewagon/rails-templates/master/devise.rb \
  CHANGE_THIS_TO_YOUR_RAILS_APP_NAME
```
