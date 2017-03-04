require 'net/http'
require 'uri'
require 'json'

def request(url, body)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.port == 443)
  request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
  request.basic_auth('diatex', ENV['DIATEX_PASSWORD'])
  request.basic_auth('diatex', "hi")
  # request.body = body.to_json
  request.form_data = body
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

URL = "http://localhost:32768"

body = """
graph BT
  subgraph Kubernetes
    Node1((Node1))-->Cluster
    Node2((Node2))-->Cluster
    Node3((Node3))-->Cluster
  end
  subgraph Node
    App-->Node3
    MySQL-->Node3
    Redis-->Node3
    Nginx-->Node3
  end
  Nginx---Internet
"""
puts request("#{URL}/diagram", { diagram: body })

body = "J(w) = MSE_{train} + \lambda w^{T}w+w^2"
puts request("#{URL}/latex", { latex: body })