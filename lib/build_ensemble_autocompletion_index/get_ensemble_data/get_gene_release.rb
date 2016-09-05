require 'net/http'
require 'uri'
require 'json'
require 'byebug' # FIXME

server = 'http://rest.ensembl.org'
path = '/info/data/?'

url = URI.parse(server)
http = Net::HTTP.new(url.host, url.port)

request = Net::HTTP::Get.new(path, {'Content-Type' => 'application/json'})

response = http.request(request)

if response.code != "200"
  puts "Invalid response: #{response.code}"
  puts response.body
  exit
end

result = JSON.parse(response.body)
result["releases"]