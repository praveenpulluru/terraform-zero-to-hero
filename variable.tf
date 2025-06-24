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

    /**
     * Match metadata value using a custom predicate function.
     */
    public Mono<Boolean> matchWithPredicate(ServerWebExchange exchange, String property, Predicate<Object> valuePredicate) {
        return extractMetadataFromRequest(exchange)
            .map(metadata -> metadata.containsKey(property) && valuePredicate.test(metadata.get(property)))
            .onErrorResume(e -> {
                // Optional: Log error
                return Mono.just(false);
            });
    }

    /**
     * Extracts metadata JSON from a multipart field named "metadata"
     */
    private Mono<Map<String, Object>> extractMetadataFromRequest(ServerWebExchange exchange) {
        return exchange.getMultipartData()
            .flatMap(parts -> {
                Part part = parts.getFirst("metadata");
                if (part instanceof FormFieldPart formFieldPart) {
                    try {
                        Map<String, Object> metadata = objectMapper.readValue(
                                formFieldPart.value(),
                                new TypeReference<>() {}
                        );
                        return Mono.just(metadata);
                    } catch (Exception e) {
                        return Mono.error(new RuntimeException("Failed to parse JSON metadata", e));
                    }
                }
                return Mono.just(Map.of()); // fallback
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
                .filters(f -> f.filter((exchange, chain) ->
                    metadataMatcher.matchWithPredicate(exchange, "documentType", val -> "mark".equals(val))
                        .flatMap(match -> {
                            if (match) {
                                ServerHttpRequest mutatedRequest = exchange.getRequest().mutate()
                                        .uri(URI.create(cloudUrl))
                                        .build();
                                return chain.filter(exchange.mutate().request(mutatedRequest).build());
                            }
                            return chain.filter(exchange);
                        })
                ).rewritePath(
                    "/trademark/cms/rest/case/(?<sn>\\d{8})/(?<doctype>[^/]+)/(?<filename>[^/]+)",
                    "/cases/${sn}/MRK/${filename}"
                ))
                .uri(cloudUrl)
            )
            .build();
    }
}





@Component
public class RewritePathFilter implements GatewayFilter, Ordered {

    private static final Pattern PATH_PATTERN =
        Pattern.compile("/trademark/cms/rest/case/(?<sn>\\d{8})/(?<doctype>[^/]+)/(?<filename>[^/]+)");

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getURI().getPath();
        Matcher matcher = PATH_PATTERN.matcher(path);
        if (matcher.matches()) {
            String sn = matcher.group("sn");
            String filename = matcher.group("filename");
            String newPath = "/cases/" + sn + "/MRK/" + filename;

            ServerHttpRequest newRequest = exchange.getRequest().mutate()
                .path(newPath)
                .build();

            return chain.filter(exchange.mutate().request(newRequest).build());
        }
        return chain.filter(exchange);
    }

    @Override
    public int getOrder() {
        return -1;
    }
}
