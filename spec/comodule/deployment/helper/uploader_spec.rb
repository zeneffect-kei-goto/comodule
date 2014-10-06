require 'spec_helper'

describe Comodule::Deployment::Helper::Uploader do
  include_context 'deployment.platform'
  include_context 'deployment.helper.uploader'

  before do
    platform.create
  end

  describe '#secret_files' do
    let(:common_secret_config) do
      File.join(platform.platform_root, 'secret_config.yml')
    end
    let(:secret_config) do
      File.join(platform.platform_dir, 'secret_config.yml')
    end

    context 'exists a file' do
      subject { platform.secret_files }

      context 'in #common_secret_config_dir' do
        before do
          be_files :common_secret_config_dir, ['rails/config/database.yml']
        end

        it_behaves_like 'has default secret_files'

        it 'has the file' do
          is_expected.to include(
            File.join(platform.common_secret_config_dir, 'rails', 'config', 'database.yml')
          )
          expect(subject.size).to eq(3)
        end
      end

      context 'in #secret_config_dir' do
        before do
          be_files :secret_config_dir, ['rails/config/database.yml']
        end

        it_behaves_like 'has default secret_files'

        it 'has the file' do
          is_expected.to include(
            File.join(platform.secret_config_dir, 'rails', 'config', 'database.yml')
          )
        end
      end
    end

    context 'exists some files' do
      let(:files) do
        ['rails/config/database.yml', 'etc/nginx/ssl.pem']
      end

      subject { platform.secret_files }

      context 'in #common_secret_config_dir' do
        before do
          be_files :common_secret_config_dir, files
        end

        it 'has the files' do
          files.each do |file|
            is_expected.to include(File.join(platform.common_secret_config_dir, file))
          end
        end
      end

      context 'in $secret_config_dir' do
        before do
          be_files :secret_config_dir, files
        end

        it 'has the files' do
          files.each do |file|
            is_expected.to include(File.join(platform.secret_config_dir, file))
          end
        end
      end

      context 'in $common_secret_config_dir and $secret_config_dir' do
        before do
          be_files :common_secret_config_dir, files
          be_files :secret_config_dir, files
        end

        it 'has the files' do
          files.each do |file|
            is_expected.to include(File.join(platform.common_secret_config_dir, file))
          end
          files.each do |file|
            is_expected.to include(File.join(platform.secret_config_dir, file))
          end
        end
      end
    end
  end

  describe '#upload_secret_files' do
    let(:common_secret_config) do
      File.join(platform.platform_root, 'secret_config.yml')
    end
    let(:secret_config) do
      File.join(platform.platform_dir, 'secret_config.yml')
    end

    subject { platform.upload_secret_files }

    context '#config.upload_secret_files != true' do
      it 'do nothing' do
        expect(platform.s3).not_to receive(:bucket)
        is_expected.to eq(nil)
      end
    end

    context '#config.upload_secret_files == true' do
      let(:test_dir_common) { "#{platform.test_upload_secret_files_dir}/#{platform.name}/platform" }
      let(:test_dir) { "#{platform.test_upload_secret_files_dir}/#{platform.name}/platform/#{platform.name}" }

      before do
        platform.config.upload_secret_files = true
      end

      context 'and not #deployment?' do
        before do
          platform.env = :test
        end

        it "makes the secret files copy in test directory" do
          expect(platform).to receive(:re_dir)
          expect(platform).to receive(:be_dir).with(test_dir_common)
          expect(platform).to receive(:be_dir).with(test_dir)

          expect(FileUtils).to receive(:cp).with(common_secret_config, test_dir_common)
          expect(FileUtils).to receive(:cp).with(secret_config, test_dir)

          expect(platform.s3).not_to receive(:bucket)

          is_expected.to eq(platform.secret_files)
        end
      end

      context 'and #deployment?' do
        before do
          platform.env = :staging
        end

        it "copies the secret files to S3" do
          expect(platform).to receive(:re_dir)
          expect(platform).to receive(:be_dir).with(test_dir_common)
          expect(platform).to receive(:be_dir).with(test_dir)

          expect(FileUtils).to receive(:cp).with(common_secret_config, test_dir_common)
          expect(FileUtils).to receive(:cp).with(secret_config, test_dir)

          s3_obj_common = double('s3_obj_common')
          s3_obj = double('s3_obj')

          expect(s3_obj_common).to receive(:write).with(
            Pathname.new(common_secret_config), server_side_encryption: :aes256
          )
          expect(s3_obj).to receive(:write).with(
            Pathname.new(secret_config), server_side_encryption: :aes256
          )

          allow(platform.s3).to receive_message_chain(
            'bucket.objects.[]'
          ).with(
            "#{platform.name}/platform/secret_config.yml"
          ).and_return(s3_obj_common)

          allow(platform.s3).to receive_message_chain(
            'bucket.objects.[]'
          ).with(
            "#{platform.name}/platform/#{platform.name}/secret_config.yml"
          ).and_return(s3_obj)

          is_expected.to eq(platform.secret_files)
        end
      end
    end
  end

  describe '#tmp_archives_dir' do
    subject { platform.tmp_archives_dir }

    it 'equals #tmp_dir/archives' do
      is_expected.to eq(File.join(platform.tmp_dir, 'archives'))
    end
  end

  describe '#archive_filename' do
    subject { platform.archive_filename }

    it do
      "#{platform.project_name}-#{platform.config.platform_name}.tar.gz"
    end
  end

  describe '#archive_path' do
    subject { platform.archive_path }

    it do
      is_expected.to eq(
        File.join(platform.tmp_archives_dir, platform.archive_filename)
      )
    end
  end

  describe '#archive_s3_path' do
    subject { platform.archive_s3_path }

    it do
      is_expected.to eq(
        platform.archive_path.sub(%r|^#{platform.tmp_dir}/|, '')
      )
    end
  end

  describe '#archive_project' do
    subject { platform.archive_project }

    context 'not exists #git_dir' do
      it 'do nothing' do
        expect(platform).to receive(:puts).with('.git not found')
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'not #config.upload_project == "without_git"' do
      include_context 'exists #git_dir'

      it 'project with .git' do
        is_expected.to eq(platform.archive_path)
        expect(
          File.file?(File.join(platform.tmp_project_dir, 'project_stamp.txt'))
        ).to eq(true)
        expect(
          File.file?(File.join(platform.archive_path))
        ).to eq(true)
        expect(
          File.directory?(File.join(platform.tmp_project_dir, '.git'))
        ).to eq(true)
      end
    end

    context '#config.upload_project == "without_git' do
      include_context 'exists #git_dir'

      before do
        platform.config.upload_project = 'without_git'
      end

      it 'project without .git' do
        is_expected.to eq(platform.archive_path)
        expect(
          File.file?(File.join(platform.tmp_project_dir, 'project_stamp.txt'))
        ).to eq(true)
        expect(
          File.file?(platform.archive_path)
        ).to eq(true)
        expect(
          File.directory?(File.join(platform.tmp_project_dir, '.git'))
        ).to eq(false)
      end
    end
  end

  describe '#download_project' do
    include_context 'exists #git_dir'

    subject { platform.download_project }

    before do
      platform.archive_project
    end

    it 'download tar ball' do
      allow(platform).to receive_message_chain('s3.bucket.objects.[].read') do
        File.open(platform.archive_path).read
      end

      local_dir = File.join(platform.test_dir, 'download_archive')

      is_expected.to eq(
        File.join(
          local_dir,
          File.basename(platform.archive_path)
        )
      )
      expect(File.file?(subject)).to eq(true)
      expect(
        File.file?(File.join(local_dir, 'project_stamp.txt'))
      ).to eq(true)
    end
  end
end
