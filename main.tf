.route("route-put-mark-documents", r -> r
    .path("/trademark/cms/rest/case/**")
    .and()
    .method("PUT")
    .filters(f -> f
        .filter(rewritePathFilter) // Apply path rewrite first
        .filter((exchange, chain) ->
            metadataMatcher.matchWithPredicate(exchange, "documentType", val -> "mark".equals(val))
                .flatMap(match -> {
                    if (match) {
                        URI updatedUri = exchange.getRequest().getURI();
                        String rewrittenPath = updatedUri.getPath(); // after rewrite
                        URI newUri = UriComponentsBuilder.fromUri(updatedUri)
                            .scheme("https")
                            .host(URI.create(cloudUrl).getHost())
                            .port(URI.create(cloudUrl).getPort())
                            .replacePath(rewrittenPath)
                            .build(true)
                            .toUri();

                        ServerHttpRequest mutatedRequest = exchange.getRequest().mutate()
                            .uri(newUri)
                            .build();

                        return chain.filter(exchange.mutate().request(mutatedRequest).build());
                    }
                    return chain.filter(exchange);
                })
        )
    )
    .uri(cloudUrl)
)
