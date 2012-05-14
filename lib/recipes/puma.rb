Capistrano::Configuration.instance.load do
  set :puma_min_threads, 0 unless exists?(:puma_min_threads)
  set :puma_max_threads, 16 unless exists?(:puma_max_threads)

  # The wrapped bin to start puma (bundle exec power...)
  set :puma_bin, 'bundle exec puma' unless exists?(:puma_bin)
  set :puma_socket, File.join("/var/run/", "rails", "#{application}", "#{rails_env}.sock") unless exists?(:puma_socket)

  # Defines where the pid will live.
  set(:puma_pid) { File.join(pids_path,"#{app_server}","#{application}", "#{rails_env}.pid") } unless exists?(:puma_pid)
  set(:puma_state) { File.join(shared_path, "puma.state") } unless exists?(:puma_state)

  set :puma_activate_control_app, false unless exists?(:puma_activate_control_app)

  set :puma_on_restart_active, true unless exists?(:puma_on_restart_active)
  # Our puma template to be parsed by erb
  # You may need to generate this file the first time with the generator
  # included in the gem
  set(:puma_local_config) { File.join(templates_path, "puma.rb.erb") } 

  # The remote location of puma's config file. Used by bluepill to fire it up
  set(:puma_remote_config) { File.join(shared_path, "config", "puma.rb") }

  def puma_get_status
    #"echo TODO fix curl to get status of puma server?"
  end
  
  def puma_stop_cmd
    #TODO
    #"kill -QUIT `cat #{puma_pid}`"
  end
  
  def puma_restart_cmd
    #TODO
    #"kill -USR2 `cat #{puma_pid}`"
  end

  # Puma 
  #------------------------------------------------------------------------------
  namespace :puma do    
    desc "|capistrano-recipes| Starts puma directly"
    task :start, :roles => :app do
      run puma_start_cmd
    end  
    
    desc "|capistrano-recipes| Stops puma directly"
    task :stop, :roles => :app do
      run puma_stop_cmd
    end  
    
    desc "|capistrano-recipes| Restarts puma directly"
    task :restart, :roles => :app do
      run puma_restart_cmd
    end
    
    # ???????????????
    # desc "|capistrano-recipes| Tail puma log file" 
    # task :tail, :roles => :app do
    #   run "tail -f #{shared_path}/log/puma.log" do |channel, stream, data|
    #     puts "#{channel[:host]}: #{data}"
    #     break if stream == :err
    #   end
    # end

    desc <<-EOF
    |capistrano-recipes| Parses the configuration file through ERB to fetch our variables and \
    uploads the result to #{puma_remote_config}, to be loaded by whoever is booting \
    up the puma.
    EOF
    task :setup, :roles => :app , :except => { :no_release => true } do
      # TODO: refactor this to a more generic setup task once we have more socket tasks.
      # commands = []
      # commands << "mkdir -p #{sockets_path}"
      # commands << "chown #{user}:#{group} #{sockets_path} -R" 
      # commands << "chmod +rw #{sockets_path}"
      
      # run commands.join(" && ")
      generate_config(puma_local_config, puma_remote_config)
    end
  end
  
  after 'deploy:setup' do
    puma.setup if Capistrano::CLI.ui.agree("Create puma configuration file? [Yn]")
  end if is_using('puma',:app_server)
end
