require 'spec_helper'

describe Comodule::Deployment::Helper::SystemUtility do

  include_context 'deployment'
  include_context 'platform'

  let(:sample_yaml) do
    <<-HERE
production:
  username: <%= config.db.username %>
  password: <%= config.db.password %>
    HERE
  end

  let(:sample_result) do
    <<-HERE
production:
  username: jamiroquai
  password: afunkodyssey
    HERE
  end

  let(:erb_path) { File.join(platform_dir, 'config', 'database.yml.erb') }

  before do
    platform.create

    File.open(File.join(platform_root, 'config.yml'), 'w') do |file|
      file.write <<-HERE
db:
  username: jamiroquai
  password: afunkodyssey
      HERE
    end

    File.open(erb_path, 'w') do |file|
      file.write sample_yaml
    end
  end

  describe '#render' do

    subject { platform.render(erb_path) }

    it 'render erb' do
      should eq(sample_result)
    end
  end

  describe '#render_in_path' do

    let(:path) do
      FileUtils.mkdir_p File.join(platform_root, 'render_in_dir_test')
      File.join(platform_root, 'render_in_dir_test', 'database_config.yml')
    end

    subject { platform.render_in_path erb_path, path }

    it 'makes a file rendered erb in specify path' do
      should eq(path)
      expect(File.file?(path)).to eq(true)
      expect(File.read(path)).to eq(sample_result)
    end
  end

  describe '#render_in_dir' do

    let(:in_dir) { File.join(platform_root, 'render_in_dir_test') }

    before do
      FileUtils.mkdir_p in_dir
    end

    subject { platform.render_in_dir erb_path, in_dir }

    it 'makes a file rendered erb in specify directory' do
      result_path = File.join(in_dir, 'database.yml')
      should eq(result_path)
      expect(File.file?(result_path)).to eq(true)
      expect(File.read(result_path)).to eq(sample_result)
    end
  end

  describe '#yaml_to_config' do

    let(:path) do
      FileUtils.mkdir_p File.join(platform_root, 'yaml_to_config_test')
      File.join(platform_root, 'yaml_to_config_test', 'database.yml')
    end

    before do
      platform.render_in_path erb_path, path
    end

    subject { platform.yaml_to_config(path).to_hash }

    it 'makes a ConfigSupport::Config instance source specify file' do
      should eq({ production: { username: 'jamiroquai', password: 'afunkodyssey' } })
    end
  end

  describe '#be_dir' do

    let(:dir) { File.join(platform_root, 'be_dir_test') }

    subject { platform.be_dir dir }

    it 'makes a directory' do
      should eq(dir)
      expect(File.directory?(dir)).to eq(true)
    end
  end

  describe '#be_file' do

    let(:path) do
      FileUtils.mkdir_p File.join(platform_root, 'be_file_test')
      File.join(platform_root, 'be_file_test', 'test_file.txt')
    end

    subject { platform.be_file path }

    it 'makes a file' do
      should eq(path)
      expect(File.file?(path)).to eq(true)
    end
  end
end
