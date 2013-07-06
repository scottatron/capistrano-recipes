Capistrano::Configuration.instance.load do
  # set :shared_children, %w(public/system log pids sockets)

  namespace :deploy do
    desc "|capistrano-recipes| Destroys everything"
    task :seppuku, :roles => :app, :except => { :no_release => true } do
      run "rm -rf #{current_path}; rm -rf #{shared_path}"
    end
    desc "|capistrano-recipes| Uploads your local config.yml to the server"
    task :configure, :roles => :app, :except => { :no_release => true } do
      generate_config('config/config.yml', "#{shared_path}/config/config.yml")
    end

    desc "|capistrano-recipes| Create Session_Store config"
    task :session_store, :roles => :app, :except => { :no_release => true } do
      run_rake("config/initializers/session_store.rb")
    end

    desc <<-DESC
      |capistrano-recipes| Restarts your application. This depends heavily on what server you're running.
      If you are running Phusion Passenger, you can explicitly set the server type:

        set :server, :passenger

      ...which will touch tmp/restart.txt, a file monitored by Passenger.

      If you are running Unicorn, you can set:

        set :server, :unicorn

      ...which will use unicorn signals for restarting its workers.

      Otherwise, this command will call the script/process/reaper \
      script under the current path.

      If you are running with Unicorn, you can set the server type as well:

      set :server, :unicorn

      By default, this will be |capistrano-recipes| d via sudo as the `app' user. If \
      you wish to run it as a different user, set the :runner variable to \
      that user. If you are in an environment where you can't use sudo, set \
      the :use_sudo variable to false:

      set :use_sudo, false
    DESC
    task :restart, :roles => :app, :except => { :no_release => true } do
      if exists?(:app_server)
        case fetch(:app_server).to_s.downcase
          when 'passenger'
            passenger.bounce
          when 'unicorn'
            is_using('bluepill', :monitorer) ? bluepill.restart : unicorn.restart
          when 'puma'
            if is_using('bluepill', :monitorer)
              bluepill.restart
            else
              puts "Cannot restart puma without bluepill... doink"
            end
        end
      else
        puts "Dunno how to restart your internets! kthx!"
      end
    end
  end
end

