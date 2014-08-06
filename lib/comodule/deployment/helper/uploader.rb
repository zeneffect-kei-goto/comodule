module Comodule::Deployment::Helper::Uploader

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


  def upload_project
    upload_archive archive_project
  end

  def project_stamp
    branch = `echo $(cd #{project_dir} ; git rev-parse --abbrev-ref HEAD)`.strip
    commit = `echo $(cd #{project_dir} ; git rev-parse HEAD)`.strip
    "branch: #{branch}\n" + "commit: #{commit}\n"
  end

  def archive_path
    File.join tmp_archives_dir, "#{platform}.tar.gz"
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
end
