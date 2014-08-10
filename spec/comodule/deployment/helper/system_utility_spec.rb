require 'spec_helper'

describe Comodule::Deployment::Helper::SystemUtility do

  include_context 'deployment.platform'

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
      is_expected.to eq(sample_result)
    end
  end

  describe '#render_in_path' do
    let(:path) do
      FileUtils.mkdir_p File.join(platform_root, 'render_in_dir_test')
      File.join(platform_root, 'render_in_dir_test', 'database_config.yml')
    end

    subject { platform.render_in_path erb_path, path }

    it 'makes a file rendered erb in specify path' do
      is_expected.to eq(path)
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
      is_expected.to eq(result_path)
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
      is_expected.to eq({ production: { username: 'jamiroquai', password: 'afunkodyssey' } })
    end
  end

  describe 'about directory or file' do
    let(:dir) { File.join(platform_root, 'dir_test') }
    let(:dirs) do
      [
        File.join(platform_root, 'dir_test1'),
        File.join(platform_root, 'dir_test2'),
        File.join(platform_root, 'dir_test3')
      ]
    end

    describe '#rm_rf' do
      context 'given path outside of #platform_root' do
        it 'raises an error' do
          expect {
            platform.rm_rf "/test/tet/tett"
          }.to raise_error(ArgumentError)
        end
      end

      context 'given path inside of #platform_root' do
        context 'exists the directory' do
          subject { platform.rm_rf platform.tmp_dir }

          before do
            FileUtils.mkdir_p platform.tmp_dir
          end

          it 'execute rm -rf' do
            allow(platform).to receive(:`).with(
              "rm -rf #{platform.tmp_dir}"
            )
          end
        end

        context 'not exists the directory' do
          subject { platform.rm_rf platform.tmp_dir }

          before do
            `rm -rf #{platform.tmp_dir}`
          end

          it 'do nothing' do
            is_expected.to eq(nil)
          end
        end
      end
    end

    describe '#be_dir' do
      context 'given a path' do
        subject { platform.be_dir dir }

        it 'makes the directory' do
          is_expected.to eq(dir)
          expect(File.directory?(dir)).to eq(true)
        end
      end

      context 'given some paths' do
        subject { platform.be_dir *dirs }

        it 'makes those directories' do
          is_expected.to eq(dirs)
          dirs.each do |dir|
            expect(File.directory?(dir)).to eq(true)
          end
        end
      end
    end

    describe '#re_dir' do
      context 'given a directory' do
        let(:sample_file) { File.join(dir, 'sample.txt') }

        subject { platform.re_dir dir}

        before do
          FileUtils.mkdir_p dir
          `touch #{sample_file}`
        end

        it 'remakes the directory' do
          expect(File.directory?(dir)).to eq(true)
          expect(File.file?(sample_file)).to eq(true)
          is_expected.to eq(dir)
          expect(File.directory?(dir)).to eq(true)
          expect(File.file?(sample_file)).to eq(false)
        end
      end

      context 'given some directories' do
        let(:sample_files) do
          dirs.map { |d| File.join(d, 'sample.txt')}
        end

        subject { platform.re_dir dirs }

        before do
          sample_files.each do |path|
            FileUtils.mkdir_p File.dirname(path)
            `touch #{path}`
          end
        end

        it 'remakes those directories' do
          sample_files.each do |path|
            expect(File.directory?(File.dirname(path))).to eq(true)
            expect(File.file?(path)).to eq(true)
          end
          is_expected.to eq(dirs)
          sample_files.each do |path|
            expect(File.directory?(File.dirname(path))).to eq(true)
            expect(File.file?(path)).to eq(false)
          end
        end
      end
    end

    describe '#be_file' do
      context 'given a filepath' do
        let(:path) do
          FileUtils.mkdir_p dir
          File.join(dir, 'test_file.txt')
        end

        subject { platform.be_file path }

        it 'makes the file' do
          is_expected.to eq(path)
          expect(File.file?(path)).to eq(true)
        end
      end

      context 'given some filepaths' do
        let(:paths) do
          (1..3).map do |n|
            FileUtils.mkdir_p dir
            File.join(dir, "test_file#{n}.txt")
          end
        end

        subject { platform.be_file paths }

        it 'makes those files' do
          is_expected.to eq(paths)
          paths.each do |path|
            expect(File.file?(path)).to eq(true)
          end
        end
      end
    end
  end
end
