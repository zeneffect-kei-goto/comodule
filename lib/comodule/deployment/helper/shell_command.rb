module Comodule::Deployment::Helper::ShellCommand

  def command_or_dummy(cmd)
    if deployment?
      `#{cmd}`
    else
      dummy :`, cmd
    end
  end

  def dummy(method_name, *args)
    puts "execute dummy method: #{method_name}, args: #{args}"
  end

  def chown
    return unless config.chown

    [config.chown].flatten.each do |arg|
      command_or_dummy "chown #{arg}"
    end
  end

  def crontab
    count = 0

    paths  = Dir.glob(File.join(common_crontab_dir, '**', '*'))
    paths += Dir.glob(File.join(crontab_dir, '**', '*'))
    paths += Dir.glob(File.join(secret_crontab_dir, '**', '*'))

    rm_rf tmp_crontab_dir
    be_dir tmp_crontab_dir

    paths.each do |path|
      next unless File.file?(path)

      path = render_in_dir(path, tmp_crontab_dir)

      cmd = "crontab #{path}"
      puts "set crontab:\n  #{cmd}"

      command_or_dummy cmd

      count += 1
    end

    count
  end

  def shell_script
    count = 0

    paths  = Dir.glob(File.join(common_shell_script_dir, '**', '*'))
    paths += Dir.glob(File.join(shell_script_dir, '**', '*'))
    paths += Dir.glob(File.join(secret_shell_script_dir, '**', '*'))

    shell_path = config.shell || '/bin/bash'

    rm_rf tmp_shell_script_dir
    be_dir tmp_shell_script_dir

    paths.each do |path|
      next unless File.file?(path)

      path = render_in_dir(path, tmp_shell_script_dir)

      cmd = "#{shell_path} #{path}"
      puts "execute shell script:\n  #{cmd}"

      command_or_dummy "#{shell_path} #{path}"

      count += 1
    end

    count
  end
end
