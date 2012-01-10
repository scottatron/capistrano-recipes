# Common hooks for all scenarios.
Capistrano::Configuration.instance.load do
  after "deploy:finalize_update" do
    symlinks.make
  end
end
