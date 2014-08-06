module Comodule::Deployment::Base

  def self.included(receiver)
    unless receiver < ::Comodule::Deployment::Helper::SystemUtility
      receiver.send :include, ::Comodule::Deployment::Helper::SystemUtility
    end
    receiver.send :include, InstanceMethods
  end

  module InstanceMethods

    def config
      return @config if @config

      @config = ::Comodule::ConfigSupport::Config.new

      @config += yaml_to_config(aws_config_path) if File.file?(aws_config_path)
      @config += yaml_to_config(common_config_path) if File.file?(common_config_path)
      @config += yaml_to_config(config_path)

      @config += yaml_to_config(common_secret_config_path) if File.file?(common_secret_config_path)
      @config += yaml_to_config(secret_config_path) if File.file?(secret_config_path)

      if @config.config_files
        @config.config_files.each do |extend_path|
          path = File.join(platform_root, extend_path)
          @config += yaml_to_config(path) if File.file?(path)
        end
      end

      @config.platform_name = @name

      @config
    end

    def config_copy
      return unless config.cp

      `rm -rf #{test_dir}/file_copy` if test?

      count = 0

      count += file_copy(common_config_dir)
      count += file_copy(common_secret_config_dir)
      count += file_copy(config_dir)
      count += file_copy(secret_config_dir)

      return count
    end

    def file_copy(dir)
      count = 0

      paths = Dir.glob(File.join(dir, '**', '*'))

      order = config.cp.to_hash

      order.each do |key, path_head_list|

        [path_head_list].flatten.each do |path_head|
          wanted = %r|^#{File.join(dir, key.to_s)}|

          paths.each do |file_path|
            next unless File.file?(file_path)
            next unless file_path =~ wanted

            path_tail = file_path.sub(wanted, '')

            path = File.join(path_head, path_tail)
            path = File.join(test_dir, 'file_copy', path) if test?

            dirname, filename = File.split(path)

            be_dir(dirname)

            if file_path =~ /\.erb$/
              File.open(path.sub(/\.erb$/, ''), 'w') do |file|
                file.write render(file_path)
              end
            else
              FileUtils.cp file_path, "#{dirname}/"
            end

            count += 1
          end
        end
      end

      count
    end

    def aws_config_path
      @aws_config_path ||= File.join(platform_root, 'aws_config.yml')
    end

    def config_dir
      @config_dir ||= File.join(platform_dir, 'config')
    end

    def secret_config_dir
      @secret_config_dir ||= File.join(platform_dir, 'secret_config')
    end

    def common_config_dir
      @common_config_dir ||= File.join(platform_root, 'config')
    end

    def common_secret_config_dir
      @common_secret_config_dir ||= File.join(platform_root, 'secret_config')
    end

    def common_config_path
      @common_config_path ||= File.join(platform_root, 'config.yml')
    end

    def common_secret_config_path
      @common_secret_config_path ||= File.join(platform_root, 'secret_config.yml')
    end

    def config_path
      @config_path ||= File.join(platform_dir, 'config.yml')
    end

    def secret_config_path
      @secret_config_path ||= File.join(platform_dir, 'secret_config.yml')
    end

    def tmp_dir
      @tmp_dir ||= be_dir(File.join(platform_dir, 'tmp'))
    end

    def test_dir
      @test_dir ||= be_dir(File.join(platform_dir, 'test'))
    end

    def archives_dir
      @archive_dir ||= be_dir(File.join(tmp_dir, 'archives'))
    end

    def tmp_projects_dir
      @tmp_projects_dir ||= be_dir(File.join(tmp_dir, 'projects'))
    end

    def tmp_project_dir
      @tmp_project_dir ||= File.join(tmp_projects_dir, project_name)
    end

    def project_name
      File.basename project_root
    end

    def git_dir
      @git_dir ||= File.join(project_root, '.git')
    end

    def file_path(*path)
      path = File.join(*path)
      if path =~ %r|^platform/(.*)|
        File.join(platform_root, $1)
      else
        File.join(platform_dir, path)
      end
    end

    def platform_dir
      @platform_dir ||= File.join(platform_root, name)
    end

    def name
      @name
    end

    def project_root
      @project_root ||=
        if defined?(Rails)
          Rails.root
        else
          File.expand_path('../../../../', __FILE__)
        end
    end

    def platform_root
      @platform_root ||= File.join(project_root, 'platform')
    end
  end
end
