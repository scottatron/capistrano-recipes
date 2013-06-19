require "bundler/capistrano"

Capistrano::Configuration.instance.load do
  # User settings
  set :user, 'deploy'   unless exists?(:user)
  set :group,'www-data' unless exists?(:group)

  # HACK
  # Server settings
  set :app_server, :unicorn       unless exists?(:app_server)
  set :web_server, :nginx         unless exists?(:web_server)

  set :runner, user               unless exists?(:runner)
  set :application_port, 80        unless exists?(:application_port)

  set :application_uses_ssl, false unless exists?(:application_uses_ssl)
  set :application_port_ssl, 443   unless exists?(:application_port_ssl)

  set :database, :mysql unless exists?(:database)

  set :scm, :git
  set :branch, 'master' unless exists?(:branch)
  puts "Missing deploy_to path for application... cannot deploy to nil" unless exists?(:deploy_to)
  set :deploy_via, :remote_cache
  set :keep_releases, 3
  set :git_enable_submodules, true
  set :rails_env, 'production' unless exists?(:rails_env)
  set :use_sudo, false
  default_run_options[:pty] = true
  ssh_options[:forward_agent] = true
  set :bundle_flags, "--deployment --without=development test" unless exists?(:bundle_flags)
  set :sockets_path, "/var/run/unicorn" unless exists?(:sockets_path)
  set(:pids_path) { File.join(shared_path, "pids") } unless exists?(:pids_path)
end
