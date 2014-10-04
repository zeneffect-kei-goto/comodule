module Comodule::Deployment::Helper::Aws::Ssl

  def self.included(receiver)
    receiver.send :include, InstanceMethods
  end

  module InstanceMethods
    def ssl
      @ssl ||= ::Comodule::Deployment::Helper::Aws::Ssl::Service.new(self)
    end
  end

  class Service
    include ::Comodule::Deployment::Helper::Aws::Base

    def iam
      aws.iam
    end

    def describe
      puts
      iam.server_certificates.each do |cert|
        inspect_certificate cert
      end
    end

    def delete
      name = config.ssl.name
      cert = iam.server_certificates[name]
      puts "I am going to delete this server certificate #{name}. Are you sure? [N/y] "
      confirm = STDIN.gets
      unless confirm =~ /^y(es)?$/
        puts "\nAbort!\n"
        return
      end
      puts cert.delete
    end

    def upload
      body  = File.open(owner.file_path(config.ssl.dir, config.ssl.body_file)).read
      chain = File.open(owner.file_path(config.ssl.dir, config.ssl.chain_file)).read
      key   = File.open(owner.file_path(config.ssl.dir, config.ssl.key_file)).read
      puts "body:"
      puts body
      puts
      puts "chain:"
      puts chain
      puts
      puts "key"
      puts key
      puts
      puts "AWS IAM server certificate name: #{config.ssl.name}"
      puts "I am going to upload this server certificate to AWS IAM. Are you sure? [N/y] "
      confirm = STDIN.gets
      unless confirm =~ /^y(es)?$/
        puts "\nAbort!\n"
        return
      end

      cert = iam.server_certificates.create(
        certificate_body: body,
        name: config.ssl.name,
        path: config.ssl.path || ?/,
        private_key: key,
        certificate_chain: chain
      )

      unless cert
        'Failed!'
        return
      end

      puts
      puts "Success:"
      inspect_certificate cert
    end

    def inspect_certificate(cert)
      inspect_certificate_summary cert
      inspect_certificate_body cert
      inspect_certificate_chain cert
    end

    def inspect_certificate_summary(cert)
      puts "arn:         #{cert.arn}"
      puts "id:          #{cert.id}"
      puts "name:        #{cert.name}"
      puts "path:        #{cert.path}"
      puts "upload_date: #{cert.upload_date}"
      puts
    end

    def inspect_certificate_body(cert)
      puts "body:"
      puts cert.certificate_body
      puts
    end

    def inspect_certificate_chain(cert)
      puts "chain:"
      puts cert.certificate_chain
      puts
    end

    def find
      iam.server_certificates.find do |cert|
        cert.name == config.ssl.name
      end
    end
  end
end
