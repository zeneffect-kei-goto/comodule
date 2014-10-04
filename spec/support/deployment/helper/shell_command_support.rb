require 'spec_helper'

shared_context 'deployment.helper.shell_command' do

  shared_examples 'crontab messages' do |names|
    it '#command_or_dummy receives crontab messages' do
      names.each do |name|
        cmd = "crontab #{File.join(platform.tmp_crontab_dir, name)}"
        expect(platform).to receive(:command_or_dummy).with(cmd)
        expect(platform).to receive(:puts).with("set crontab:\n  #{cmd}")
      end
      is_expected.to eq(names.size)
    end
  end

  shared_examples 'shell script messages' do |names|
    it '#command_or_dummy receive shell script messages' do
      names.each do |name|
        cmd = "/bin/bash #{File.join(platform.tmp_shell_script_dir, name)}"
        expect(platform).to receive(:command_or_dummy).with(cmd)
        expect(platform).to receive(:puts).with("execute shell script:\n  #{cmd}")
      end
      is_expected.to eq(names.size)
    end
  end

  def be_crontab_files(dir_getter, names)
    be_files dir_getter, names, "1 0 1 * * /bin/bash ls -la\n"
  end

  def be_shell_script_files(dir_getter, names)
    be_files dir_getter, names, "/bin/bash\nls -la\n"
  end
end
