require 'spec_helper'

describe Comodule::Deployment do
  def test_dir
    File.expand_path('../deployment/test', __FILE__)
  end

  def platform_root
    File.join(test_dir, 'platform')
  end

  describe '::Platform' do
    let(:platform) do
      Comodule::Deployment::Platform.new(
        'experiment', platform_root
      )
    end

    it 'file_copy' do
      platform.config_copy
    end

    # it '#upload' do
    #   platform.upload
    # end

    it '#validate_template' do
      cfn = platform.aws.cloud_formation
      result_template = "platform: experiment, user: ec2-user, group: ec2-user, ami: ami-001\n"
      cfn.should_receive(:validate_template).with(result_template)

      file_path = File.join(platform_root, 'experiment', 'test', 'cloud_formation', 'template.json')
      if File.file?(file_path)
        File.unlink(file_path)
      end

      template = platform.validate_template do |config|
        config.ami = 'ami-001'
      end

      expect(File.file?(file_path)).to eq(true)
    end

    it '#aws' do
      iam = platform.aws_access_credentials
      expect(iam.common.access_key_id).to eq('ACCESSKEYID')

      expect(platform.aws.ec2.class).to eq(AWS::EC2)
      expect(platform.aws.rds.class).to eq(AWS::RDS)
      expect(platform.aws.cloud_formation.class).to eq(AWS::CloudFormation)

      cfn = platform.aws.cloud_formation
      expect(cfn.config.access_key_id)
        .to eq(platform.aws_access_credentials.common.access_key_id)
      expect(cfn.config.secret_access_key)
        .to eq(platform.aws_access_credentials.common.secret_access_key)
    end

    it '#config' do
      config = platform.config
      expect(config.user).to eq('ec2-user')
    end
  end
end
