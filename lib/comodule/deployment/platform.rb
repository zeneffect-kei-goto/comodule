class Comodule::Deployment::Platform
  include ::Comodule::Deployment::Base
  include ::Comodule::Deployment::Helper

  def initialize(name, hsh={})
    if ['config', 'secret_config'].member?(name)
      raise ArgumentError, %Q|Don't use the platform name [#{name}].|
    end

    @platform = name
    @project_root = hsh[:project_root] if hsh[:project_root]

    if hsh[:db_host]
      config.db ||= {}
      config.db.host = hsh[:db_host]
    end

    if hsh[:db_password]
      config.db ||= {}
      config.db.password = hsh[:db_password]
    end

    self.env = hsh[:RAILS_ENV].to_sym if hsh[:RAILS_ENV]
    self.env = hsh[:env].to_sym if hsh[:env]
  end

  def create_platform
    be_dir(platform_root, platform_dir, cloud_formation_dir, config_dir, secret_config_dir)

    be_file(
      File.join(cloud_formation_dir, '.keep'),
      File.join(config_dir, '.keep'),
      config_path,
      "#{secret_config_path}.default"
    )

    gitignore_path = File.join(platform_root, '.gitignore')

    unless File.file?(gitignore_path)
      File.open(gitignore_path, 'w') do |file|
        file.write <<-HERE
/**/test
/**/tmp
/**/secret_config/*
/**/secret_config.yml
/**/stack
secret_config/*
secret_config.yml
        HERE
      end
    end

    nil
  end


  def deploy
    download
    @config = nil
    config_copy
    chown
    shell_script
    crontab
  end


  def cloud_formation_dir
    @cloud_formation_dir ||= be_dir(File.join(platform_dir, 'cloud_formation'))
  end

  def common_cloud_formation_dir
    @common_cloud_formation_dir ||= be_dir(File.join(platform_root, 'cloud_formation'))
  end

  def cloud_formation_test_dir
    @cloud_formation_test_dir ||= be_dir(File.join(test_dir, 'cloud_formation'))
  end


  def common_crontab_dir
    @common_crontab_dir ||= File.join(common_config_dir, 'crontab')
  end

  def crontab_dir
    @crontab_dir ||= File.join(config_dir, 'crontab')
  end

  def secret_crontab_dir
    @secret_crontab_dir ||= File.join(secret_config_dir, 'crontab')
  end

  def crontab_tmp_dir
    @crontab_tmp_dir ||= File.join(tmp_dir, 'crontab')
  end


  def common_shell_script_dir
    @common_shell_script_dir ||= File.join(common_config_dir, 'shell_script')
  end

  def shell_script_dir
    @shell_script_dir ||= File.join(config_dir, 'shell_script')
  end

  def secret_shell_script_dir
    @secret_shell_script_dir ||= File.join(secret_config_dir, 'shell_script')
  end

  def shell_script_tmp_dir
    @shell_script_tmp_dir ||= File.join(tmp_dir, 'shell_script')
  end


  def s3_bucket_name=(name)
    @s3_bucket_name = name
  end

  def s3_bucket_name
    @s3_bucket_name ||= config.s3_bucket
  end

  def s3_bucket
    return @s3_bucket if @s3_bucket
    s3 = aws.s3
    bucket_name = s3_bucket_name
    s3.buckets.create(bucket_name) unless s3.buckets[bucket_name].exists?
    @s3_bucket = s3.buckets[bucket_name]
  end


  def env
    return @env if @env
    self.env = defined?(Rails) ? Rails.env : nil
  end

  def env=(name)
    return if !name || name.empty?
    @env = name.to_sym
  end

  def production?
    env && !env.empty? && env == :production
  end

  def deployment?
    env && !env.empty? && env != :test && env != :development
  end

  def test?
    !deployment?
  end
end
