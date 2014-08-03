require 'spec_helper'

describe Comodule::Deployment::Platform do

  include_context 'deployment'
  include_context 'platform'

  describe '#create_platform' do

    def directory_check(dir)
      it "makes #{dir}" do
        expect(File.directory?(dir)).to eq(true)
      end
    end

    before do
      platform.create
    end

    it 'mekes necessary directories' do
      [
        platform_root,
        File.join(platform_root, 'config'),
        File.join(platform_root, 'secret_config'),
        File.join(platform_root, 'cloud_formation'),
        platform_dir,
        File.join(platform_dir, 'config'),
        File.join(platform_dir, 'secret_config'),
        File.join(platform_dir, 'cloud_formation')
      ].each do |dir|
        expect(File.directory?(dir)).to eq(true)
      end
    end

    it 'makes necessary files' do
      [
        File.join(platform_root, 'config.yml'),
        File.join(platform_root, 'secret_config.yml'),
        File.join(platform_dir, 'config.yml'),
        File.join(platform_dir, 'secret_config.yml'),
        File.join(platform_root, 'aws_config.yml'),
        File.join(platform_root, '.gitignore')
      ].each do |file|
        expect(File.file?(file)).to eq(true)
      end
    end
  end
end
