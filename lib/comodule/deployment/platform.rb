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


  def chown
    return unless config.chown

    [config.chown].flatten.each do |arg|
      command_or_dummy "chown #{arg}"
    end
  end


  def crontab
    count = 0

    paths  = Dir.glob(File.join(common_crontab_dir, '**', '*'))
    paths += Dir.glob(File.join(crontab_dir, '**', '*'))
    paths += Dir.glob(File.join(secret_crontab_dir, '**', '*'))

    `rm -rf #{crontab_tmp_dir}`
    be_dir crontab_tmp_dir

    paths.each do |path|
      next unless File.file?(path)

      if path =~ /\.erb$/
        path = render_in_tmp(path, crontab_tmp_dir)
      end

      cmd = "crontab #{path}"
      puts "set crontab:\n  #{cmd}"

      command_or_dummy cmd

      count += 1
    end

    count
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


  def shell_script
    count = 0

    paths  = Dir.glob(File.join(common_shell_script_dir, '**', '*'))
    paths += Dir.glob(File.join(shell_script_dir, '**', '*'))
    paths += Dir.glob(File.join(secret_shell_script_dir, '**', '*'))

    shell_path = config.shell || '/bin/bash'

    `rm -rf #{shell_script_tmp_dir}`
    be_dir shell_script_tmp_dir
    paths.each do |file_path|
      next unless File.file?(file_path)

      if file_path =~ /\.erb$/
        file_path = render_in_tmp(file_path, shell_script_tmp_dir)
      end

      command_or_dummy "#{shell_path} #{file_path}"

      count += 1
    end

    count
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


  def upload_project
    upload_archive archive_project
  end

  def project_stamp
    branch = `echo $(cd #{project_dir} ; git rev-parse --abbrev-ref HEAD)`.strip
    commit = `echo $(cd #{project_dir} ; git rev-parse HEAD)`.strip
    "branch: #{branch}\n" + "commit: #{commit}\n"
  end

  def archive_path
    File.join archives_dir, "#{platform}.tar.gz"
  end

  def archive_s3_path
    archive_path.sub %r|^#{tmp_dir}/|, ''
  end

  def archive_s3_public_url
    s3_bucket.objects[archive_s3_path].public_url secure: true
  end

  def download_project
    local_dir = File.join(test_dir, 'download_archive')
    `rm -rf #{local_dir}`
    be_dir local_dir

    s3_path = archive_s3_path
    filename = File.basename(s3_path)
    local_path = File.join(local_dir, filename)

    File.open(local_path, 'wb') do |file|
      file.write s3_bucket.objects[s3_path].read
    end

    `( cd #{local_dir} ; tar xfz #{filename} )`

    File.unlink(local_path)
  end

  def archive_project
    unless File.directory?(git_dir)
      puts ".git not found"
      return
    end

    `rm -rf #{tmp_project_dir}`

    `git clone #{git_dir} #{tmp_project_dir}`
    `rm -rf #{File.join(tmp_project_dir, '.git')}` if config.upload_project == 'without_git'

    File.open(File.join(tmp_project_dir, 'project_stamp.txt'), 'w') do |file|
      file.write project_stamp
    end

    gz_path = archive_path
    `( cd #{tmp_project_dir} ; tar cfz #{gz_path} . )`

    gz_path
  end

  def upload_archive(path = archive_path)
    s3_path = archive_s3_path
    obj = s3_bucket.objects[s3_path]
    obj.write(
      Pathname.new(path),
      server_side_encryption: :aes256
    )
  end


  def secret_files
    Dir.glob(File.join(common_secret_config_dir, '**', '*')) |
    Dir.glob(File.join(secret_config_dir, '**', '*')) <<
    File.join(common_secret_config_path) <<
    File.join(secret_config_path)
  end

  def upload_test
    original, self.env = env, :test
    upload
    self.env = original
  end

  def upload
    return unless config.s3_bucket

    if env == :test
      test_upload_dir = File.join(test_dir, 'upload_secret_files')
      `rm -rf #{test_upload_dir}`
      be_dir test_upload_dir
    else
      s3_bucket.objects.with_prefix("#{platform}/").delete_all
    end

    secret_files.each do |path|
      next unless File.file?(path)

      s3_path = path.sub(%r|^#{File.dirname(platform_root)}/|, "#{platform}/")

      if env == :test
        dir = File.dirname(File.join(test_upload_dir, s3_path))
        be_dir dir
        FileUtils.cp path, dir
      else
        obj = s3_bucket.objects[s3_path]
        obj.write Pathname.new(path), server_side_encryption: :aes256
      end
    end
  end

  def download
    return unless config.s3_bucket

    if test?
      test_download_dir = File.join(test_dir, 'download_secret_files')
      `rm -rf #{test_download_dir}`
      be_dir test_download_dir
    end

    s3_bucket.objects.with_prefix("#{platform}/").each do |s3_obj|
      local_path =
        unless test?
          s3_obj.key.sub(%r|^#{platform}/platform|, platform_root)
        else
          s3_obj.key.sub(%r|^#{platform}/platform|, test_download_dir)
        end

      be_dir File.dirname(local_path)

      File.open(local_path, 'w') do |file|
        file.write s3_obj.read
      end
    end
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

private

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
