require 'spec_helper'

describe Comodule::Deployment::Platform do

  include_context 'deployment.platform'

  describe '#test_mode' do
    it 'chenge mode into test on block' do
      platform.env = :production
      expect(platform.test?).to eq(false)
      platform.test_mode do
        expect(platform.test?).to eq(true)
      end
      expect(platform.test?).to eq(false)
    end
  end

  describe '#create' do

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

  describe '#name' do
    subject { platform.name }

    it { is_expected.to eq(platform_name) }
  end

  describe '#project_root' do
    subject { platform.project_root }

    it { is_expected.to eq(project_root) }
  end

  describe '#platform_root' do
    subject { platform.platform_root }

    it 'equals #project_root/platform' do
      is_expected.to eq(File.join(platform.project_root, 'platform'))
    end
  end

  describe '#platform_dir' do
    subject { platform.platform_dir }

    it "equals #platform_root/experiment" do
      is_expected.to eq(File.join(platform.platform_root, platform_name))
    end
  end

  describe '#aws_config_path' do
    subject { platform.aws_config_path }

    it 'equals #platform_root/aws_config.yml' do
      is_expected.to eq(File.join(platform.platform_root, 'aws_config.yml'))
    end
  end

  describe '#config_dir' do
    subject { platform.config_dir }

    it 'equals #platform_dir/config' do
      is_expected.to eq(File.join(platform_dir, 'config'))
    end
  end

  describe '#secret_config_dir' do
    subject { platform.secret_config_dir }

    it 'equals #platform_dir/secret_config' do
      is_expected.to eq(File.join(platform.platform_dir, 'secret_config'))
    end
  end

  describe '#common_config_dir' do
    subject { platform.common_config_dir }

    it 'equals #platform_root/config' do
      is_expected.to eq(File.join(platform.platform_root, 'config'))
    end
  end

  describe '#common_secret_config_dir' do
    subject { platform.common_secret_config_dir }

    it 'equals #platform_root/secret_config' do
      is_expected.to eq(File.join(platform_root, 'secret_config'))
    end
  end

  describe '#common_config_path' do
    subject { platform.common_config_path }

    it 'equals #platform_root/config.yml' do
      is_expected.to eq(File.join(platform_root, 'config.yml'))
    end
  end

  describe '#common_secret_config_path' do
    subject { platform.common_secret_config_path }

    it 'equals #platform_root/secret_config' do
      is_expected.to eq(File.join(platform_root, 'secret_config.yml'))
    end
  end

  describe '#config_path' do
    subject { platform.config_path }

    it 'equals #platform_dir/config.yml' do
      is_expected.to eq(File.join(platform_dir, 'config.yml'))
    end
  end

  describe '#secret_config_path' do
    subject { platform. secret_config_path }

    it 'equals #platform_dir/secret_config.yml' do
      is_expected.to eq(File.join(platform_dir, 'secret_config.yml'))
    end
  end

  describe '#git_dir' do
    subject { platform.git_dir }

    it 'equals #project_root/.git' do
      is_expected.to eq(File.join(platform.project_root, '.git'))
    end
  end

  describe '#tmp_dir' do
    subject { platform.tmp_dir }

    it 'equals #platform_dir/tmp' do
      is_expected.to eq(File.join(platform.platform_dir, 'tmp'))
    end
  end

  describe '#test_dir' do
    subject { platform.test_dir }

    it 'equals #platform_dir/tmp' do
      is_expected.to eq(File.join(platform.platform_dir, 'test'))
    end
  end

  describe '#project_name' do
    subject { platform.project_name }

    it { is_expected.to eq('test') }
  end

  describe '#tmp_projects_dir' do
    subject { platform.tmp_projects_dir }

    it 'equals #tmp_dir/projects' do
      is_expected.to eq(File.join(platform.tmp_dir, 'projects'))
    end
  end

  describe '#tmp_project_dir' do
    subject { platform.tmp_project_dir }

    it 'equals #tmp_projects_dir/#project_name' do
      is_expected.to eq(File.join(platform.tmp_projects_dir, platform.project_name))
    end
  end

  describe '#file_path' do
    context 'argument =~ /^platform/' do
      subject { platform.file_path 'platform/config/etc' }

      it 'relative path from #platform_root' do
        is_expected.to eq(File.join(platform.platform_root, 'config', 'etc'))
      end
    end

    context 'argument !~ /^platform/' do
      subject { platform.file_path '/config/etc' }

      it 'relative path from #platform_dir' do
        is_expected.to eq(File.join(platform.platform_dir, 'config', 'etc'))
      end
    end
  end

  describe '#common_crontab_dir' do
    subject { platform.common_crontab_dir }

    it 'equals #common_config_dir/crontab' do
      is_expected.to eq(File.join(platform.common_config_dir, 'crontab'))
    end
  end

  describe '#crontab_dir' do
    subject { platform.crontab_dir }

    it 'equals #config_dir/crontab' do
      is_expected.to eq(File.join(platform.config_dir, 'crontab'))
    end
  end

  describe '#secret_crontab_dir' do
    subject { platform.secret_crontab_dir }

    it 'equals #secret_config_dir/crontab' do
      is_expected.to eq(File.join(platform.secret_config_dir, 'crontab'))
    end
  end

  describe '#tmp_crontab_dir' do
    subject { platform.tmp_crontab_dir }

    it 'equals #tmp_dir/crontab' do
      is_expected.to eq(File.join(platform.tmp_dir, 'crontab'))
    end
  end

  describe '#common_shell_script_dir' do
    subject { platform.common_shell_script_dir }

    it 'equals #common_config_dir/shell_script' do
      is_expected.to eq(File.join(platform.common_config_dir, 'shell_script'))
    end
  end

  describe '#shell_script_dir' do
    subject { platform.shell_script_dir }

    it 'equals #config_dir/shell_script' do
      is_expected.to eq(File.join(platform.config_dir, 'shell_script'))
    end
  end

  describe '#secret_shell_script_dir' do
    subject { platform.secret_shell_script_dir }

    it 'equals #secret_config_dir/shell_script' do
      is_expected.to eq(File.join(platform.secret_config_dir, 'shell_script'))
    end
  end

  describe '#tmp_shell_script_dir' do
    subject { platform.tmp_shell_script_dir }

    it 'equals #tmp_dir/shell_script' do
      is_expected.to eq(File.join(platform.tmp_dir, 'shell_script'))
    end
  end

  describe '#cloud_formation_dir' do
    subject { platform.cloud_formation_dir }

    it 'equals #platform_dir/cloud_formation' do
      is_expected.to eq(File.join(platform_dir, 'cloud_formation'))
    end
  end

  describe '#common_cloud_formation_dir' do
    subject { platform.common_cloud_formation_dir }

    it 'equals #platform_root/cloud_formation' do
      is_expected.to eq(File.join(platform.platform_root, 'cloud_formation'))
    end
  end

  describe '#test_cloud_formation_dir' do
    subject { platform.test_cloud_formation_dir }

    it 'equals #test_dir/cloud_formation' do
      is_expected.to eq(File.join(platform.test_dir, 'cloud_formation'))
    end
  end
end
