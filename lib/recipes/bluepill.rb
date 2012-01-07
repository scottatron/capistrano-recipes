Capistrano::Configuration.instance.load do  
  namespace :bluepill do
    desc "|capistrano-recipes| Stop processes that bluepill is monitoring and quit bluepill"
    task :quit, :roles => [:app] do
      args = exists?(:options) ? options : ''
      begin
        run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{application} stop --no-privileged #{args}"
      rescue
        puts "Bluepill was unable to finish gracefully all the process"
      ensure
        run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{application} quit --no-privileged"
      end
    end
    
    desc "|capistrano-recipes| Load the pill from {your-app}/config/master.pill"
    task :init, :roles =>[:app] do
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill load #{current_path}/config/master.pill --no-privileged"
    end
 
    desc "|capistrano-recipes| Starts your previous stopped pill"
    task :start, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{application} start --no-privileged #{args}"
    end
    
    desc "|capistrano-recipes| Stops some bluepill monitored process"
    task :stop, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{application} stop --no-privileged #{args}"
    end
    
    desc "|capistrano-recipes| Restarts the pill from {your-app}/config/master.pill"
    task :restart, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{application} restart --no-privileged #{args}"
    end
 
    desc "|capistrano-recipes| Prints bluepills monitored processes statuses"
    task :status, :roles => [:app] do
      args = exists?(:options) ? options : ''
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{application} status --no-privileged #{args}"
    end
  end
end