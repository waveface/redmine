default_run_options[:pty] = true 

set :scm, :git
set :user, 'deploy'
set :application, "redmine.waveface.com"
set :repository,  "git@github.com:waveface/redmine.git"
set :aws_private_key_path, "~/.ec2/waveface-generic.pem"
set :aws_deploy_user_public_key_path, "~/.ssh/id_rsa.pub"
set :deploy_to, "/var/www/vhosts/redmine"

ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa")]
ssh_options[:port] = 8765

role :web, :application
role :app, :application
role :db, :application, :primary => true


desc "uploads id_rsa.pub to the EC2 instance's deploy users authorized_keys file"
task :bootstrap_deploy_user do

	commands = <<-SH.split("\n").map(&:strip).join(";")
		sudo groupadd admin
		sudo useradd -d /home/#{user} -s /bin/bash -m #{user}
		echo #{user}:#{password} | sudo chpasswd
		sudo usermod -a -G admin deploy
		echo '%admin ALL=(ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers
		sudo mkdir /home/#{user}/.ssh
		sudo chmod  700 /home/#{user}/.ssh
		sudo chown #{user} /home/#{user}/.ssh
		sudo chgrp #{user} /home/#{user}/.ssh
		sudo ls /home/#{user}/.ssh
	SH

	setup_user = <<-SH
		ssh -i #{aws_private_key_path} ec2-user@#{application} "script -c \\"#{commands}\\""
	SH
	
	puts setup_user
  system setup_user

  ssh_options[:keys].each do |key|
	
		puts key
		
    authorized_keys2 = "/home/#{user}/.ssh/authorized_keys2"

    commands = <<-SH.split("\n").map(&:strip).join(";")
      sudo touch #{authorized_keys2}
			sudo cat /tmp/my_key.pub
      sudo cat /tmp/my_key.pub | sudo tee -a #{authorized_keys2}
      sudo rm /tmp/my_key.pub
      sudo chmod   600   #{authorized_keys2}
      sudo chown #{user} #{authorized_keys2}
      sudo chgrp #{user} #{authorized_keys2}
    SH

    setup_keys = <<-SH.strip
      scp -i #{aws_private_key_path} #{aws_deploy_user_public_key_path} ec2-user@#{application}:/tmp/my_key.pub
      ssh -i #{aws_private_key_path} ec2-user@#{application} "script -c \\"#{commands}\\""
    SH

    puts setup_keys
    system setup_keys
  end

end


task :before_update_code, :roles => :app do 
#  run "echo Hello" 
 run "whoami" 
end 


# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

after :deploy, "gems:install"


namespace :gems do
  task :install do
    run "cd #{deploy_to}/current && RAILS_ENV=production rake gems:install"
  end
end

after "gems:install", "deploy:migrate"
