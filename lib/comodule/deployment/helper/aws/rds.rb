module Comodule::Deployment::Helper::Aws::Rds

  def self.included(receiver)
    receiver.send :include, InstanceMethods
  end

  module InstanceMethods
    def rds
      @rds ||= ::Comodule::Deployment::Helper::Aws::Rds::Service.new(self)
    end
  end

  class Service
    include ::Comodule::Deployment::Helper::Aws::Base

    def db(db_instance_identifier)
      ::Comodule::Deployment::Helper::Aws::Rds::Db.new(owner, db_instance_identifier)
    end

    def latest_automated_snapshot
      if config.db && config.db.master && !config.db.snapshot_identifier
        config.db.snapshot_identifier = db(config.db.master).latest_automated_snapshot
      end
    end
  end

  class Db
    include ::Comodule::Deployment::Helper::Aws::Base

    attr_accessor :db

    def initialize(platform, db_instance_identifier)
      self.owner = platform
      self.db = aws.rds.db_instances[db_instance_identifier]
    end

    def latest_automated_snapshot
      snapshot =
        db.snapshots.with_type('automated').sort do |a, b|
          b.created_at <=> a.created_at
        end

      snapshot.first.db_snapshot_identifier
    end
  end
end
