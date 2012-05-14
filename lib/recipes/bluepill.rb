Capistrano::Configuration.instance.load do  
  set(:bluepill_local_config) { File.join(templates_path, "bluepill.pill.erb") } 
  set(:bluepill_remote_config) { File.join(shared_path, "pids", "config", "master.pill") }

  namespace :bluepill do
    desc "|capistrano-recipes| Stop processes that bluepill is monitoring and quit bluepill"
    task :quit, :roles => [:app] do
      args = exists?(:options) ? options : ''
      begin
        run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{application}_#{rails_env} stop --no-privileged #{args}"
      rescue
        puts "Bluepill was unable to finish gracefully all the process"
      ensure
        run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{application}_#{rails_env} quit --no-privileged"
      end
    end
    
    desc "|capistrano-recipes| Load the pill from {your-app}/config/master.pill"
    task :init, :roles =>[:app] do
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill load #{current_path}/config/master.pill --no-privileged"
    end
 
    desc "|capistrano-recipes| Starts your previous stopped pill"
    task :start, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{application}_#{rails_env} start --no-privileged #{args}"
    end
    
    desc "|capistrano-recipes| Stops some bluepill monitored process"
    task :stop, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{application}_#{rails_env} stop --no-privileged #{args}"
    end
    
    desc "|capistrano-recipes| Restarts the pill from {your-app}/config/master.pill"
    task :restart, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{application}_#{rails_env} restart --no-privileged #{args}"
    end
 
    desc "|capistrano-recipes| Prints bluepills monitored processes statuses"
    task :status, :roles => [:app] do
      args = exists?(:options) ? options : ''
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{application}_#{rails_env} status --no-privileged #{args}"
    end

    desc <<-EOF
    |capistrano-recipes| Parses the configuration file through ERB to fetch our variables and \
    uploads the result to #{bluepill_remote_config}, to be loaded by whoever is booting \
    up the bluepill watcher/monitorer
    EOF
    task :setup, :roles => :app , :except => { :no_release => true } do
      generate_config(bluepill_local_config, bluepill_remote_config)
    end
  end

  after 'deploy:setup' do
    bluepill.setup if Capistrano::CLI.ui.agree("Create master.pill configuration file? [Yn]")
  end if is_using('bluepill', :monitorer)
  #end if is_using_bluepill
end