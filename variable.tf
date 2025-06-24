import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.core.io.buffer.DataBufferUtils;
import org.springframework.http.codec.multipart.Part;
import org.springframework.http.codec.multipart.FormFieldPart;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.function.Predicate;

@Component
public class MetadataMatcher {

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Match metadata value using a custom predicate function.
     * @param exchange       the current server exchange
     * @param property       the metadata property key
     * @param valuePredicate the predicate to evaluate the property's value
     * @return Mono<Boolean> if the metadata matches
     */
    public Mono<Boolean> matchWithPredicate(ServerWebExchange exchange, String property, Predicate<Object> valuePredicate) {
        return extractMetadataFromRequest(exchange)
            .map(metadata -> metadata.containsKey(property) && valuePredicate.test(metadata.get(property)))
            .onErrorResume(ex -> {
                // log or handle error if needed
                return Mono.just(false);
            });
    }

    /**
     * Extracts metadata from a multipart request with a field named "metadata".
     * Assumes "metadata" is a JSON string part in the multipart body.
     */
    private Mono<Map<String, Object>> extractMetadataFromRequest(ServerWebExchange exchange) {
        if (!exchange.getRequest().getHeaders().getContentType().toString().startsWith("multipart/form-data")) {
            return Mono.just(Map.of());
        }

        return exchange.getMultipartData()
            .flatMap(parts -> {
                Part part = parts.getFirst("metadata"); // expecting field named "metadata"
                if (part instanceof FormFieldPart formFieldPart) {
                    String json = formFieldPart.value();
                    try {
                        Map<String, Object> metadata = objectMapper.readValue(json, new TypeReference<>() {});
                        return Mono.just(metadata);
                    } catch (Exception e) {
                        return Mono.error(new RuntimeException("Failed to parse multipart metadata JSON", e));
                    }
                } else {
                    return Mono.just(Map.of()); // metadata part not found or not text
                }
            });
    }
}


import java.net.URI;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.web.server.ServerWebExchange;

import gov.uspto.tmcms.gateway.filter.RewritePathFilter;
import gov.uspto.tmcms.gateway.matcher.MetadataMatcher;

@Configuration
public class GatewayRoutesConfig {

	@Value("${services.on-prem-url}")
	private String onPremUrl;

	@Value("${services.cloud-url}")
	private String cloudUrl;

	private static final String on_prem = "on-prem";
	private static final String cloud = "cloud";
	
	private final MetadataMatcher metadataMatcher;

    public GatewayRoutesConfig(MetadataMatcher metadataMatcher) {
        this.metadataMatcher = metadataMatcher;
    }

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder, RewritePathFilter rewritePathFilter) {
    	return builder.routes()
                .route("route-put-mark-documents", r -> r
                    .path("/trademark/cms/rest/case/**")
                    .and()
                    .method("PUT")
                    .filters(f -> f.filter((exchange, chain) ->
                        metadataMatcher.matchWithPredicate(exchange, "documentType", val -> "mark".equals(val))
                            .flatMap(match -> {
                                if (match) {
                                    ServerHttpRequest mutatedRequest = createCloudRequest(exchange);
                                    return chain.filter(exchange.mutate().request(mutatedRequest).build());
                                }
                                return chain.filter(exchange);
                            })
                    ).rewritePath("/trademark/cms/rest/case/(?<sn>\\d{8})\\/(?<doctype>[^/]+)\\/(?<filename>[^/]+)$","/cases/${sn}/MRK/${filename}"))
                    .uri(cloudUrl)
                )
                .build();
    }

    private ServerHttpRequest createCloudRequest(ServerWebExchange exchange) {
        return exchange.getRequest().mutate().uri(URI.create(cloudUrl)).build();
    }

    private ServerHttpRequest createOnPremRequest(ServerWebExchange exchange) {
        return exchange.getRequest().mutate().uri(URI.create(onPremUrl)).build();
    }

}

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.core.Ordered;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;

import reactor.core.publisher.Mono;

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
