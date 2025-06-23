org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'org.springframework.cloud.gateway.config.GatewayClassPathWarningAutoConfiguration$SpringMvcFoundOnClasspathConfiguration': Failed to instantiate [org.springframework.cloud.gateway.config.GatewayClassPathWarningAutoConfiguration$SpringMvcFoundOnClasspathConfiguration]: Constructor threw exception

import org.springframework.stereotype.Component;
import org.springframework.http.HttpMethod;
import org.springframework.util.MultiValueMap;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.Map;

@Component
public class MetadataMatcher {

    // Match based on a specific metadata property key-value pair
    public boolean match(ServerWebExchange exchange, String property, String expectedValue) {
        // Extract metadata from the request body (assuming multipart form data)
        Map<String, Object> metadata = extractMetadataFromRequest(exchange);

        // Check if the property exists in the metadata and matches the expected value
        return metadata != null && metadata.containsKey(property) && expectedValue.equals(metadata.get(property));
    }

    // Helper method to extract metadata from the request body
    private Map<String, Object> extractMetadataFromRequest(ServerWebExchange exchange) {
        // Logic to extract metadata from the request body (assuming multipart form-data)
        // This can be done using a WebClient, or by parsing the body of the request directly
        // For simplicity, we assume metadata is available as a Map in the request

        // For now, assume it's just a mock object for demonstration purposes:
        return Map.of(
                "documentName", "MRK_00.jpg",
                "documentAlias", "mark",
                "createdByUserId", "eFile",
                "accessLevel", "public",
                "documentType", "mark",
                "docCode", "MRK"
        );
    }
}





import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.RouteLocatorBuilder;
import org.springframework.web.server.ServerHttpRequest;
import org.springframework.web.server.ServerHttpResponse;

@Configuration
public class GatewayRoutesConfig {

    @Value("${services.on-prem-url}")
    private String onPremUrl;

    @Value("${services.cloud-url}")
    private String cloudUrl;

    private static final String onPrem = "on-prem";
    private static final String cloud = "cloud";

    private final MetadataMatcher metadataMatcher;

    public GatewayRoutesConfig(MetadataMatcher metadataMatcher) {
        this.metadataMatcher = metadataMatcher;
    }

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("route-save-as-mark-to-cloud", r -> r.path("/tdk/cms/rest/case/*/*/*/set-as-mark")
                        .and()
                        .method(HttpMethod.POST)
                        .filters(f -> f.filter((exchange, chain) -> {
                            if (shouldRouteToCloud(exchange)) {
                                return chain.filter(exchange.mutate().request(createCloudRequest(exchange)).build());
                            }
                            return chain.filter(exchange);
                        }))
                        .uri(cloudUrl))
                .route("route-put-post-delete-to-cloud", r -> r.path("/tdk/cms/rest/case/*/mark/**")
                        .and()
                        .method(HttpMethod.POST, HttpMethod.PUT)
                        .filters(f -> f.filter((exchange, chain) -> {
                            if (shouldRouteToCloud(exchange)) {
                                return chain.filter(exchange.mutate().request(createCloudRequest(exchange)).build());
                            }
                            return chain.filter(exchange);
                        }))
                        .uri(cloudUrl))
                .route("route-put-post-delete-to-on-prem", r -> r.path("/tdk/cms/rest/**")
                        .and()
                        .method(HttpMethod.POST, HttpMethod.PUT, HttpMethod.DELETE)
                        .filters(f -> f.filter((exchange, chain) -> {
                            if (shouldRouteToOnPrem(exchange)) {
                                return chain.filter(exchange.mutate().request(createOnPremRequest(exchange)).build());
                            }
                            return chain.filter(exchange);
                        }))
                        .uri(onPremUrl))
                .build();
    }

    private boolean shouldRouteToCloud(ServerWebExchange exchange) {
        return metadataMatcher.match(exchange, "documentType", "mark");  // Example of matching based on documentType
    }

    private boolean shouldRouteToOnPrem(ServerWebExchange exchange) {
        return metadataMatcher.match(exchange, "sourceMedium", "EMAIL");  // Example of matching based on sourceMedium
    }

    private ServerHttpRequest createCloudRequest(ServerWebExchange exchange) {
        return exchange.getRequest().mutate().uri(URI.create(cloudUrl)).build();
    }

    private ServerHttpRequest createOnPremRequest(ServerWebExchange exchange) {
        return exchange.getRequest().mutate().uri(URI.create(onPremUrl)).build();
    }
}
