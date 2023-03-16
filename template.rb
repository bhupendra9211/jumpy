require "fileutils"
require "shellwords"



# Copied from: https://github.com/mattbrictson/rails-template
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("jumpy-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      "--quiet",
      "https://github.com/aadeshere1/jumpy.git",
      tempdir
    ].map(&:shellescape).join(" ")

    if (branch = __FILE__[%r{jumpy/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def rails_version
  @rails_version ||= Gem::Version.new(Rails::VERSION::STRING)
end

def rails_7_or_newer?
  Gem::Requirement.new(">= 7.0.4").satisfied_by? rails_version
end

def add_gems
    add_gem 'devise', '~> 4.9'
    add_gem 'delayed_job_active_record', '~> 4.1', '>= 4.1.7'
    add_gem 'friendly_id', '~> 5.5'
    add_gem 'name_of_person', '~> 1.1'
    add_gem 'noticed', '~> 1.4'
    add_gem 'sitemap_generator', '~> 6.3'
    add_gem 'simple_form', '~> 5.1'
    add_gem 'rollbar', '~> 3.3'
    
    add_gem 'whenever', require: false
end

def set_application_name
  environment "config.application_name = Rails.application.class.module_parent_name"

  puts "You can change application name in file ./config/application.rb"
end

def add_users
  route "root to: 'home#index'"
  generate "devise:install"

  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }", env: 'development'
  generate :devise, "User", "first_name", "last_name", "announcements_last_read_at:datetime", "admin:boolean"

  # Set admin default to false
  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end

  if Gem::Requirement.new("> 5.2").satisfied_by? rails_version
    gsub_file "config/initializers/devise.rb", /  # config.secret_key = .+/, "  config.secret_key = Rails.application.credentials.secret_key_base"
  end

  # inject_into_file("app/models/user.rb", "omniauthable, :", after: "devise :")
end

def copy_templates
  remove_file "app/assets/stylesheets/application.css"


  directory "app", force: true

  copy_file "app/models/concerns/uid.rb"
  

  route "get '/terms', to: 'home#terms'"
  route "get '/privacy', to: 'home#privacy'"
end

def add_delayed_job
  generate "delayed_job:active_record"
  environment "config.active_job.queue_adapter = :delayed_job"  
end

def add_notifications
  route "resources :notifications, only: [:index]"
end

def add_whenever
  run "wheneverize ."
end

def add_friendly_id
  generate "friendly_id"
  insert_into_file(Dir["db/migrate/**/*friendly_id_slugs.rb"].first, "[5.2]", after: "ActiveRecord::Migration")
end

def add_gem(name, *options)
  gem(name, *options) unless gem_exists?(name)
end

def gem_exists?(name)
  IO.read("Gemfile") =~ /^\s*gem ['"]#{name}['"]/
end


# 

unless rails_7_or_newer?
  puts "Please update Rails to 7.0.4 or newer to create a application through jumpy"
end

add_gems

after_bundle do
  set_application_name
  add_users
  
  add_delayed_job
  add_notifications
  add_whenever
  add_friendly_id

  rails_command "active_storage:install"
  run "bundle lock --add-platform x86_64-linux"

  copy_templates

  unless ENV["SKIP_GIT"]
    git :init
    git add: "."
    begin
      git commit: %( -m 'Initial commit')
    rescue StandardError => e
      puts e.message
    end
  end
  
  say
  say "jumpy app successfully created!", :blue
  say
  say "To get started with your new app:", :green
  say "  cd #{original_app_name}"
  say
  say "  # Update config/database.yml with your database credentials"
  say
  say "  rails db:create"
  say "  rails g noticed:model"
  say "  rails db:migrate"
  say "  rails g madmin:install # Generate admin dashboards"
  say "  gem install foreman"
  say "  bin/dev"
  
end