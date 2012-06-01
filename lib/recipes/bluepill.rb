Capistrano::Configuration.instance.load do  
  set(:bluepill_local_init) { File.join(templates_path, "bluepill_init.conf.erb") } 
  set(:bluepill_remote_init) { File.join("/etc", "init", "bluepill_#{application}_#{rails_env}.conf") } 
  set(:bluepill_local_config) { File.join(templates_path, "bluepill.pill.erb") } 
  set(:bluepill_remote_config) { File.join(shared_path, "config", "master.pill") }
  set(:bluepill_puma_pid) { File.join(pids_path,"#{app_server}.pid") } unless exists?(:bluepill_puma_pid)
  set(:bluepill_working_dir) {"#{current_path}"} unless exists?(:bluepill_working_dir)
  set(:bluepill_app) {"#{application}_#{rails_env}"} unless exists?(:bluepill_app)
  namespace :bluepill do
    desc "|capistrano-recipes| Stop processes that bluepill is monitoring and quit bluepill"
    task :quit, :roles => [:app] do
      args = exists?(:options) ? options : ''
      begin
        run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{bluepill_app} stop --no-privileged #{args}"
      rescue
        puts "Bluepill was unable to finish gracefully all the process.. (stop). Most likely not running..."
      ensure
        begin
          run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{bluepill_app} quit --no-privileged"
        rescue
          puts "Bluepill was unable to finish gracefully all the process.. (quit). Most likely not running..."
        end
      end
      sleep 5
    end
    
    desc "|capistrano-recipes| Load the pill from {your-app}/config/master.pill"
    task :init, :roles =>[:app] do
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill load #{bluepill_remote_config} --no-privileged"
    end
 
    desc "|capistrano-recipes| Starts your previous stopped pill"
    task :start, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      #run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{bluepill_app} start --no-privileged #{args}"
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill load #{bluepill_remote_config} --no-privileged"
    end
    
    desc "|capistrano-recipes| Stops some bluepill monitored process"
    task :stop, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{bluepill_app} stop --no-privileged #{args}"
    end
    
    desc "|capistrano-recipes| Restarts the pill from {your-app}/config/master.pill"
    task :restart, :roles =>[:app] do
      bluepill.quit 
      bluepill.start 
    #   args = exists?(:options) ? options : ''
    #   #run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{bluepill_app} restart --no-privileged #{args}"
   end
 
    desc "|capistrano-recipes| Prints bluepills monitored processes statuses"
    task :status, :roles => [:app] do
      args = exists?(:options) ? options : ''
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec bluepill #{bluepill_app} status --no-privileged #{args}"
    end

    desc <<-EOF
    |capistrano-recipes| Parses the configuration file through ERB to fetch our variables and \
    uploads the result to #{bluepill_remote_config}, to be loaded by whoever is booting \
    up the bluepill watcher/monitorer
    EOF
    task :setup_config, :roles => :app , :except => { :no_release => true } do
      generate_config(bluepill_local_config, bluepill_remote_config)
    end

    desc "|capistrano-recipes| Create bluepill init file for ubuntu systems..."
    task :setup_init, :roles => :app , :except => { :no_release => true } do
      generate_config(bluepill_local_init, bluepill_remote_init, true)
    end
  end

  after 'deploy:setup' do
    bluepill.setup_config if Capistrano::CLI.ui.agree("Create master.pill configuration file? [Yn]")
    bluepill.setup_init   if Capistrano::CLI.ui.agree("Create #{bluepill_remote_init} configuration file? [Yn]")
  end if is_using('bluepill', :monitorer)

  # after "deploy:update" do 
  #   bluepill.quit 
  #   bluepill.start 
  # end if is_using('bluepill', :monitorer)
  #end if is_using_bluepill
end