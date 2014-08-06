module Comodule::Deployment::Helper::SystemUtility

  def render(path)
    ERB.new(File.read(path)).result(binding)
  end

  def render_in_path(from, to)
    File.open(to, 'w') do |file|
      if from =~ /\.erb$/
        file.write render(from)
      else
        file.write File.read(from)
      end
    end

    to
  end

  def render_in_dir(file_path, in_dir)
    dir, filename = File.split(file_path)

    path_in_dir = File.join(in_dir, filename.sub(/\.erb$/, ''))

    render_in_path file_path, path_in_dir
  end

  def yaml_to_config(path)
    ::Comodule::ConfigSupport::Config.new(
      YAML.load_file( path ) || {}
    )
  end

  def be_dir(*dir)
    if dir.size > 1
      return dir.map { |d| be_dir(d) }
    end

    dir = dir[0]
    FileUtils.mkdir_p dir unless File.directory?(dir)
    dir
  end

  def be_file(*path)
    if path.size > 1
      return path.map { |p| be_file(p) }
    end

    path = path[0]
    FileUtils.touch path if !File.directory?(path) && !File.file?(path)
    path
  end
end
