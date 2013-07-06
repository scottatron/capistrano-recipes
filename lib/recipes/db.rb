require 'erb'

Capistrano::Configuration.instance.load do
  namespace :db do
    set_default :db_admin_user, 'root'
    set_default :db_name, 'DATABASE'
    set_default :db_user, 'USER'
    set_default :db_pass, 'PASS'
    
    namespace :mysql do
      
      set_default (:mysql_grant_sql) do
        "CREATE DATABASE IF NOT EXISTS #{db_name}; GRANT ALL PRIVILEGES ON #{db_name}.* TO #{db_user}@localhost IDENTIFIED BY '#{db_pass}';"
      end

      desc <<-EOF
      |capistrano-recipes| Performs a compressed database dump. \
      WARNING: This locks your tables for the duration of the mysqldump.
      Don't run it madly!
      EOF
      task :dump, :roles => :db, :only => { :primary => true } do
        prepare_from_yaml
        run "mysqldump --user=#{db_user} -p --host=#{db_host} #{db_name} | bzip2 -z9 > #{db_remote_file}" do |ch, stream, out|
        ch.send_data "#{db_pass}\n" if out =~ /^Enter password:/
          puts out
        end
      end

      desc "|capistrano-recipes| Restores the database from the latest compressed dump"
      task :restore, :roles => :db, :only => { :primary => true } do
        prepare_from_yaml
        run "bzcat #{db_remote_file} | mysql --user=#{db_user} -p --host=#{db_host} #{db_name}" do |ch, stream, out|
        ch.send_data "#{db_pass}\n" if out =~ /^Enter password:/
          puts out
        end
      end

      desc "|capistrano-recipes| Downloads the compressed database dump to this machine"
      task :fetch_dump, :roles => :db, :only => { :primary => true } do
        prepare_from_yaml
        download db_remote_file, db_local_file, :via => :scp
      end
    
      desc "|capistrano-recipes| Create MySQL database and user for this environment using prompted values"
      task :setup, :roles => :db, :only => { :primary => true } do
        cmd = "mysql -u#{db_admin_user} -p -e\"#{mysql_grant_sql}\""
        if dry_run
          logger.debug cmd
        else
          prepare_from_yaml
          run cmd do |channel, stream, data|
            if data =~ /^Enter password:/
              pass = Capistrano::CLI.password_prompt "Enter database password for '#{db_admin_user}': "
              channel.send_data "#{pass}\n" 
            end
          end
        end
      end
      
      task :destroy, :roles => :db, :only => { :primary => true } do
        prepare_from_yaml
        sql = "DROP DATABASE IF EXISTS #{db_name};"
        run "mysql -u#{db_admin_user} -p -e\"#{sql}\"" do |channel, stream, data|
          if data =~ /^Enter password:/
            pass = Capistrano::CLI.password_prompt "Enter database password for '#{db_admin_user}': "
            channel.send_data "#{pass}\n" 
          end
        end
      end
      
      # Sets database variables from remote database.yaml
      def prepare_from_yaml
        set(:db_file) { "#{application}-dump.sql.bz2" }
        set(:db_remote_file) { "#{shared_path}/backup/#{db_file}" }
        set(:db_local_file)  { db_file }
        set(:db_user) { db_config[rails_env]["username"] }
        set(:db_pass) { db_config[rails_env]["password"] }
        set(:db_host) { db_config[rails_env]["host"] }
        set(:db_name) { db_config[rails_env]["database"] }
      end
        
      def db_config
        @db_config ||= fetch_db_config
      end

      def fetch_db_config
        require 'yaml'
        file = capture "cat #{shared_path}/config/database.yml"
        db_config = YAML.load(file)
      end
    end
    
    desc "|capistrano-recipes| Create database.yml in shared path with settings for current stage and test env"
    task :create_yaml do      
      prepare_for_db_command
      
      db_config = ERB.new <<-EOF
      base: &base
        adapter: mysql2
        encoding: utf8
        username: #{db_user}
        password: #{db_pass}

      #{environment}:
        database: #{db_name}
        <<: *base
      EOF

      ensure_dir_exists "#{shared_path}/config"
      if dry_run
        logger.debug "put #{shared_path}/config/database.yml"
      else
        put db_config.result, "#{shared_path}/config/database.yml"
      end
    end
  end
    
  def prepare_for_db_command
    set(:db_name) { "#{application.gsub(/-/, '')}_#{environment}" }
    set(:db_user) { application.gsub(/-/, '').slice(0, 16) }
    set(:db_pass) { generate_password }
  end
  
  desc "Populates the database with seed data"
  task :seed do
    Capistrano::CLI.ui.say "Populating the database..."
    run "cd #{current_path}; rake RAILS_ENV=#{variables[:rails_env]} db:seed"
  end
  
  after 'deploy:setup' do
    db.create_yaml if Capistrano::CLI.ui.agree("\n--- Create database.yml? [Yn] ")
  end if is_using('mysql', :database)
  
  after 'db:create_yaml' do
    db.mysql.setup if Capistrano::CLI.ui.agree("\n--- Create mysql database and grant privileges? [Yn] ")
  end if is_using 'mysql', :database

  before "symlinks:make" do
    run "rm -f #{release_path}/config/database.yml"
  end if is_using('mysql', :database)
  
end
