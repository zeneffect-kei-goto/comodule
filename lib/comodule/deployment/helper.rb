module Comodule::Deployment::Helper

  def self.included(receiver)
    receiver.send(
      :include,
      SystemUtility, ShellCommand, Uploader, Aws
    )
  end
end
