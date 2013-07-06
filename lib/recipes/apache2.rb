Capistrano::Configuration.instance.load do
  namespace :apache2 do
    
    set_default (:apache2_vhost_local_template) { "#{templates_path}/apache2-vhost.conf.erb" }
    set_default (:apache2_vhost_remote_config_dir) { "#{shared_path}/config/" }
    set_default (:apache2_vhost_remote_config_file) { "#{application}.conf" }
    set_default (:apache2_vhost_remote_config) { "#{apache2_vhost_remote_config_dir}#{apache2_vhost_remote_config_file}" }
    
    set_default :hostnames, []
    
    def canonical_hostname
      hostnames.first
    end
    
    def other_hostnames
      hostnames.slice(1, hostnames.length) || []
    end
    
    def other_hostnames?
      !other_hostnames.empty?
    end
    
    task :enable, :roles => :app , except: { no_release: true } do
      run "#{sudo} APACHE_SITES_AVAILABLE=#{apache2_vhost_remote_config_dir} a2ensite #{apache2_vhost_remote_config_file}"
    end
    
    task :disable, :roles => :app , except: { no_release: true } do
      run "a2dissite #{apache2_vhost_remote_config_file}"
    end
    
    def apache2_config_ok?
      (capture('apache2ctl -t').strip == 'Syntax OK') || true
    end
    
    task :reload, :roles => :app , except: { no_release: true } do
      sudo 'apache2ctl graceful' if apache2_config_ok?
    end
    
    desc "Sets up Apache2 config"
    task :setup, :roles => :app , except: { no_release: true } do
      generate_config(apache2_vhost_local_template, apache2_vhost_remote_config)
      enable
      reload
    end
    
  end
end