source 'https://rubygems.org'

ruby "2.1.4"


gem 'rails', '4.2.5.2'
gem 'pg', '~> 0.18.4'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'

gem 'jquery-ui-rails'
gem 'jtable-rails4', '~> 0.1.1'
# gem "jtable-rails4", :path => "/home/david/webdev/jtable-rails4"

gem 'turbolinks'
gem 'sdoc', '~> 0.4.0', group: :doc

# DBR: https://www.railstutorial.org/book/filling_in_the_layout
gem 'bootstrap-sass'
#gem 'bootstrap-will_paginate'
gem 'kaminari'
gem 'api-pagination'

gem 'paperclip'
gem 'delayed_paperclip'

gem 'aws-sdk-v1' # Needed as per (otherwise errors): http://ruby.awsblog.com/post/TxFKSK2QJE6RPZ/Upcoming-Stable-Release-of-AWS-SDK-for-Ruby-Version-2
gem 'aws-sdk'
gem 'delayed_job_active_record'
gem 'daemons' # for start/stop/restart delayed_job
gem 'sextant', :group => :development # to show routes in browser localhost:3000/rails/routes

gem 'devise'

# DBR: cors needed as have API and separate app. Getting errors
# when doing ajax requests across different domains.
gem 'rack-cors', :require => 'rack/cors'
gem 'yajl-ruby' # ?not sure needed anymore? faster JSON backends. See https://github.com/rails/jbuilder#faster-json-backends

gem 'therubyracer'

group :development, :test do
  gem 'faker'
  gem 'pry-rails'
  gem 'pry-nav'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'minitest-reporters'
  gem 'mini_backtrace'
  gem 'guard' # without this you get an error when running tests. See https://github.com/guard/guard-minitest#install
  gem 'guard-minitest'

  #gem "factory_girl_rails"
end

group :test do

end

group :production do
  #gem 'pg',             '0.17.1'
  gem 'rails_12factor', '0.0.3'
end


# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development
