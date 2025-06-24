.route("route-post-metadata-based-routing", r -> r
    .path("/trademark/cms/rest/case/**")
    .and()
    .method(HttpMethod.POST)
    .filters(f -> f
        .filter(rewritePathFilter)
        .filter((exchange, chain) ->
            metadataMatcher.matchWithPredicate(exchange, "documentType", val -> "mark".equals(val))
                .flatMap(match -> {
                    URI targetBaseUri = match ? URI.create(cloudUrl) : URI.create(onPremUrl);
                    URI currentUri = exchange.getRequest().getURI();

                    URI finalUri = UriComponentsBuilder.fromUri(targetBaseUri)
                        .path(currentUri.getPath()) // use rewritten path
                        .query(currentUri.getQuery())
                        .build(true)
                        .toUri();

                    ServerHttpRequest mutatedRequest = exchange.getRequest().mutate()
                        .uri(finalUri)
                        .build();

                    return chain.filter(exchange.mutate().request(mutatedRequest).build());
                })
        )
    )
    .uri("http://dummy.com") // dummy to satisfy builder; overridden later
)
