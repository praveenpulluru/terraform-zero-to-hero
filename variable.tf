package gov.uspto.tmcms.gateway.matcher;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.codec.multipart.FormFieldPart;
import org.springframework.http.codec.multipart.Part;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.Map;
import java.util.function.Predicate;

@Component
public class MetadataMatcher {

    private final ObjectMapper objectMapper = new ObjectMapper();

    public Mono<Boolean> matchWithPredicate(ServerWebExchange exchange, String property, Predicate<Object> valuePredicate) {
        return extractMetadataFromRequest(exchange)
            .map(metadata -> metadata.containsKey(property) && valuePredicate.test(metadata.get(property)))
            .onErrorResume(ex -> {
                // Optional: log the error
                return Mono.just(false);
            });
    }

    private Mono<Map<String, Object>> extractMetadataFromRequest(ServerWebExchange exchange) {
        return exchange.getMultipartData()
            .flatMap(parts -> {
                Part part = parts.getFirst("metadata");
                if (part instanceof FormFieldPart formFieldPart) {
                    String json = formFieldPart.value();
                    try {
                        Map<String, Object> metadata = objectMapper.readValue(json, new TypeReference<>() {});
                        return Mono.just(metadata);
                    } catch (Exception e) {
                        return Mono.error(new RuntimeException("Failed to parse multipart metadata JSON", e));
                    }
                } else {
                    return Mono.just(Map.of()); // No metadata part
                }
            });
    }
}



package gov.uspto.tmcms.gateway.config;

import gov.uspto.tmcms.gateway.matcher.MetadataMatcher;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.web.server.ServerWebExchange;

import java.net.URI;

@Configuration
public class GatewayRoutesConfig {

    @Value("${services.cloud-url}")
    private String cloudUrl;

    private final MetadataMatcher metadataMatcher;

    public GatewayRoutesConfig(MetadataMatcher metadataMatcher) {
        this.metadataMatcher = metadataMatcher;
    }

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
            .route("route-put-mark-documents", r -> r
                .path("/trademark/cms/rest/case/**")
                .and()
                .method("PUT")
                .filters(f -> f
                    .filter((exchange, chain) ->
                        metadataMatcher.matchWithPredicate(exchange, "documentType", val -> "mark".equals(val))
                            .flatMap(match -> {
                                if (match) {
                                    ServerHttpRequest mutatedRequest = exchange.getRequest().mutate()
                                        .path(rewritePath(exchange))
                                        .uri(URI.create(cloudUrl))
                                        .build();

                                    return chain.filter(exchange.mutate().request(mutatedRequest).build());
                                }
                                return chain.filter(exchange);
                            })
                    )
                )
                .uri(cloudUrl) // fallback uri
            )
            .build();
    }

    private String rewritePath(ServerWebExchange exchange) {
        String path = exchange.getRequest().getURI().getPath();
        // Extract variables from original path
        // Example: /trademark/cms/rest/case/76900900/mark/MRK_00.jpg
        String[] parts = path.split("/");
        if (parts.length >= 8) {
            String sn = parts[5];
            String filename = parts[7];
            return "/cases/" + sn + "/MRK/" + filename;
        }
        throw new IllegalArgumentException("Invalid path structure: " + path);
    }
}
