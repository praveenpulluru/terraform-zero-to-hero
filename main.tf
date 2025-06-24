@Component
public class MetadataMatcherFilter implements GatewayFilter {

    private final MetadataMatcher metadataMatcher;

    @Value("${services.on-prem-url}")
    private String onPremUrl;

    @Value("${services.cloud-url}")
    private String cloudUrl;

    public MetadataMatcherFilter(MetadataMatcher metadataMatcher) {
        this.metadataMatcher = metadataMatcher;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        return metadataMatcher.matchWithPredicate(exchange, "documentType", val -> "mark".equals(val))
            .flatMap(match -> {
                URI targetBaseUri = match ? URI.create(cloudUrl) : URI.create(onPremUrl);
                URI currentUri = exchange.getRequest().getURI();

                URI finalUri = UriComponentsBuilder.fromUri(targetBaseUri)
                    .path(currentUri.getPath())
                    .query(currentUri.getQuery())
                    .build(true)
                    .toUri();

                ServerHttpRequest mutatedRequest = exchange.getRequest()
                    .mutate()
                    .uri(finalUri)
                    .build();

                return chain.filter(exchange.mutate().request(mutatedRequest).build());
            });
    }
}


@Component
public class MetadataMatcherFilter implements GatewayFilter {

    private final MetadataMatcher metadataMatcher;

    @Value("${services.on-prem-url}")
    private String onPremUrl;

    @Value("${services.cloud-url}")
    private String cloudUrl;

    public MetadataMatcherFilter(MetadataMatcher metadataMatcher) {
        this.metadataMatcher = metadataMatcher;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        return metadataMatcher.matchWithPredicate(exchange, "documentType", val -> "mark".equals(val))
            .flatMap(match -> {
                URI targetBaseUri = match ? URI.create(cloudUrl) : URI.create(onPremUrl);
                URI currentUri = exchange.getRequest().getURI();

                URI finalUri = UriComponentsBuilder.fromUri(targetBaseUri)
                    .path(currentUri.getPath())
                    .query(currentUri.getQuery())
                    .build(true)
                    .toUri();

                ServerHttpRequest mutatedRequest = exchange.getRequest()
                    .mutate()
                    .uri(finalUri)
                    .build();

                return chain.filter(exchange.mutate().request(mutatedRequest).build());
            });
    }
}





package gov.uspto.tmcms.gateway.filter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.util.Assert;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.util.UriComponentsBuilder;
import reactor.core.publisher.Mono;

import java.net.URI;
import java.util.function.Predicate;

@Component
public class MetadataMatcherFilter {

    private static final Logger logger = LoggerFactory.getLogger(MetadataMatcherFilter.class);

    private final MetadataMatcher metadataMatcher;

    public MetadataMatcherFilter(MetadataMatcher metadataMatcher) {
        this.metadataMatcher = metadataMatcher;
    }

    public org.springframework.cloud.gateway.filter.GatewayFilter createFilter(String metadataKey, Predicate<String> matcher, String cloudUrl, String onPremUrl) {
        return (exchange, chain) ->
            metadataMatcher.matchWithPredicate(exchange, metadataKey, matcher)
                .flatMap(match -> {
                    URI targetBaseUri = match ? URI.create(cloudUrl) : URI.create(onPremUrl);
                    URI currentUri = exchange.getRequest().getURI();

                    URI finalUri = UriComponentsBuilder.fromUri(targetBaseUri)
                        .path(currentUri.getPath())
                        .query(currentUri.getQuery())
                        .build(true)
                        .toUri();

                    logger.debug("Routing to final URI: {}", finalUri);

                    ServerHttpRequest mutatedRequest = exchange.getRequest().mutate()
                        .uri(finalUri)
                        .build();

                    ServerWebExchange mutatedExchange = exchange.mutate().request(mutatedRequest).build();
                    return chain.filter(mutatedExchange);
                });
    }
}


package gov.uspto.tmcms.gateway.config;

import gov.uspto.tmcms.gateway.filter.MetadataMatcherFilter;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GatewayRoutesConfig {

    private final MetadataMatcherFilter metadataMatcherFilter;

    public GatewayRoutesConfig(MetadataMatcherFilter metadataMatcherFilter) {
        this.metadataMatcherFilter = metadataMatcherFilter;
    }

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        String cloudUrl = "http://cloud-app";    // replace with actual
        String onPremUrl = "http://onprem-app";  // replace with actual

        return builder.routes()
            .route("mark_upload", r -> r
                .path("/trademark/cms/rest/case/{caseId}/mark/{fileName}")
                .filters(f -> f
                    .filter(metadataMatcherFilter.createFilter(
                        "documentType",
                        val -> "mark".equals(val),
                        cloudUrl,
                        onPremUrl
                    ))
                )
                .uri("http://placeholder")) // will be overridden
            .build();
    }
}
