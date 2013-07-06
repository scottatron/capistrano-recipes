Capistrano::Configuration.instance.load do
  
  set_default :normal_symlinks, %w(log config/database.yml)
  set_default :mapped_symlinks, { 'bundle'  => 'vendor/bundle', 'pids' => 'tmp/pids', 'sockets' => 'tmp/sockets' }

  namespace :symlinks do
    desc "Make all the symlinks in a single run"
    task :make, :roles => :app, :except => { :no_release => true } do
      commands = ["cd #{latest_release}"]
      commands.concat normal_symlinks.map {|path| "rm -rf #{latest_release}/#{path}" }
      commands.concat normal_symlinks.map {|path| "ln -s #{shared_path}/#{path} #{latest_release}/#{path}" }
      commands.concat mapped_symlinks.map {|from, to| "rm -rf #{latest_release}/#{to}" }
      commands.concat mapped_symlinks.map {|from, to| "ln -s #{shared_path}/#{from} #{latest_release}/#{to}" }
      run commands.join(" && ")
    end
  end
end
