require 'snmp'
require_relative 'ext/octet_string'
require 'yaml'

class Snitch
  attr_accessor :client_list, :config

  def initialize
    @client_list = []
    @config = YAML.load_file("snitch.yml")
  end

  # Public: Get array of connected clients that match
  #         Side affect of updating the internal client list
  #
  # Examples
  #
  #   snitch = Snitch.new
  #   snitch.connected_clients.join(",")
  #
  # Returns array of connected clients.
  def connected_clients
    update_client_list
    client_list.map do |client|
      config[client]
    end.compact.uniq
  end

  private

  # Private: Update the list of clients on the router
  #
  # Resets internal client list
  def update_client_list
    client_list.clear
    begin
      # Open SNMP connection
      SNMP::Manager.open(host: config['router_name'], community: 'private') do |manager|
        list = manager.get_bulk(0, 10, '1.3.6.1.4.1.4526.100.7.8.8.1.1.1.24')
        list.varbind_list.map do |row|
          client_list << row.value.to_mac if row.value.is_a? SNMP::OctetString
        end
      end
    rescue SocketError => error
      client_list.clear
    rescue => error
      STDERR.puts "Unknown SNMP Error Caught\n#{error.inspect}"
    end
  end
end
