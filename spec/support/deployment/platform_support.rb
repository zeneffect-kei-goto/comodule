require 'spec_helper'

shared_context 'deployment.platform' do

  let(:project_root) { File.expand_path '../platform/test', __FILE__ }
  let(:platform_root) { File.join(project_root, 'platform') }
  let(:platform_name) { 'experiment' }
  let(:platform_dir) { File.join(platform_root, platform_name) }
  let(:platform) do
    Comodule::Deployment::Platform.new(
      platform_name, project_root: project_root
    )
  end

  after do
    `rm -rf #{project_root}`
  end

  def be_dir(dir_getter)
    FileUtils.mkdir_p platform.send(dir_getter)
  end

  def be_files(dir_getter, names, contents = "")
    names.each do |name|
      path = File.join(platform.send(dir_getter), name)
      FileUtils.mkdir_p File.dirname(path)
      File.open(path, 'w') do |file|
        file.write contents
      end
    end
  end
end
