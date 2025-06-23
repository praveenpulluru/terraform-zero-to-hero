import gov.uspto.tmcms.gateway.matcher.MetadataMatcher;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class GatewayRoutesConfig {

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
                                ServerHttpRequest mutatedRequest = createCloudRequest(exchange);
                                return chain.filter(exchange.mutate().request(mutatedRequest).build());
                            }
                            return chain.filter(exchange);
                        })
                ))
                .uri("https://test.dev.tttt.tt:443")
            )
            .build();
    }

    /**
     * Rewrite the request path or headers here as needed.
     */
    private ServerHttpRequest createCloudRequest(org.springframework.web.server.ServerWebExchange exchange) {
        String originalPath = exchange.getRequest().getURI().getPath();

        // Example rewrite: /trademark/cms/rest/case/76900900/mark/MRK_00.jpg => /cases/76900900/MRK/MRK_00.jpg
        String newPath = originalPath.replaceAll(
            "/trademark/cms/rest/case/(\\d{8})/[^/]+/([^/]+)",
            "/cases/$1/MRK/$2"
        );

        return exchange.getRequest()
            .mutate()
            .path(newPath)
            .build();
    }
}
