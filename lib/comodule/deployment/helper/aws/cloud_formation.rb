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

    def stack_basename
      stack_name = []
      stack_name << (config.stack_name_prefix || owner.project_name)
      stack_name << owner.name
      stack_name.join(?-)
    end

    def own_stacks
      cfn.stacks.find_all { |stack| stack.name =~ /#{stack_basename}/ }
    end

    def latest_stack
      filter = -> stack { stack.name.match(/[0-9]*$/)[0].to_i }
      own_stacks.max { |a,b| filter[a] <=> filter[b] }
    end

    def create_stack(&block)
      if config.upload_secret_files
        puts 'Upload secret files'
        owner.upload_secret_files
      end

      if config.upload_project
        puts 'Upload project'
        owner.upload_project
      end

      stack_name = [stack_basename, Time.now.strftime("%Y%m%d")].join(?-)

      template = validate_template(&block)

      stack = cfn.stacks.create(stack_name, template)

      puts "Progress of creation stack: #{stack.name}"

      status = stack_status_watch(stack)

      puts "\n!!! #{status} !!!\n"
    end

    def delete_stack
      stack = latest_stack

      if !stack || !stack.exists?
        puts "Stack:/#{stack_basename}-[0-9]*/ is not found.\n"
        exit
      end

      print "You are going to delete stack #{stack.name}. Are you sure? [N/y] "
      confirm = STDIN.gets
      unless confirm =~ /^y(es)?$/
        puts "\nAbort!\n"
        exit
      end

      stack.delete

      puts "Progress of deletion stack: #{stack.name}"

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
