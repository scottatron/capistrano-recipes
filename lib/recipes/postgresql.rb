require 'active_support/secure_random'

Capistrano::Configuration.instance.load do
  set_default(:postgresql_host, "localhost")
  set_default(:postgresql_user) { "#{application}".downcase }
  set_default(:postgresql_password) { ActiveSupport::SecureRandom.base64(16) }
  set_default(:postgresql_database) { "#{application}_production".downcase }

  set(:postgresql_database_template) { File.join(templates_path, "postgresql.yml.erb") } 
  set(:postgresql_database_config) { "#{shared_path}/config/database.yml" }

  namespace :postgresql do
    desc "Install the latest stable release of PostgreSQL."
    task :install, roles: :db, only: {primary: true} do
      #run "#{sudo} add-apt-repository ppa:pitti/postgresql"
      run "#{sudo} apt-get -y update"
      run "#{sudo} apt-get -y install postgresql libpq-dev"
    end
    after "deploy:install", "postgresql:install"

    desc "Create a database for this application."
    task :drop_database, roles: :db, only: {primary: true} do
      run %Q{#{sudo} -u postgres psql -c "drop database #{postgresql_database};"}
      run %Q{#{sudo} -u postgres psql -c "drop user #{postgresql_user};"}
    end

    desc "Create a database for this application."
    task :create_database, roles: :db, only: {primary: true} do
      run %Q{#{sudo} -u postgres psql -c "create user #{postgresql_user} with password '#{postgresql_password}';"}
      run %Q{#{sudo} -u postgres psql -c "create database #{postgresql_database} owner #{postgresql_user};"}
    end
    after "postgresql:setup", "postgresql:create_database"

    desc "Generate the database.yml configuration file."
    task :setup, roles: :app do
      run "mkdir -p #{shared_path}/config"
      generate_config(postgresql_database_template, postgresql_database_config)
    end
    after "deploy:setup", "postgresql:setup"

    desc "Symlink the database.yml file into latest release"
    task :symlink, roles: :app do
      run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    end
    after "deploy:finalize_update", "postgresql:symlink"
  end
end