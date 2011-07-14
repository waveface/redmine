default_run_options[:pty] = true

set :application, "redmine"
set :repository,  "git@github.com:waveface/redmine.git"
set :deploy_to, "/var/www/vhosts/redmine"
set :scm, :git
set :branch, "master"
set :user, "deploy"

role :web, "redmine.waveface.com"
role :app, "redmine.waveface.com"
role :db,  "redmine.waveface.com", :primary => true

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

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
end
