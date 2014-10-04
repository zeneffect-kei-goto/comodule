require 'spec_helper'

shared_context 'deployment.helper.uploader' do

  shared_examples 'has default secret_files' do
    it 'has default secret_files' do
      is_expected.to include(common_secret_config)
      is_expected.to include(secret_config)
    end
  end

  shared_context 'exists #git_dir' do
    before do
      dir = platform.project_root
      `cd #{dir}; git init`
      `cd #{dir}; touch sample.txt`
      `cd #{dir}; git add -A`
      `cd #{dir}; git commit -m "first commit"`
    end
  end
end
