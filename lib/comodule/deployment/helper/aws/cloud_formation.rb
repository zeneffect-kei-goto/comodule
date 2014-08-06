module Comodule::Deployment::Helper::Aws::CloudFormation

  def self.included(receiver)
    receiver.send :include, InstanceMethods
  end

  module InstanceMethods
    def cloud_formation
      @cloud_formation ||= ::Comodule::Deployment::Helper::Aws::CloudFormation::Service.new(self)
    end
  end

  class Service
    include ::Comodule::Deployment::Helper::Aws::Base

    def cfn
      @cfn ||= aws.cloud_formation
    end

    def create_stack(&block)
      if config.upload_secret_files
        puts 'Upload secret files'
        upload
      end

      if config.upload_project
        puts 'Upload project'
        upload_project
      end

      stack_name = []
      stack_name << config.stack_name_prefix if config.stack_name_prefix
      stack_name << owner.platform
      stack_name << Time.now.strftime("%Y%m%d")
      stack_name = stack_name.join(?-)

      template = validate_template(&block)

      stack = cfn.stacks.create(stack_name, template)

      stack_name = stack.name
      puts "Progress of creation stack: #{stack_name}"

      File.open(File.join(owner.cloud_formation_dir, 'stack'), 'w') do |file|
        file.write stack_name
      end

      status = stack_status_watch(stack)

      puts "\n!!! #{status} !!!\n"
    end

    def delete_stack
      stack_memo_path = File.join(owner.cloud_formation_dir, 'stack')

      unless File.file?(stack_memo_path)
        puts "stack not found.\n"
        exit
      end

      stack_name = File.open(stack_memo_path).read

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
      template = cloud_formation_template(&block)

      template_path = File.join(owner.test_cloud_formation_dir, 'template.json')

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

      file = File.join(owner.cloud_formation_dir, 'template.json.erb')
      common_file = File.join(owner.common_cloud_formation_dir, 'template.json.erb')

      owner.render( File.file?(file) ? file : common_file )
    end
  end
end
