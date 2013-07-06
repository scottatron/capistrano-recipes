Capistrano::Configuration.instance.load do

  require 'gitlab'
  
  before 'deploy:setup', 'gitlab:setup'

  set_default :gitlab_api_endpoint, 'https://gitlab.com/api/v3'
  set_default :gitlab_api_token, ''
  set_default :gitlab_public_key, '$HOME/.ssh/id_dsa.pub'
  set_default(:gitlab_key_name_prefix) { application }

  def gitlab_api
    Gitlab.client(endpoint: gitlab_api_endpoint, private_token: gitlab_api_token)
  end

  def find_project_by_name(name)
    gitlab_api.projects.select{|project| project.path == name }.shift
  end

  def mac_address
    capture('ifconfig eth0 | grep -Eo ..\(\:..\){5}').gsub(/:/, '-').strip
  end

  def key_name
    @key_name ||= "#{gitlab_key_name_prefix}::#{capture('whoami').strip}-on-#{capture('hostname').strip}-#{mac_address}"
  end

  def key
    capture("cat #{gitlab_public_key}")
  end
  
  namespace :gitlab do
    desc 'Add deploy key to GitLab'
    task :setup do
      if !exists?(:gitlab_api_token) || fetch(:gitlab_api_token).empty?
        logger.important "API token (:gitlab_api_token) is missing", 'GitLab'
        abort
      else
        if dry_run
          logger.debug 'Adding deploy key', 'GitLab'
        else
          # Gitlab.com doesn't currently support project keys via API
          # project = find_project_by_name(application)
          # gitlab_api.post("/projects/#{project.id}/keys", {title: key_name, key: key})
          logger.trace "Adding deploy key - #{key_name}", 'GitLab'
          gitlab_api.create_ssh_key key_name, key
          run "ssh -oStrictHostKeyChecking=no git@gitlab.com"
        end
      end
    end
  end
  
end