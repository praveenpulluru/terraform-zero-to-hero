<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
spring:
  webflux:
    base-path: /api
  multipart:
    enabled: true
    max-file-size: 10MB
    max-request-size: 10MB
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.http.HttpMethod;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.util.MultiValueMap;
import org.springframework.web.multipart.Part;
import reactor.core.publisher.Mono;
import java.util.Map;
import java.io.IOException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

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
        // Check if the request is multipart
        if (exchange.getRequest().getHeaders().getContentType().includes(MediaType.MULTIPART_FORM_DATA)) {
            return exchange.getRequest().getMultipartData()
                    .flatMap(multipartData -> {
                        // Extract metadata from the multipart form
                        Part metadataPart = multipartData.getFirst("metadata");

                        if (metadataPart != null) {
                            return metadataPart.getContent()
                                    .map(buffer -> {
                                        try {
                                            String metadataJson = new String(buffer.array(), StandardCharsets.UTF_8);
                                            Map<String, Object> metadata = parseMetadata(metadataJson);

                                            // Perform matching based on metadata
                                            if (MetadataMatcher.matchMetadata(metadata, metadataPropertyToMatch)) {
                                                // Route to cloud if matched
                                                exchange.getRequest().mutate().uri(URI.create(cloudUrl)).build();
                                            } else {
                                                // Route to on-prem if not matched
                                                exchange.getRequest().mutate().uri(URI.create(onPremUrl)).build();
                                            }

                                        } catch (IOException e) {
                                            e.printStackTrace();
                                        }
                                        return exchange;
                                    })
                                    .flatMap(chain::filter);
                        }

                        return chain.filter(exchange); // Proceed if no metadata found
                    });
        }

        // Proceed as usual if the request is not multipart
        return chain.filter(exchange);
    }

    // Helper method to parse metadata
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
                                .uri("http://dummy")) // dummy uri just to match the route
                .build();
    }
}
