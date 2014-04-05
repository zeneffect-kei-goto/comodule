class Comodule::Deployment::Platform
  include ::Comodule::Deployment::Helper

  def initialize(name, hsh={})
    @platform = name
    @platform_root = hsh[:root] if hsh[:root]
    config.db_host = hsh[:db_host] if hsh[:db_host]
  end


  def deploy
    download
    config_copy
    shell_script
    crontab
  end


  def create_stack(&block)
    upload

    cfn = aws.cloud_formation

    stack_name = []
    stack_name << config.stack_name_prefix if config.stack_name_prefix
    stack_name << platform
    stack_name << Time.zone.now.strftime("%Y%m%d")
    stack_name = stack_name.join(?-)

    template = validate_template(&block)

    stack = cfn.stacks.create(stack_name, template)

    stack_name = stack.name
    puts "Progress of creation stack: #{stack_name}"

    File.open(File.join(cloud_formation_dir, 'stack'), 'w') do |file|
      file.write stack_name
    end

    status = stack_status_watch(stack)

    puts "\n!!! #{status} !!!\n"
  end

  def delete_stack
    stack_memo_path = File.join(cloud_formation_dir, 'stack')

    unless File.file?(stack_memo_path)
      puts "stack not found.\n"
      exit
    end

    stack_name = File.open(stack_memo_path).read

    cfn = aws.cloud_formation

    stack = cfn.stacks[stack_name]

    unless stack.exists?
      puts "Stack:#{stack_name} is not found.\n"
      exit
    end

    print "You are going to delete stack #{stack_name}. Are you sure? [N/y] "
    confirm = STDIN.gets
    unless confirm =~ /^y(es)?$/
      puts "\nAbort!\n"
      exit
    end

    stack.delete

    puts "Progress of deletion stack: #{stack_name}"

    status = stack_status_watch(stack)

    puts "\n!!! #{status} !!!\n"
  end

  def stack_status_watch(stack, interval=10)
    begin
      status = stack.status
    rescue
      return 'Missing stack'
    end

    first_status = status
    before_status = ""

    while status == first_status
      if status == before_status
        before_status, status = status, ?.
      else
        before_status = status
      end

      print status

      sleep interval

      begin
        status = stack.status
      rescue
        status = "Missing stack"
        break
      end
    end

    status
  end


  def validate_template(&block)
    cfn = aws.cloud_formation

    template = cloud_formation_template(&block)

    template_path = if production?
      File.join(cloud_formation_dir, 'template.json')
    else
      File.join(cloud_formation_test_dir, 'template.json')
    end

    File.open(template_path, 'w') do |file|
      file.write template
    end

    result = cfn.validate_template(template)

    puts "Validation result:"
    result.each do |key, msg|
      puts "  #{key}: #{msg}"
    end

    template
  end

  def cloud_formation_template
    if block_given?
      yield config
    end

    render(File.join(cloud_formation_dir, 'template.json.erb'))
  end

  def render(path)
    ERB.new(File.read(path)).result(binding)
  end

  def render_in_tmp(file_path, tmp_dir)
    return unless file_path =~ /\.erb$/

    dir, filename = File.split(file_path)
    tmp_path = File.join(tmp_dir, filename.sub(/\.erb$/, ''))
    File.open(tmp_path, 'w') do |file|
      file.write render(file_path)
    end

    tmp_path
  end


  def crontab
    count = 0

    paths  = Dir.glob(File.join(crontab_dir, '**', '*'))
    paths += Dir.glob(File.join(secret_crontab_dir, '**', '*'))

    File.unlink(*Dir.glob(File.join(crontab_tmp_dir, '*')))
    paths.each do |file_path|
      next unless File.file?(file_path)

      if file_path =~ /\.erb$/
        file_path = render_in_tmp(file_path, crontab_tmp_dir)
      end

      cmd = "crontab #{file_path}"
      puts "set crontab:\n  #{cmd}"

      if production?
        `#{cmd}`
      else
        dummy :`, cmd
      end

      count +=1
    end

    count
  end

  def crontab_dir
    @crontab_dir ||= File.join(config_dir, 'crontab')
  end

  def secret_crontab_dir
    @secret_crontab_dir ||= File.join(secret_config_dir, 'crontab')
  end

  def crontab_tmp_dir
    return @crontab_tmp_dir if @crontab_tmp_dir

    @crontab_tmp_dir = be_dir(File.join(tmp_dir, 'crontab'))
  end


  def dummy(method_name, *args)
    puts "execute dummy method: #{method_name}, args: #{args}"
  end


  def shell_script
    count = 0

    paths  = Dir.glob(File.join(shell_script_dir, '**', '*'))
    paths += Dir.glob(File.join(secret_shell_script_dir, '**', '*'))

    shell_path = config.shell || '/bin/bash'

    File.unlink(*Dir.glob(File.join(shell_script_tmp_dir, '*')))
    paths.each do |file_path|
      next unless File.file?(file_path)

      if file_path =~ /\.erb$/
        file_path = render_in_tmp(file_path, shell_script_tmp_dir)
      end

      cmd = "#{shell_path} #{file_path}"

      if production?
        `#{shell_path} #{file_path}`
      else
        dummy :`, cmd
      end

      count += 1
    end

    count
  end

  def shell_script_dir
    @shell_script_dir ||= File.join(config_dir, 'shell_script')
  end

  def secret_shell_script_dir
    @secret_shell_script_dir ||= File.join(secret_config_dir, 'shell_script')
  end

  def shell_script_tmp_dir
    return @shell_script_tmp_dir if @shell_script_tmp_dir

    @shell_script_tmp_dir = be_dir(File.join(tmp_dir, 'shell_script'))
  end

  def tmp_dir
    return @tmp_dir if @tmp_dir

    @tmp_dir = be_dir(File.join(platform_dir, 'tmp'))
  end


  def config_copy
    return unless config.cp

    count = 0

    count += file_copy(config_dir)
    count += file_copy(secret_config_dir)

    return count
  end

  def file_copy(dir)
    count = 0

    paths = Dir.glob(File.join(dir, '**', '*'))

    order = config.cp.to_hash

    order.each do |key, path_head|
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
          next
        end

        FileUtils.cp file_path, "#{dirname}/"

        count += 1
      end
    end

    count
  end


  def config
    return @config if @config

    @config = yaml_to_config(config_path)

    @config += yaml_to_config(secret_config_path) if File.file?(secret_config_path)

    @config
  end

  def config_dir
    @config_dir ||= File.join(platform_dir, 'config')
  end

  def secret_config_dir
    @secret_config_dir ||= File.join(platform_dir, 'secret_config')
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


  def upload
    if File.directory?(secret_dir)
      Dir.glob(File.join(secret_dir, '**', '*')).each do |path|
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
      s3_obj.delete
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
    env && env.to_sym == :production
  end

  def test?
    !production?
  end

  def cloud_formation_dir
    return @cloud_formation_dir if @cloud_formation_dir

    @cloud_formation_dir = be_dir(File.join(platform_dir, 'cloud_formation'))
  end

  def cloud_formation_test_dir
    return @cloud_formation_test_dir if @cloud_formation_test_dir

    @cloud_formation_test_dir = be_dir(File.join(test_dir, 'cloud_formation'))
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
