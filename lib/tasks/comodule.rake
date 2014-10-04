require 'comodule'

namespace :comodule do

  def platform
    return @platform if @platform
    platform_name = @args && @args.platform_name
    env = {}

    ['project_root', 'db_host', 'db_password', 'RAILS_ENV', 'env'].each do |env_name|
      env[env_name.to_sym] = ENV[env_name] if ENV[env_name]
    end

    @platform = Comodule::Deployment::Platform.new(platform_name, env)
  end

  task :variables do |cmd, args|
    @args = args
  end

  namespace :platform do

    desc 'Create necessary directories and files for the platform'
    task :create, [:platform_name] => [:environment, :variables] do
      platform.create
    end

    desc 'Upload secret files'
    task :upload_secret_files, [:platform_name] => [:environment, :variables] do
      platform.upload_secret_files
    end

    desc "Download secret files"
    task :download_secret_files, [:platform_name] => [:environment, :variables] do
      platform.download_secret_files
    end

    desc "Upload project files"
    task :upload_project, [:platform_name] => [:environment, :variables] do
      platform.upload_project
    end

    desc 'Validate cloudFormation stack'
    task :validate_template, [:platform_name] => :variables do
      platform.cloud_formation.validate_template
    end

    desc 'Create cloudFormation stack'
    task :create_stack, [:platform_name] => :variables do
      platform.cloud_formation.create_stack
    end

    desc 'Delete cloudFormation stack'
    task :delete_stack, [:platform_name] => :variables do
      platform.cloud_formation.delete_stack
    end

    desc 'Provisioning'
    task :provision, [:platform_name] => :variables do
      platform.deploy
    end

    namespace :ssl do

      desc "Describe IAM server certificates"
      task :describe, [:platform_name] => :variables do
        platform.ssl.describe
      end

      desc "Upload IAM server certificate"
      task :upload, [:platform_name] => :variables do
        platform.ssl.upload
      end

      desc "Delete IAM server certificate"
      task :delete, [:platform_name] => :variables do
        platform.ssl.delete
      end
    end

    namespace :test do

      desc 'Test of upload secret files'
      task :upload_secret_files, [:platform_name] => [:environment, :variables] do
        platform.upload_secret_files_test
      end

      desc "Test of download secret files"
      task :download_secret_files, [:platform_name] => [:environment, :variables] do
        platform.download_secret_files_test
      end
    end
  end
end
