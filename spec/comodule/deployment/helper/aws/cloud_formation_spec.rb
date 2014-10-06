require 'spec_helper'

describe Comodule::Deployment::Helper::Aws::CloudFormation do
  include_context 'deployment.platform'

  before do
    platform.create
    platform.config.aws_region = "ap-northeast-1"
  end

  describe '#cloud_formation' do
    subject { platform.cloud_formation.cfn }

    it 'is wrapper of AWS::CloudFormation' do
      is_expected.to be_an_instance_of(AWS::CloudFormation)
    end
  end

  describe '#stack_basename' do
    subject { platform.cloud_formation.stack_basename }

    context '#config.stack_name_prefix is blank' do

      it do
        is_expected.to eq("#{platform.project_name}-#{platform.name}")
      end
    end

    context '#config.stack_name_prefix is not blank' do
      before do
        platform.config.stack_name_prefix = 'stacknameprefix'
      end

      it do
        is_expected.to eq("#{platform.config.stack_name_prefix}-#{platform.name}")
      end
    end
  end

  let(:basename) { platform.cloud_formation.stack_basename }

  let(:stacks) do
    [
      double('otherstack', name: 'otherstack-20141006'),
      double('stack1', name: "#{basename}-20140101"),
      double('stack2', name: "#{basename}-20131231"),
      double('stack3', name: "#{basename}-20141006"),
      double('stack4', name: "#{basename}-20140831")
    ]
  end

  describe '#own_stacks' do
    subject { platform.cloud_formation.own_stacks }

    it 'returns own cloudFormation stacks' do
      allow(platform.cloud_formation.cfn)
        .to receive(:stacks).and_return(stacks)
      is_expected.to eq(stacks[1..-1])
    end
  end

  describe '#latest_stack' do
    subject { platform.cloud_formation.latest_stack }

    it 'returns latest cloudFormation stack' do
      allow(platform.cloud_formation.cfn)
        .to receive(:stacks).and_return(stacks)
      expect(subject.name).to eq("#{basename}-20141006")
    end
  end
end
