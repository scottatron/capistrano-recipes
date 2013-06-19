Capistrano::Configuration.instance.load do
  # Number of workers (Rule of thumb is 2 per CPU)
  # Just be aware that every worker needs to cache all classes and thus eat some
  # of your RAM.
  set :unicorn_workers, 3 unless exists?(:unicorn_workers)

  # Workers timeout in the amount of seconds below, when the master kills it and
  # forks another one.
  set :unicorn_workers_timeout, 30 unless exists?(:unicorn_workers_timeout)

  # Workers are started with this user/group
  # By default we get the user/group set in capistrano.
  set(:unicorn_user) { user }   unless exists?(:unicorn_user)
  set(:unicorn_group) { group } unless exists?(:unicorn_group)

  # The wrapped bin to start unicorn
  # This is necessary if you're using rvm
  set :unicorn_bin, 'bundle exec unicorn' unless exists?(:unicorn_bin)
  set :unicorn_socket, File.join(sockets_path,"unicorn_#{application}.sock") unless exists?(:unicorn_socket)

  # Defines where the unicorn pid will live.
  set(:unicorn_pid) { File.join(pids_path, "unicorn.pid") } unless exists?(:unicorn_pid)

  set(:unicorn_local_config) { File.join(templates_path, "unicorn.rb.erb") }

  set(:unicorn_remote_config) { "#{shared_path}/config/unicorn.rb" }

  namespace :unicorn do
    desc "|capistrano-recipes| Starts unicorn directly"
    task :start, :roles => :app do
      run "#{sudo} service unicorn start"
    end

    desc "|capistrano-recipes| Stops unicorn directly"
    task :stop, :roles => :app do
      run "#{sudo} service unicorn stop"
    end

    desc "|capistrano-recipes| Restarts unicorn directly"
    task :restart, :roles => :app do
      run "#{sudo} service unicorn restart"
    end

    desc "|capistrano-recipes| Tail unicorn log file"
    task :tail, :roles => :app do
      run "tail -f #{shared_path}/log/unicorn.log" do |channel, stream, data|
        puts "#{channel[:host]}: #{data}"
        break if stream == :err
      end
    end

    desc <<-EOF
    |capistrano-recipes| Parses the configuration file through ERB to fetch our variables and \
    uploads the result to #{unicorn_remote_config}, to be loaded by whoever is booting \
    up the unicorn.
    EOF
    task :setup, :roles => :app , :except => { :no_release => true } do
      run "#{sudo} mkdir -p #{sockets_path}"
      run "#{sudo} chown #{user}:#{group} #{sockets_path} -R"
      run "#{sudo} chmod +rw #{sockets_path}"

      generate_config(unicorn_local_config,unicorn_remote_config)
      run "#{sudo} ln -s #{unicorn_remote_config} /etc/unicorn/unicorn_#{short_name}.rb"
    end
  end

  after 'deploy:setup' do
    unicorn.setup if Capistrano::CLI.ui.agree("Create unicorn configuration file? [Yn]")
  end if is_using('unicorn',:app_server)
end
