json.array!(@enhancers) do |enhancer|
  json.extract! enhancer, :id, :data
  json.url enhancer_url(enhancer, format: :json)
end
