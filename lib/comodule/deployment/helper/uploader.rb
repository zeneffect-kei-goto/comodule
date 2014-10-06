module Comodule::Deployment::Helper::Uploader

  def self.included(receiver)
    unless receiver < ::Comodule::Deployment::Helper::Aws::S3
      receiver.send :include, ::Comodule::Deployment::Helper::Aws::S3
    end
  end

  def secret_files
    (
      Dir.glob(File.join(common_secret_config_dir, '**', '*')) |
      Dir.glob(File.join(secret_config_dir, '**', '*')) <<
      File.join(common_secret_config_path) <<
      File.join(secret_config_path)
    ).find_all { |path| File.file?(path) }
  end

  def test_upload_secret_files_dir
    @test_upload_secret_files_dir ||= File.join(test_dir, 'upload_secret_files')
  end

  def upload_secret_files_test
    test_mode do
      upload_secret_files
    end
  end

  def upload_secret_files
    return unless config.upload_secret_files

    re_dir test_upload_secret_files_dir

    secret_files.each do |path|
      s3_path = s3.local_to_cloud(path)

      dir = File.dirname(File.join(test_upload_secret_files_dir, s3_path))
      be_dir dir
      FileUtils.cp path, dir

      obj = s3.bucket.objects[s3_path]
      obj.write Pathname.new(path), server_side_encryption: :aes256
    end
  end

  def test_download_secret_files_dir
    @test_download_secret_files_dir ||= File.join(test_dir, 'download_secret_files')
  end

  def download_secret_files_test
    test_mode do
      download_secret_files
    end
  end

  def download_secret_files
    return unless config.s3_bucket

    unless deployment?
      re_dir test_download_secret_files_dir
    end

    s3.bucket.objects.with_prefix("#{name}/").each do |s3_obj|
      local_path =
        if deployment?
          s3.cloud_to_local s3_obj.key
        else
          s3_obj.key.sub(%r|^#{name}/|, test_download_secret_files_dir)
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
    branch = `echo $(cd #{project_root} ; git rev-parse --abbrev-ref HEAD)`.strip
    commit = `echo $(cd #{project_root} ; git rev-parse HEAD)`.strip
    "branch: #{branch}\n" + "commit: #{commit}\n"
  end

  def tmp_archives_dir
    @tmp_archives_dir ||= be_dir(File.join(tmp_dir, 'archives'))
  end

  def archive_filename
    "#{project_name}-#{config.platform_name}.tar.gz"
  end

  def archive_path
    File.join tmp_archives_dir, archive_filename
  end

  def archive_s3_path
    archive_path.sub %r|^#{tmp_dir}/|, ''
  end

  def archive_s3_public_url
    s3.bucket.objects[archive_s3_path].public_url secure: true
  end

  def download_project
    local_dir = File.join(test_dir, 'download_archive')
    re_dir local_dir

    s3_path = archive_s3_path
    filename = File.basename(s3_path)
    local_path = File.join(local_dir, filename)

    File.open(local_path, 'wb') do |file|
      file.write s3.bucket.objects[s3_path].read
    end

    `( cd #{local_dir} ; tar xfz #{filename} )`

    local_path
  end

  def archive_project
    unless File.directory?(git_dir)
      puts ".git not found"
      raise
    end

    rm_rf tmp_project_dir

    `git clone #{git_dir} #{tmp_project_dir}`
    rm_rf File.join(tmp_project_dir, '.git') if config.upload_project == 'without_git'

    File.open(File.join(tmp_project_dir, 'project_stamp.txt'), 'w') do |file|
      file.write project_stamp
    end

    gz_path = archive_path
    `( cd #{tmp_project_dir} ; tar cfz #{gz_path} . )`

    gz_path
  end

  def upload_archive(path = archive_path)
    s3_path = archive_s3_path
    obj = s3.bucket.objects[s3_path]
    obj.write(
      Pathname.new(path),
      server_side_encryption: :aes256
    )
  end
end
