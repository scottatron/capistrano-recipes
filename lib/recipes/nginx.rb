Capistrano::Configuration.instance.load do

  # Where your nginx lives. Usually /opt/nginx or /usr/local/nginx for source compiled.
  set :nginx_sites_enabled_path, "/etc/nginx/sites-enabled" unless exists?(:nginx_sites_enabled_path)

  # Server names. Defaults to application name.
  set :server_names, "#{application}_#{rails_env}" unless exists?(:server_names)

  # Path to the nginx erb template to be parsed before uploading to remote
  set(:nginx_local_config) { "#{templates_path}/nginx.conf.erb" } unless exists?(:nginx_local_config)

  # Path to where your remote config will reside (I use a directory sites inside conf)
  set(:nginx_remote_config) do
    "#{shared_path}/config/nginx/#{application}_#{rails_env}.conf"
  end unless exists?(:nginx_remote_config)

  set :nginx_site_symlink_sites_enabled, File.join(nginx_sites_enabled_path, "#{application}_#{rails_env}") unless exists?(:nginx_site_symlink_sites_enabled)

  # Nginx tasks are not *nix agnostic, they assume you're using Debian/Ubuntu.
  # Override them as needed.
  namespace :nginx do
    desc "|capistrano-recipes| Parses and uploads nginx configuration for this app."
    task :setup, :roles => :app , :except => { :no_release => true } do
      generate_config(nginx_local_config, nginx_remote_config)
      # create symbolic link on ubuntu
      sudo run <<-CMD
        ln -s "#{nginx_remote_config}" "#{nginx_site_symlink_sites_enabled}"
      CMD
    end

    # this should be done through apt-get or similar... 

    # desc "|capistrano-recipes| Bootstraps Nginx to init.d"
    # task :setup_init, :roles => :app do
    #   upload nginx_init_local, nginx_init_temp, :via => :scp
    #   sudo "mv #{nginx_init_temp} #{nginx_init_remote}"
    #   # Allow executing the init.d script
    #   sudo "chmod +x #{nginx_init_remote}"
    #   # Make it run at bootup
    #   sudo "update-rc.d nginx defaults"
    # end

    desc "|capistrano-recipes| Parses config file and outputs it to STDOUT (internal task)"
    task :parse, :roles => :app , :except => { :no_release => true } do
      puts parse_config(nginx_local_config)
    end

    desc "|capistrano-recipes| Restart nginx"
    task :restart, :roles => :app , :except => { :no_release => true } do
      sudo "service nginx restart"
    end

    desc "|capistrano-recipes| Stop nginx"
    task :stop, :roles => :app , :except => { :no_release => true } do
      sudo "service nginx stop"
    end

    desc "|capistrano-recipes| Start nginx"
    task :start, :roles => :app , :except => { :no_release => true } do
      sudo "service nginx start"
    end

    desc "|capistrano-recipes| Show nginx status"
    task :status, :roles => :app , :except => { :no_release => true } do
      sudo "service nginx status"
    end

    desc "|capistrano-recipes| Enable nginx site"
    task :enable, :roles => :app , :except => { :no_release => true } do
      sudo "nxensite #{application}_#{rails_env}"
    end

    desc "|capistrano-recipes| Disable nginx site"
    task :disable, :roles => :app , :except => { :no_release => true } do
      sudo "nxdissite #{application}_#{rails_env}"
    end
  end

  after 'deploy:setup' do
    nginx.setup if Capistrano::CLI.ui.agree("Create nginx configuration file? [Yn]")
  end if is_using('nginx',:web_server)
end

