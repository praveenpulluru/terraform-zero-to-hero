@Component
public class MetadataMatcherFilter{
	
	   private static final Logger logger = LoggerFactory.getLogger(MetadataMatcherFilter.class);

	    private final MetadataMatcher metadataMatcher;

	    public MetadataMatcherFilter(MetadataMatcher metadataMatcher) {
	        this.metadataMatcher = metadataMatcher;
	    }

	    public GatewayFilter createFilter(String key, String value, String cloudUrl, String onPremUrl) {
	        return (exchange, chain) ->
	            metadataMatcher.match(exchange, key, value)
	                .flatMap(match -> {
	                    URI targetBaseUri = match ? URI.create(cloudUrl) : URI.create(onPremUrl);
	                    URI currentUri = exchange.getRequest().getURI();

	                    URI finalUri = UriComponentsBuilder.fromUri(targetBaseUri)
	                        .path(currentUri.getPath())
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



@Configuration
public class GatewayRoutesConfig {

	@Value("${services.on-prem-url}")
	private String onPremUrl;

	@Value("${services.cloud-url}")
	private String cloudUrl;

	private static final String on_prem = "on-prem";
	private static final String cloud = "cloud";

	private final MetadataMatcherFilter metadataMatcherFilter;

    public GatewayRoutesConfig(MetadataMatcherFilter metadataMatcherFilter) {
        this.metadataMatcherFilter = metadataMatcherFilter;
    }


	 @Bean
	    public RouteLocator customRouteLocator(RouteLocatorBuilder builder,RewritePathFilter rewritePathFilter) {
	        return builder.routes()
	        		.route("route-post-metadata-based-routing", r -> r
	        			    .path("/trademark/cms/rest/case/**")
	        			    .and()
	        			    .method(HttpMethod.PUT)
	        			    .filters(f -> f
	        			        .filter(metadataMatcherFilter.createFilter("documentType","mark",cloudUrl,onPremUrl))
	        			        .filter(rewritePathFilter)
	        			        //.rewritePath("/trademark/cms/rest/case/(?<sn>\\d{8})\\/(?<doctype>[^/]+)\\/(?<filename>[^/]+)$","/cases/${sn}/MRK/${filename}")
	        			    )
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
            String newPath = "/cases/" + sn + "/mark/" + filename;

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


.route("route-all-GET-to-agg-service",
				r -> r.path("/trademark/cms/rest/**")
				.and()
				.method(HttpMethod.GET)
				.filters(f -> f.filter(new CustomAggregationFilter(WebClient.builder(), onPremUrl, cloudUrl, on_prem, cloud)))
				.uri("http://dummy"))

public class CustomAggregationFilter implements GatewayFilter {

	private static final Logger logger = LoggerFactory.getLogger(CustomAggregationFilter.class);
	
	private final WebClient.Builder webClientBuilder;

	private final String onPremUrl;
	private final String cloudUrl;
	private final String onPrem;
	private final String cloud;

	private final ObjectMapper objectMapper = new ObjectMapper();

	public CustomAggregationFilter(WebClient.Builder webClientBuilder, String onPremUrl, String cloudUrl,
			String onPremService, String cloudService) {
		this.webClientBuilder = webClientBuilder;
		this.onPremUrl = onPremUrl;
		this.cloudUrl = cloudUrl;
		this.onPrem = onPremService;
		this.cloud = cloudService;
	}

	@Override
	public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {

		String service = exchange.getRequest().getHeaders().getFirst("service");

		if (service == null || service.isEmpty()) {
			service = exchange.getRequest().getQueryParams().getFirst("service");
		}

		if (service == null || service.isEmpty()) {
			return callBothServicesAndAggregate(exchange);
		}

		exchange.getResponse().setStatusCode(org.springframework.http.HttpStatus.BAD_REQUEST);
		return exchange.getResponse().setComplete();
	}

	private WebClient getWebClient(String service) {
		String baseUrl = "";

		if (onPrem.equalsIgnoreCase(service)) {
			baseUrl = onPremUrl;
		} else if (cloud.equalsIgnoreCase(service)) {
			baseUrl = cloudUrl;
		}

		return webClientBuilder.baseUrl(baseUrl).build();
	}

	private Mono<Void> callBothServicesAndAggregate(ServerWebExchange exchange) {
	    Mono<String> onPremResponse = getWebClient(onPrem).get()
	        .uri(uriBuilder -> uriBuilder.path(exchange.getRequest().getURI().getPath()).build())
	        .retrieve()
	        .bodyToMono(String.class)
	        .onErrorResume(e -> {
	        	logger.error("Error while calling on-prem service: ",e);
	            return Mono.just("[]"); 
	        });

	    String path = exchange.getRequest().getPath().toString();
	    String[] pathParts = path.split("/");
	    String caseId = pathParts.length > 5 ? pathParts[5] : "";
	    String uri = "/cases/" + caseId + "/documents/metadata";

	    Mono<String> cloudResponse = getWebClient(cloud).get().uri(uri).retrieve()
	        .bodyToMono(String.class)
	        .onErrorResume(e -> {
	        	logger.error("Error while calling cloud service: ",e);
	            return Mono.just("[]"); 
	        });

	    return Mono.zip(onPremResponse, cloudResponse).flatMap(responses -> {
	        String onPremData = responses.getT1();
	        String cloudData = responses.getT2();

	        String combinedResponse = mergeResponses(onPremData, cloudData);

	        exchange.getResponse().getHeaders().setContentType(MediaType.APPLICATION_JSON);
	        return exchange.getResponse()
	            .writeWith(Mono.just(exchange.getResponse().bufferFactory().wrap(combinedResponse.getBytes())));
	    });
	}

	// Aggregate Logic(Preferring cloud versions if both services have the same
	// document,Including all unique documents from both sources)
	private String mergeResponses(String onPremData, String cloudData) {
		try {
			ArrayNode onPremArray = (ArrayNode) objectMapper.readTree(onPremData);
			ArrayNode cloudArray = (ArrayNode) objectMapper.readTree(cloudData);

			Map<String, JsonNode> cloudLookup = new HashMap<>();
			Set<String> matchedKeys = new HashSet<>();

			for (JsonNode cloudDoc : cloudArray) {
				String key = getMatchKey(cloudDoc);
				if (key != null) {
					cloudLookup.put(key, cloudDoc);
				}
			}

			ArrayNode finalDocs = objectMapper.createArrayNode();

			for (JsonNode onPremDoc : onPremArray) {
				String key = getMatchKey(onPremDoc);
				if (key != null && cloudLookup.containsKey(key)) {
					finalDocs.add(cloudLookup.get(key));
					matchedKeys.add(key);
				} else {
					finalDocs.add(onPremDoc);
				}
			}

			for (Map.Entry<String, JsonNode> entry : cloudLookup.entrySet()) {
				if (!matchedKeys.contains(entry.getKey())) {
					finalDocs.add(entry.getValue());
				}
			}

			ObjectNode result = objectMapper.createObjectNode();
			result.set("documents", finalDocs);
			return objectMapper.writeValueAsString(result);

		} catch (Exception e) {
			logger.error("Error while merging json : ",e);
			return "{\"error\": \"Failed to merge responses\"}";
		}
	}

	// Matching documents by their name (excluding file extension)
	private String getMatchKey(JsonNode doc) {
		JsonNode metadata = doc.path("metadata");
		if (metadata.isMissingNode())
			return null;

		String documentName = metadata.path("documentName").asText(null);
		if (documentName == null || documentName.isEmpty())
			return null;
		int dotIndex = documentName.lastIndexOf(".");
		return (dotIndex > 0) ? documentName.substring(0, dotIndex) : documentName;
	}
}
