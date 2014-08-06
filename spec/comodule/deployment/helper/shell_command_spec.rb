require 'spec_helper'

describe Comodule::Deployment::Helper::ShellCommand do

  include_context 'deployment.platform'
  include_context 'deployment.helper.shell_command'

  before do
    platform.create
  end

  let(:test_command) { 'ls -la' }

  describe '#dummy' do
    subject { platform.dummy :`, test_command }

    it 'return message to STDOUT' do
      expect(platform).to receive(:puts).with(
        "execute dummy method: `, args: #{[test_command]}"
      )
      subject
    end
  end

  describe '#command_or_dummy' do
    subject { platform.command_or_dummy test_command }

    context 'not #deployment?' do
      it 'return message to STDOUT' do
        expect(platform).to receive(:puts).with(
          "execute dummy method: `, args: #{[test_command]}"
        )
        subject
      end
    end

    context '#deployment?' do
      before do
        platform.env = :staging
      end

      it 'execute shell command' do
        expect(platform).to receive(:`).with(test_command)
        subject
      end
    end
  end

  describe '#chown' do
    subject { platform.chown }

    context 'config.chown' do
      context 'has a command' do
        before do
          platform.config.chown = test_command
        end

        it '#command_or_dummy receives the command' do
          expect(platform).to receive(:command_or_dummy).with(
            "chown #{test_command}"
          )
          subject
        end
      end

      context 'has some commands' do
        let(:commands) do
          [
            'ec2-user:ec2-user /home/ec2-user/projects',
            'ec2-user:ec2-user /etc/nginx/nginx.conf',
            'ec2-user:ec2-user /home/ec2-user/db-backup'
          ]
        end

        before do
          platform.config.chown = commands
        end

        it '#command_or_dummy receives those commands' do
          commands.each do |cmd|
            expect(platform).to receive(:command_or_dummy).with("chown #{cmd}")
          end
          subject
        end
      end
    end
  end

  describe '#crontab' do
    subject { platform.crontab }

    context 'exists a file' do
      context 'in #common_crontab_dir' do
        before do
          be_crontab_files :common_crontab_dir, ['batch.rb']
        end

        it_behaves_like 'crontab messages', ['batch.rb']
      end

      context 'in #crontab_dir' do
        before do
          be_crontab_files :crontab_dir, ['batch.rb']
        end

        it_behaves_like 'crontab messages', ['batch.rb']
      end

      context 'in #secret_crontab_dir' do
        before do
          be_crontab_files :secret_crontab_dir, ['batch.rb']
        end

        it_behaves_like 'crontab messages', ['batch.rb']
      end
    end

    context 'exists some files' do
      commands1 = ['batch.rb', 'batch-2.rb', 'batch-3.rb']
      commands2 = ['script.rb', 'script-2.rb', 'script-3.rb']
      commands3 = ['exec.rb', 'exec-2.rb', 'exec-3.rb']

      before do
        be_crontab_files :common_crontab_dir, commands1
        be_crontab_files :crontab_dir, commands2
        be_crontab_files :secret_crontab_dir, commands3
      end

      it_behaves_like 'crontab messages', commands1 + commands2 + commands3
    end
  end

  describe '#shell_script' do
    subject { platform.shell_script }

    context 'exists a file' do
      context 'in #common_shell_script_dir' do
        before do
          be_shell_script_files :common_shell_script_dir, ['script.rb']
        end

        it_behaves_like 'shell script messages', ['script.rb']
      end

      context 'in #shell_script_dir' do
        before do
          be_shell_script_files :shell_script_dir, ['script.rb']
        end

        it_behaves_like 'shell script messages', ['script.rb']
      end

      context 'in #secret_shell_script_dir' do
        before do
          be_shell_script_files :secret_shell_script_dir, ['script.rb']
        end

        it_behaves_like 'shell script messages', ['script.rb']
      end
    end

    context 'exists some files' do
      scripts1 = ['scripts1-1.rb', 'scripts1-2.rb', 'scripts1-3.rb']
      scripts2 = ['scripts2-1.rb', 'scripts2-2.rb', 'scripts2-3.rb']
      scripts3 = ['scripts3-1.rb', 'scripts3-2.rb', 'scripts3-3.rb']

      before do
        be_shell_script_files :common_shell_script_dir, scripts1
        be_shell_script_files :shell_script_dir, scripts2
        be_shell_script_files :secret_shell_script_dir, scripts3
      end

      it_behaves_like 'shell script messages', scripts1 + scripts2 + scripts3
    end
  end
end
