import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.http.HttpMethod;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

public class MetadataRoutingFilter implements GatewayFilter {

    private final String onPremUrl;
    private final String cloudUrl;
    private final String metadataPropertyToMatch;

    public MetadataRoutingFilter(String onPremUrl, String cloudUrl, String metadataPropertyToMatch) {
        this.onPremUrl = onPremUrl;
        this.cloudUrl = cloudUrl;
        this.metadataPropertyToMatch = metadataPropertyToMatch;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        // Extract the payload from the request (assuming it's JSON and we can extract metadata)
        return exchange.getRequest().getBody()
                .reduce((acc, item) -> acc) // Combine chunks into a single buffer
                .flatMap(buffer -> {
                    String payload = buffer.toString(StandardCharsets.UTF_8);
                    // Assuming you are using Jackson or another library to parse the JSON payload
                    try {
                        Map<String, Object> metadata = parseMetadata(payload);
                        if (MetadataMatcher.matchMetadata(metadata, metadataPropertyToMatch)) {
                            // Route to cloud if matched
                            exchange.getRequest().mutate().uri(URI.create(cloudUrl)).build();
                        } else {
                            // Route to on-prem if not matched
                            exchange.getRequest().mutate().uri(URI.create(onPremUrl)).build();
                        }
                    } catch (Exception e) {
                        // Handle any parsing errors
                        e.printStackTrace();
                    }
                    return chain.filter(exchange);
                });
    }

    // Helper method to parse the metadata from the payload (simplified here)
    private Map<String, Object> parseMetadata(String payload) throws JsonProcessingException {
        ObjectMapper objectMapper = new ObjectMapper();
        JsonNode rootNode = objectMapper.readTree(payload);
        return objectMapper.convertValue(rootNode.get("metadata"), Map.class);
    }
}
