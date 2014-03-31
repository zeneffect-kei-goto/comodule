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

  def validate_template &block
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
    @config ||= yaml_to_config(File.join(platform_dir, 'config.yml'))
  end

  def iam_config=(path)
    @iam = yaml_to_config(path)
  end

  def iam_config
    @iam_config ||= yaml_to_config(File.join(platform_dir, 'aws_iam.yml'))
  end

  def aws
    @aws ||= AwsSdk.new(iam_config)
  end

  def env
    @env || (defined?(Rails) ? Rails.env : nil)
  end

  def env=(name)
    @env = name
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
