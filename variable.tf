import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.util.MultiValueMap;
import org.springframework.web.multipart.Part;
import org.springframework.web.reactive.function.BodyInserters;
import reactor.core.publisher.Mono;
import org.springframework.web.server.ServerWebExchange;
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
        // Check if the request is multipart/form-data
        if (exchange.getRequest().getHeaders().getContentType().equals(MediaType.MULTIPART_FORM_DATA)) {
            // Access the multipart data
            return exchange.getRequest().getMultipartData()
                    .flatMap(multipartData -> {
                        // Retrieve metadata from multipart data
                        Part metadataPart = multipartData.getFirst("metadata");

                        if (metadataPart != null) {
                            // Process metadata (e.g., parse JSON)
                            return metadataPart.getContent().map(buffer -> {
                                try {
                                    String metadataJson = new String(buffer.array(), StandardCharsets.UTF_8);
                                    Map<String, Object> metadata = parseMetadata(metadataJson);

                                    // Perform matching based on metadata
                                    if (MetadataMatcher.matchMetadata(metadata, metadataPropertyToMatch)) {
                                        // If matched, route to cloud
                                        exchange.getRequest().mutate().uri(URI.create(cloudUrl)).build();
                                    } else {
                                        // If not matched, route to on-prem
                                        exchange.getRequest().mutate().uri(URI.create(onPremUrl)).build();
                                    }

                                } catch (IOException e) {
                                    e.printStackTrace();
                                }
                                return exchange;
                            }).flatMap(chain::filter);
                        }

                        return chain.filter(exchange); // Proceed if no metadata part
                    });
        }

        // Proceed as usual if the request is not multipart
        return chain.filter(exchange);
    }

    // Helper method to parse metadata
    private Map<String, Object> parseMetadata(String metadataJson) throws IOException {
        // Add JSON parsing logic (e.g., Jackson or Gson)
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

    @Value("${metadata.property.match}")
    private String metadataPropertyToMatch;

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("route-put-post-delete-dynamic",
                        r -> r.path("/tdk/cms/rest/**")
                                .and()
                                .method(HttpMethod.PUT)
                                .filters(f -> f.filter(new MetadataRoutingFilter(onPremUrl, cloudUrl, metadataPropertyToMatch)))
                                .uri("http://dummy")) // dummy uri just to match the route
                .build();
    }
}
