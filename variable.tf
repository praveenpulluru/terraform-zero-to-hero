org.springframework.http.server.reactive.ServerHttpRequest
The method getMultipartData() is undefined for the type ServerHttpRequest
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.http.HttpMethod;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.util.MultiValueMap;
import org.springframework.web.multipart.MultipartFile;
import reactor.core.publisher.Mono;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import java.io.IOException;

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
        // Check if the request is multipart and contains metadata
        if (exchange.getRequest().getHeaders().getContentType().includes(MediaType.MULTIPART_FORM_DATA)) {
            return exchange.getRequest().getBody()
                    .reduce((acc, item) -> acc) // Combine chunks into a single buffer
                    .flatMap(buffer -> {
                        // Now, we need to extract the form fields (metadata)
                        return exchange.getRequest().getMultipartData().flatMap(multipartData -> {
                            // Extract metadata field (assuming metadata is sent as JSON string)
                            String metadataJson = multipartData.getFirst("metadata") != null ? multipartData.getFirst("metadata").toString() : "";
                            if (!metadataJson.isEmpty()) {
                                try {
                                    // Parse the metadata
                                    Map<String, Object> metadata = parseMetadata(metadataJson);
                                    
                                    // Match the metadata based on a property (e.g., documentType)
                                    if (MetadataMatcher.matchMetadata(metadata, metadataPropertyToMatch)) {
                                        // Route to cloud if metadata matches
                                        exchange.getRequest().mutate().uri(URI.create(cloudUrl)).build();
                                    } else {
                                        // Route to on-prem if metadata does not match
                                        exchange.getRequest().mutate().uri(URI.create(onPremUrl)).build();
                                    }
                                } catch (IOException e) {
                                    // Handle parsing errors
                                    e.printStackTrace();
                                }
                            }
                            return chain.filter(exchange);
                        });
                    });
        }
        return chain.filter(exchange); // Continue if not a multipart form
    }

    // Helper method to parse the JSON metadata string
    private Map<String, Object> parseMetadata(String metadataJson) throws IOException {
        ObjectMapper objectMapper = new ObjectMapper();
        JsonNode jsonNode = objectMapper.readTree(metadataJson);
        return objectMapper.convertValue(jsonNode, Map.class);
    }
}



@Configuration
public class GatewayRoutesConfig {

    @Value("${services.on-prem-url}")
    private String onPremUrl;

    @Value("${services.cloud-url}")
    private String cloudUrl;

    private static final String on_prem = "on-prem";
    private static final String cloud = "cloud";

    @Value("${metadata.property.match}")
    private String metadataPropertyToMatch; // Property to match in metadata

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("route-put-post-delete-dynamic",
                        r -> r.path("/tdk/cms/rest/**")
                                .and()
                                .method(HttpMethod.PUT)
                                .filters(f -> f.filter(new MetadataRoutingFilter(onPremUrl, cloudUrl, metadataPropertyToMatch)))
                                .uri("http://dummy")) // dummy uri to match the route
                .build();
    }
}
