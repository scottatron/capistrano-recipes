Capistrano::Configuration.instance.load do
  
  require 'bundler/deployment'
  
  set_default :bundler, true
  
  def bundler?
    bundler == true
  end

  Bundler::Deployment.define_task(self, :task, :except => { :no_release => true })
  set :rake, lambda { "#{fetch(:bundle_cmd, "bundle")} exec rake" }
  
end
