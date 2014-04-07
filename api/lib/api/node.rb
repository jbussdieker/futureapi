require 'json'
require 'net/http'

module Api
  module Client
    def Client.included cls
      cls.extend Client
    end

    def attributes(*attrs)
      if attrs.length > 0
        @@_attrs = attrs
        attr_accessor *attrs
      else
        @@_attrs
      end
    end

    def root_path(setting = nil)
      if setting == nil
        @root_path
      else
        @root_path = setting
      end
    end

    def client
      Net::HTTP.new("localhost", 3000)
    end

    def new_request(method, url)
      req = Net::HTTP.const_get(method.capitalize).new(url)
      req["Content-Type"] = "application/json"
      req["Accept"] = "application/json"
      req
    end

    def issue_request(method, url)
      req = new_request(method, url)
      resp = client.request(req)

      if resp.kind_of? Net::HTTPSuccess
        if resp.body.nil?
          nil
        else
          JSON.parse(resp.body)
        end
      elsif resp.kind_of? Net::HTTPRedirect
        raise "Redirect?"
      else
        raise "Error?"
      end
    end
  end

  class Node
    include Client

    root_path "/nodes"
    attributes :url, :name, :id, :created_at, :updated_at

    def initialize(params = {})
      params.each do |k, v|
        send("#{k}=", v)
      end
    end

    def delete
      issue_request(:delete, url)
    end

    def save
      req = new_request(:put, url)
      params = {}
      attributes.each do |k|
        params[k] = send("#{k}")
      end
      req.body = { node: params }.to_json
      client.request(req)
    end

    def self.all
      nodes = issue_request(:get, root_path)
      nodes.collect { |n| new(n) }
    end

    def self.create(params)
      req = new_request(:post, root_path)
      req.body = params.to_json
      resp = client.request(req)
      if resp.kind_of? Net::HTTPSuccess
        location = resp["Location"]
        node = issue_request(:get, location)
        new(node.merge(url: location))
      else
        raise "Error creating"
      end
    end
  end
end
