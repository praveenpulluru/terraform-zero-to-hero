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
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("route-put-post-delete-to-cloud",
                        r -> r.path("/trademark/cms/rest/case/*/mark/**").and()
                        .method(HttpMethod.POST, HttpMethod.PUT)
                        .filters(f -> f.filter((exchange, chain) -> {
                            if (shouldRouteToCloud(exchange)) {
                                return chain.filter(exchange.mutate().request(createCloudRequest(exchange)).build());
                            }
                            return chain.filter(exchange);
                        }).rewritePath("/trademark/cms/rest/case/(?<sn>\\d{8})\\/(?<doctype>[^/]+)\\/(?<filename>[^/]+)$", "/cases/${sn}/MRK/${filename}")
                        )
                        .uri(cloudUrl))

                .route("route-save-as-mark-to-cloud", r -> r.path("/trademark/cms/rest/case/*/mark")
                        .and()
                        .method(HttpMethod.POST)
                        .filters(f -> f.filter((exchange, chain) -> {
                            if (shouldRouteToCloud(exchange)) {
                                return chain.filter(exchange.mutate().request(createCloudRequest(exchange)).build());
                            }
                            return chain.filter(exchange);
                        }))
                        .uri(cloudUrl))
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
