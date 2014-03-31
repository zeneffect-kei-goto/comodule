class Comodule::Deployment::Platform
  include ::Comodule::Deployment::Helper

  def initialize(name, root=nil)
    @platform = name
    @platform_root = root if root
  end

  def deploy(db_host)
    options[:db_host]  = db_host
  end

  def create_stack
  end

  def delete_stack
  end

  def validate_template(&block)
    cfn = aws.cloud_formation

    dir = if test?
      be_dir(File.join(test_dir, 'cloud_formation'))
    else
      cloud_formation_dir
    end

    template = cloud_formation_template &block

    File.open(File.join(dir, 'template.json'), 'w') do |file|
      file.write template
    end

    puts cfn.validate_template(template)
  end

  def config
    return @config if @config

    @config = yaml_to_config(config_path)

    @config += yaml_to_config(secret_config_path) if File.file?(secret_config_path)

    @config
  end

  def config_path
    @config_path ||= File.join(platform_dir, 'config.yml')
  end

  def secret_config_path
    @secret_config_path ||= File.join(platform_dir, 'secret_config.yml')
  end

  def aws_access_credentials
    config.aws_access_credentials
  end

  def aws
    @aws ||= AwsSdk.new(aws_access_credentials)
  end

  def env
    @env || (defined?(Rails) ? Rails.env : nil)
  end

  def env=(name)
    @env = name
  end

  def cloud_formation_template
    if block_given?
      yield config
    end

    ERB.new(
      File.read(
        File.join(cloud_formation_dir, 'template.json.erb')
      )
    ).result(binding)
  end

  def secret_dir
    @secret_dir ||= File.join(platform_dir, 'secret')
  end

  def upload
    if File.directory?(secret_dir)
      Dir.glob("#{secret_dir}/**/*").each do |path|
        next unless File.file?(path)
        s3_path = path.sub(%r|^#{platform_dir}/|, '')
        obj = s3_bucket.objects[s3_path]
        obj.write Pathname.new(path), server_side_encryption: :aes256
      end
    end
  end

  def download(credentials=nil)
    if credentials
      config.aws_access_credentials = credentials
    end

    s3_bucket.objects.each do |s3_obj|
      local_path = File.join(platform_dir, s3_obj.key)
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


private

  def test_dir
    return @test_dir if @test_dir
    @test_dir = be_dir(File.join(platform_dir, 'test'))
  end

  def production?
    env.to_sym == :production
  end

  def test?
    !production?
  end

  def cloud_formation_dir
    File.join(platform_dir, 'cloud_formation')
  end

  def platform_dir
    @platform_dir ||= File.join(platform_root, platform)
  end

  def platform
    @platform
  end

  def platform_root
    return @platform_root if @platform_root

    if defined?(Rails)
      dir = File.join(Rails.root, 'platform')
      if File.directory?(dir)
        @platform_root = dir
      end
    end

    unless @platform_root
      raise ArgumentError, "Comodule::Deployment.platform_root is missing directory."
    end
    @platform_root
  end
end
