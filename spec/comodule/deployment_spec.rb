require 'spec_helper'

# RSpec.configure do |c|
#   c.filter = {focus: true}
# end

describe Comodule::Deployment do
  def test_dir
    File.expand_path('../deployment/test', __FILE__)
  end

  def project_root
    File.join(test_dir, 'trial')
  end

  def platform_root
    File.join(project_root, 'platform')
  end

  describe '::Platform' do
    # describe 'deploy test' do
    #   let(:platform) do
    #     Comodule::Deployment::Platform.new(
    #       'ami', root: platform_root
    #     )
    #   end

    #   it 'deploy platform: ami', focus: true do
    #     platform.repository_dir = File.join(test_dir, 'trial')
    #     platform.archive_repository
    #     platform.upload_archive
    #     platform.create_stack
    #   end
    # end

    context 'methods' do
      let(:platform) do
        Comodule::Deployment::Platform.new(
          'experiment', project_root: project_root
        )
      end

      # it '#upload_archive' do
      #   platform.repository_dir = File.join(test_dir, 'trial')

      #   local_path = platform.archive_repository

      #   expect(File.file?(local_path)).to eq(true)

      #   s3_path = platform.upload_archive
      #   filename = File.basename(s3_path)

      #   s3_bucket = platform.s3_bucket

      #   expect(s3_bucket.objects[s3_path].exists?).to eq(true)
      #   expect(File.file?(platform.repository_archive_memo_path)).to eq(true)

      #   result_dir = File.join(platform.tmp_dir, 'download_archive_result')
      #   result_path = File.join(result_dir, filename)
      #   platform.download_repository_archive(result_dir)

      #   expect(s3_bucket.objects[s3_path].exists?).to be_false
      #   expect(File.file?(platform.repository_archive_memo_path)).to be_false
      #   expect(File.file?(result_path)).to be_false
      # end

      it '#crontab' do
        path = File.join(platform.crontab_tmp_dir, 'make_cache.txt')
        cmd = "crontab #{path}"
        platform.should_receive(:puts).with("set crontab:\n  #{cmd}")
        platform.should_receive(:dummy).with(:`, "crontab #{path}")

        result = platform.crontab
        expect(result).to eq(1)
      end

      it 'shell_script' do
        path = File.join(platform.shell_script_tmp_dir, 'test.sh')
        platform.should_receive(:dummy).with(:`, "/bin/bash #{path}")

        result = platform.shell_script
        expect(result).to eq(1)
      end

      it '#file_copy' do
        platform.config_copy
      end

      it '#validate_template' do
        cfn = platform.aws.cloud_formation
        result_template = "platform: experiment, user: ec2-user, group: ec2-user, ami: ami-001\n"
        cfn.should_receive(:validate_template).with(result_template).and_return(validation_test: "success")

        file_path = File.join(platform_root, 'experiment', 'test', 'cloud_formation', 'template.json')
        if File.file?(file_path)
          File.unlink(file_path)
        end

        template = platform.cloud_formation.validate_template do |config|
          config.ami = 'ami-001'
        end

        expect(File.file?(file_path)).to eq(true)
      end

      it '#aws' do
        expect(platform.aws.ec2.class).to eq(AWS::EC2)
        expect(platform.aws.rds.class).to eq(AWS::RDS)
        expect(platform.aws.cloud_formation.class).to eq(AWS::CloudFormation)
      end

      it '#config' do
        config = platform.config
        expect(config.user).to eq('ec2-user')
      end
    end
  end
end
