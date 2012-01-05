Capistrano::Configuration.instance.load do
  namespace :resque do  
    namespace :worker do
      desc "|capistrano-recipes| List all workers"
      task :list, :roles => :app do
        run "cd #{current_path} && bundle exec resque list"
      end
    
      desc "|capistrano-recipes| Starts the workers"
      task :start, :roles => :app do
        run "cd #{current_path} && bundle exec bluepill start resque --no-privileged"
      end
    
      desc "|capistrano-recipes| Stops the workers"
      task :stop, :roles => :app do
        run "cd #{current_path} && bundle exec bluepill stop resque --no-privileged"
      end
    
      desc "|capistrano-recipes| Restart all workers"
      task :restart, :roles => :app do
        run "cd #{current_path} && bundle exec bluepill restart resque --no-privileged"
      end  
    end
  
    namespace :web do
      desc "|capistrano-recipes| Starts the resque web interface"
      task :start, :roles => :app do
        run "cd #{current_path}; bundle exec resque-web -p 9000 -e #{rails_env} "
      end
    
      desc "|capistrano-recipes| Stops the resque web interface"
      task :stop, :roles => :app do
        run "cd #{current_path}; bundle exec resque-web -K"
      end
    
      desc "|capistrano-recipes| Restarts the resque web interface "
      task :restart, :roles => :app do
        stop
        start
      end
    
      desc "|capistrano-recipes| Shows the status of the resque web interface"
      task :status, :roles => :app do
        run "cd #{current_path}; bundle exec resque-web -S"
      end 
    end
  end
end