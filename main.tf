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
