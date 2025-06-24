@Bean
public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
    return builder.routes()

        // Route 1: Straightforward match
        .route("route-put-post-delete-to-cloud", r -> r
            .path("/trademark/cms/rest/case/*/mark/**")
            .and()
            .method(HttpMethod.POST, HttpMethod.PUT)
            .filters(f -> f
                .rewritePath(
                    "/trademark/cms/rest/case/(?<sn>\\d{8})/(?<doctype>[^/]+)/(?<filename>[^/]+)$",
                    "/cases/${sn}/MRK/${filename}"
                )
            )
            .uri(cloudUrl)
        )

        // Route 2: Match based on metadata
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
                                    .uri(URI.create(cloudUrl))
                                    .build();
                                return chain.filter(exchange.mutate().request(mutatedRequest).build());
                            }
                            return chain.filter(exchange);
                        })
                )
                .rewritePath(
                    "/trademark/cms/rest/case/(?<sn>\\d{8})/(?<doctype>[^/]+)/(?<filename>[^/]+)$",
                    "/cases/${sn}/MRK/${filename}"
                )
            )
            .uri(cloudUrl)
        )

        .build();
}




public Mono<Boolean> matchWithPredicate(ServerWebExchange exchange, String property, Predicate<Object> valuePredicate) {
    return extractMetadataFromRequest(exchange)
        .map(metadata -> {
            Object val = metadata.get(property);
            boolean result = metadata.containsKey(property) && valuePredicate.test(val);
            System.out.println("[MetadataMatcher] Match result for key '" + property + "' = " + result + " (value: " + val + ")");
            return result;
        })
        .onErrorResume(e -> {
            System.err.println("[MetadataMatcher] Error extracting metadata: " + e.getMessage());
            return Mono.just(false);
        });
}
