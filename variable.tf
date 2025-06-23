@Configuration
public class GatewayRoutesConfig {

	@Value("${services.on-prem-url}")
	private String onPremUrl;

	@Value("${services.cloud-url}")
	private String cloudUrl;

	private static final String on_prem = "on-prem";
	private static final String cloud = "cloud";

	@Bean
	RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
		return builder.routes().route("route-all-GET-to-agg-service",
				r -> r.path("/tdk/cms/rest/**")
				.and()
				.method(HttpMethod.GET)
				.filters(f -> f.filter(new CustomAggregationFilter(WebClient.builder(), onPremUrl, cloudUrl, on_prem, cloud)))
				.uri("http://dummy"))
				
				// Route MARK - POST, PUT, DELETE to Cloud
				.route("route-save-as-mark-to-cloud",
				r -> r.path("/tdk/cms/rest/case/*/*/*/set-as-mark").and()
				.method(HttpMethod.POST)
				.filters(f -> f.rewritePath("/tdk/cms/rest/case/(?<sn>\\d{8})\\/(?<doctype>[^/]+)\\/(?<filename>[^/]+)\\/set-as-mark","/cases/${sn}/${doctype}/${filename}/set-as-mark"))
				.uri(cloudUrl))
				
				// Route MARK - POST, PUT, DELETE to Cloud
				.route("route-put-post-delete-to-cloud",
				r -> r.path("/tdk/cms/rest/case/*/mark/**").and()
				.method(HttpMethod.POST, HttpMethod.PUT)
				.filters(f -> f.rewritePath("/tdk/cms/rest/case/(?<sn>\\d{8})\\/(?<doctype>[^/]+)\\/(?<filename>[^/]+)$","/cases/${sn}/MRK/${filename}"))
				.uri(cloudUrl))
				
				// Route POST, PUT, DELETE to Cloud
				.route("route-put-post-delete-to-cloud",
				r -> r.path("/tdk/cms/rest/**").and()
				.method(HttpMethod.POST, HttpMethod.PUT, HttpMethod.DELETE)
				.filters(f -> f.rewritePath("/tdk/cms/rest/case/(?<sn>[^/]+)(?<remaining>/.*)?","/cases/${sn}${remaining}"))
				.uri(cloudUrl))
				.build();
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

	@Bean
	RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
		return builder.routes().route("route-all-GET-to-agg-service",
				r -> r.path("/tdk/cms/rest/**")
				.and()
				.method(HttpMethod.GET)
				.filters(f -> f.filter(new CustomAggregationFilter(WebClient.builder(), onPremUrl, cloudUrl, on_prem, cloud)))
				.uri("http://dummy"))
				
				// Route MARK - POST, PUT, DELETE to Cloud
				.route("route-save-as-mark-to-cloud",
				r -> r.path("/tdk/cms/rest/case/*/*/*/set-as-mark").and()
				.method(HttpMethod.POST)
				.filters(f -> f.rewritePath("/tdk/cms/rest/case/(?<sn>\\d{8})\\/(?<doctype>[^/]+)\\/(?<filename>[^/]+)\\/set-as-mark","/cases/${sn}/${doctype}/${filename}/set-as-mark"))
				.uri(cloudUrl))
				
				// Route MARK - POST, PUT, DELETE to Cloud
				.route("route-put-post-delete-to-cloud",
				r -> r.path("/tdk/cms/rest/case/*/mark/**").and()
				.method(HttpMethod.POST, HttpMethod.PUT)
				.filters(f -> f.rewritePath("/tdk/cms/rest/case/(?<sn>\\d{8})\\/(?<doctype>[^/]+)\\/(?<filename>[^/]+)$","/cases/${sn}/MRK/${filename}"))
				.uri(cloudUrl))
				
				// Route POST, PUT, DELETE to Cloud
				.route("route-put-post-delete-to-cloud",
				r -> r.path("/tdk/cms/rest/**").and()
				.method(HttpMethod.POST, HttpMethod.PUT, HttpMethod.DELETE)
				.filters(f -> f.rewritePath("/tdk/cms/rest/case/(?<sn>[^/]+)(?<remaining>/.*)?","/cases/${sn}${remaining}"))
				.uri(cloudUrl))
				.build();
	}

}



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
