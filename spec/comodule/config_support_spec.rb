require 'spec_helper'

describe Comodule::ConfigSupport do
  describe '::Config' do
    context '#[], #[]=' do
      it 'like Hash' do
        config = Comodule::ConfigSupport::Config.new
        config[:host] = 'example.com'
        config[:port] = '3000'

        expect(config[:host]).to eq('example.com')
        expect(config[:port]).to eq('3000')

        config[:db] = {
          host: 'rds',
          database: 'app_development',
          password: 'secret'
        }

        expect(config[:db][:host]).to eq('rds')
        expect(config[:db][:database]).to eq('app_development')
        expect(config[:db][:password]).to eq('secret')

        expect(config.db.host).to eq('rds')
        expect(config.db.database).to eq('app_development')
        expect(config.db.password).to eq('secret')
      end
    end

    context '#to_hash' do
      it 'not include :cofigure_type' do
        config = Comodule::ConfigSupport::Config.new(
          configure_type: :hard,
          host: 'example.com',
          port: '3000',
          ip: '10.0.0.100'
        )
        expect(config.to_hash).to eq({
          host: 'example.com',
          port: '3000',
          ip: '10.0.0.100'
        })
      end
    end

    context '.new' do
      it 'can specify each other configure_type to recursive object' do
        config = Comodule::ConfigSupport::Config.new(
          configure_type: :hard,
          host: 'example.com',
          port: '3000',
          db: {
            host: 'rds',
            database: 'app_development',
            username: 'ec2-user',
            password: 'secret'
          }
        )
        expect(config.configure_type).to eq(:hard)
        expect(config.db.configure_type).to eq(:hard)

        config.current_user = {
          role: 'admin',
          dept: 'sales'
        }

        expect(config.current_user.configure_type).to eq(:hard)

        config.current_user = {
          configure_type: :soft,
          role: 'admin',
          dept: 'sales'
        }
        expect(config.configure_type).to eq(:hard)
        expect(config.db.configure_type).to eq(:hard)
        expect(config.current_user.configure_type).to eq(:soft)
      end

      it 'return recursive object when argument include Hash' do
        config = Comodule::ConfigSupport::Config.new(
          host: 'example.com',
          port: '3000',
          db: {
            host: 'rds',
            database: 'app_development',
            username: 'ec2-user',
            password: 'secret',
            instance: {
              type: 't1.micro',
              multi_az: false
            }
          }
        )
        expect(config.db.host).to eq('rds')
        expect(config.db.database).to eq('app_development')
        expect(config.db.username).to eq('ec2-user')
        expect(config.db.password).to eq('secret')
        expect(config.db.instance.type).to eq('t1.micro')
        expect(config.db.instance.multi_az).to eq(false)

        config = Comodule::ConfigSupport::Config.new(
          host: 'example.com',
          port: '3000'
        )
        config.db = {
          host: 'rds',
          database: 'app_development',
          username: 'ec2-user',
          password: 'secret'
        }
        expect(config.db.host).to eq('rds')
        expect(config.db.database).to eq('app_development')
        expect(config.db.username).to eq('ec2-user')
        expect(config.db.password).to eq('secret')
      end

      it 'useful configure object' do
        config = Comodule::ConfigSupport::Config.new(
          host: 'example.com',
          port: '3000',
          ip: '10.0.0.100'
        )
        expect(config.host).to eq('example.com')
        expect(config.port).to eq('3000')
        expect(config.ip).to eq('10.0.0.100')
      end

      it 'return nil when access undefined attribute at default' do
        config = Comodule::ConfigSupport::Config.new(
          host: 'example.com',
          port: '3000',
          ip: '10.0.0.100'
        )
        expect(config.nothing).to eq(nil)
      end

      it 'raises error when access undefined attribute at the configure_type is :hard' do
        config = Comodule::ConfigSupport::Config.new(
          configure_type: :hard,
          host: 'example.com',
          port: '3000',
          ip: '10.0.0.100'
        )
        expect{config.nothing}.to raise_error(ArgumentError)
      end
    end
  end



  context '#create_config' do
    before do
      stub_const("SomeClass", Class.new)
      SomeClass.send :include, Comodule::ConfigSupport
    end

    it 'class configure' do
      class SomeClass
        Configure = create_config(
          max_record_size: 3000,
          update_index: 'some_class-20140325'
        )
      end
      expect(SomeClass::Configure.max_record_size).to eq(3000)
      expect(SomeClass::Configure.update_index).to eq('some_class-20140325')
    end
  end
end
