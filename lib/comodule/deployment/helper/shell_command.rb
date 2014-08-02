module Comodule::Deployment::Helper::ShellCommand

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

    `rm -rf #{crontab_tmp_dir}`
    be_dir crontab_tmp_dir

    paths.each do |path|
      next unless File.file?(path)

      if path =~ /\.erb$/
        path = render_in_tmp(path, crontab_tmp_dir)
      end

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

    `rm -rf #{shell_script_tmp_dir}`
    be_dir shell_script_tmp_dir
    paths.each do |file_path|
      next unless File.file?(file_path)

      if file_path =~ /\.erb$/
        file_path = render_in_tmp(file_path, shell_script_tmp_dir)
      end

      command_or_dummy "#{shell_path} #{file_path}"

      count += 1
    end

    count
  end
end
