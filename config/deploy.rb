# Capistrano + Passenger + Redmine
# Evadne Wu (ev@waveface.com)

# There are several assumptions about this deployment script.
# 1. You have files in the “shared” directory holding database.yml and other stuff
# 2. You can SSH to the destination as the deploy user, whose known_hosts holds your public key
# 3. You are using the Passenger mod

default_run_options[:pty] = true

set :application, "redmine"
set :repository,  "git@github.com:waveface/redmine.git"
set :deploy_to, "/var/www/vhosts/redmine"
set :scm, :git
set :branch, "waveface"
set :user, "deploy"
set :git_enable_submodules, true

role :web, "redmine.waveface.com"
role :app, "redmine.waveface.com"
role :db,  "redmine.waveface.com", :primary => true

namespace :deploy do
  task :start, :roles => :app do
		puts current_release
	  run "touch #{current_release}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/assets #{release_path}/public/assets"
  end

	desc "Cleans all existing sessions"
	task :clear_cache_and_sessions do
		run "cd #{current_release}; rake tmp:cache:clear RAILS_ENV=production"
		run "cd #{current_release}; rake tmp:sessions:clear RAILS_ENV=production"
	end
	
	desc "Run database migration"
	task :migrate_database do
		run "cd #{current_release}; rake db:migrate RAILS_ENV=production"
	end

	desc "Run plugin migration"
	task :migrate_plugins do
		run "cd #{current_release}; rake db:migrate:upgrade_plugin_migrations RAILS_ENV=production"
		run "cd #{current_release}; rake db:migrate_plugins RAILS_ENV=production"
	end

	desc "Recreate the key used when creating new sessions"
	task :recreate_session_store do
		run "cd #{current_release}; rake config/initializers/session_store.rb RAILS_ENV=production"
	end

end

after 'deploy:update_code', 'deploy:symlink_shared'
after 'deploy:update_code', 'deploy:clear_cache_and_sessions'
after 'deploy:update_code', 'deploy:migrate_database'
after 'deploy:update_code', 'deploy:migrate_plugins'
after 'deploy:update_code', 'deploy:recreate_session_store'
