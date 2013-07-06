# Common hooks for all scenarios.
Capistrano::Configuration.instance.load do
  
  after 'deploy:setup' do
    apache2.setup if is_using 'apache2', :web_server
    if is_using 'mysql', :database
      db.create_yaml
      db.mysql.setup
    end
    symlinks.make if github_style?
  end
  
  after "deploy:finalize_update" do
    symlinks.make unless github_style?
  end
end
