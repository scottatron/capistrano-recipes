Capistrano::Configuration.instance.load do
  namespace :log do
    desc "|capistrano-recipes| Tail all application log files"
    task :tail, :roles => :app do
      run "tail -f #{shared_path}/log/*.log" do |channel, stream, data|
        puts "#{channel[:host]}: #{data}"
        break if stream == :err
      end
    end
    
    desc <<-DESC
    |capistrano-recipes| Install log rotation script; optional args: days=7, size=5M, group (defaults to same value as :user)
    DESC
    task :rotate, :roles => :app do
      rotate_script = 
%Q{
  # application log
  #{shared_path}/log/*.log {
  daily
  rotate #{ENV['days'] || 7}
  size #{ENV['size'] || "5M"}
  compress
  delaycompress
  create 640 #{user} #{group}
  missingok
  notifempty
}
  # nginx
  /var/log/nginx/#{application}/#{environment}.*.log {
  daily
  rotate #{ENV['days'] || 7}
  size #{ENV['size'] || "5M"}
  compress
  delaycompress
  create 640 #{user} #{group}
  missingok
  notifempty
}
}
      puts "----------- ROTATE SCRIPT -----------"
      puts rotate_script
      puts "---------- END ROTATE SCRIPT --------"
      put rotate_script, "#{shared_path}/logrotate_script"
      run "cp #{shared_path}/logrotate_script /etc/logrotate.d/#{application}-#{environment}"
      run "rm #{shared_path}/logrotate_script"
    end
  end
end
