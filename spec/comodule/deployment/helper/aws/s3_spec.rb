require 'spec_helper'

describe Comodule::Deployment::Helper::Aws::S3 do
  include_context 'deployment.platform'

  before do
    platform.create
  end

  let(:bucket_name) { 'comodule-test' }

  describe '#s3' do
    subject { platform.s3.s3 }

    it 'is wrapper of AWS::S3' do
      is_expected.to be_an_instance_of(AWS::S3)
    end
  end

  describe '#bucket_name' do
    subject { platform.s3.bucket_name }

    before do
      platform.config.s3_bucket = bucket_name
    end

    it '== #config.s3_bucket' do
      is_expected.to eq(bucket_name)
    end
  end

  describe '#bucket' do
    subject { platform.s3.bucket }

    let(:s3) { double('s3', 'buckets' => double('[]' => bucket_obj, 'create' => bucket_obj)) }
    let(:bucket_obj) { double('bucket_obj', "exists?" => judge) }

    before do
      platform.config.s3_bucket = bucket_name
      platform.s3.instance_variable_set :@s3, s3
    end

    context 'exists the S3 bucket' do
      let(:judge) { true }

      it 'returns the S3 bucket' do
        allow(s3).to receive_message_chain('buckets.[]', bucket_name)
        allow(bucket_obj).to receive(:exists?).and_return(true)
        is_expected.to eq(bucket_obj)
      end
    end

    context 'not exists the S3 bucket' do
      let(:judge) { false }

      it 'create the S3 bucket' do
        allow(s3).to receive_message_chain('buckets.[]', bucket_name)
        allow(bucket_obj).to receive(:exists?).and_return(false)
        allow(s3).to receive_message_chain('buckets.create', bucket_name)
        is_expected.to eq(bucket_obj)
      end
    end
  end

  describe '#path' do
    subject { platform.s3.path(File.join(platform.secret_config_dir, 'secret.txt')) }

    it "return a path on S3" do
      is_expected.to eq("#{platform.name}/platform/#{platform.name}/secret_config/secret.txt")
    end
  end

  describe '#path_in_local' do
    let(:path) { File.join platform.secret_config_dir, 'secret.txt' }

    subject do
      s3_path = platform.s3.path(path)
      platform.s3.path_in_local(s3_path)
    end

    it 'return a path in local' do
      is_expected.to eq(path)
    end
  end
end
