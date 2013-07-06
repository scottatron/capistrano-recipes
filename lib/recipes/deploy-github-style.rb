Capistrano::Configuration.instance.load do
  
  set :github_style?,   true

  set(:latest_release)  { fetch(:current_path) }
  set(:release_path)    { fetch(:current_path) }
  set(:current_release) { fetch(:current_path) }
 
  set(:current_revision)  { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
  set(:latest_revision)   { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
  set(:previous_revision) { capture("cd #{current_path}; git rev-parse --short HEAD@{1}").strip }

  set :migrate_target, :current
  set :scm, :git
  set :use_sudo, false

  namespace :deploy do
  
    desc "Setup a GitHub-style deployment."
    task :setup, :except => { :no_release => true } do
      dirs = [deploy_to, shared_path]
      dirs += shared_children.map { |d| File.join(shared_path, d) }
      run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
      run "git clone #{repository} #{current_path}"
    end
  
    task :update do
      transaction do
        update_code
        finalize_update
      end
    end
 
    desc "[internal] Update the deployed code."
    task :update_code, :except => { :no_release => true } do
      run "cd #{current_path}; git fetch origin; git reset --hard #{branch} && git rev-parse HEAD > #{current_path}/REVISION"
    end
  
    desc <<-DESC
      [internal] Touches up the released code. This is called by update_code \
      after the basic deploy finishes.

      This task will make the release group-writable (if the :group_writable \
      variable is set to true, which is the default). It will then set up \
      symlinks to the shared directory for the log and system \
      directories.
    DESC
    task :finalize_update, :except => { :no_release => true } do
    end
  
    desc "[internal]"
    task :symlink do end
  
    desc "[internal]"
    task :cleanup do end
  
    desc "[internal]"
    task :cold do end
    
    desc "[internal]"
    task :check do end
    
    namespace :pending do
      desc "[internal]"
      task :diff do end
    
      # desc "Displays the commits since your last deploy."
      # task :default, :except => { :no_release => true } do
      #   from = source.next_revision(current_revision)
      #   system(source.local.log(from))
      # end
    end

    namespace :rollback do
    
      desc "[internal] Moves the repo back to the previous version of HEAD"
      task :repo, :except => { :no_release => true } do
        set :branch, "HEAD@{1}"
        deploy.default
      end
    
      desc "[internal] Rewrite reflog so HEAD@{1} will continue to point to at the next previous release."
      task :cleanup, :except => { :no_release => true } do
        run "cd #{current_path}; git reflog delete --rewrite HEAD@{1}; git reflog delete --rewrite HEAD@{1}"
      end
    
      desc "Rolls back to the previously deployed version."
      task :default do
        rollback.repo
        rollback.cleanup
      end
    
      desc "[internal]"
      task :code do end
    
    end
  
  end

end