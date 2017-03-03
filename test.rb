require 'net/http'
require 'uri'
require 'json'

def path_with_params(path, params)
   encoded_params = URI.encode_www_form(params)
   [path, encoded_params].join("?")
end

def request(url, body)
  # url = path_with_params(path, params)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(uri.request_uri, 'Content-Type' => 'application/json')
  request.basic_auth('diatex', ENV['DIATEX_PASSWORD'])
  request.body = body.to_json
  response = http.request(request)

  # Parse the response
  parsed = JSON.parse(response.body)
  if parsed['error']
    puts parsed['error']
    puts parsed['output']
    return nil
  else
    parsed['url']
  end
end

URL = "http://localhost:9292"

# body = """
# graph BT
#   subgraph Kubernetes
#     Node1((Node1))-->Cluster
#     Node2((Node2))-->Cluster
#     Node3((Node3))-->Cluster
#   end
#   subgraph Node
#     App-->Node3
#     MySQL-->Node3
#     Redis-->Node3
#     Nginx-->Node3
#   end
# Nginx---Internet
# """
# puts request("#{URL}/diatex/diagram", { diagram: body })

body = "J(w) = MSE_{train} + \lambda w^{T}w"
puts request("#{URL}/latex", { latex: body })