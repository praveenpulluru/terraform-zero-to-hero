Yes, **you can refactor `MetadataMatcherFilter` to behave like `CustomAggregationFilter`**, where instead of routing the request to another URI, it makes a call to the appropriate service (`cloudUrl` or `onPremUrl`) using `WebClient`, and returns the response directly to the client.

---

### ✅ **Goal**

Refactor the existing `MetadataMatcherFilter` to:

* Use `MetadataMatcher` to decide routing logic.
* Based on match, call the appropriate service (cloud/on-prem) using `WebClient`.
* Return the response body back to the caller **without routing**.

---

### ✅ **Step-by-Step Refactor**

#### 1. Update `MetadataMatcherFilter` to use `WebClient`:

```java
@Component
public class MetadataMatcherFilter {

    private static final Logger logger = LoggerFactory.getLogger(MetadataMatcherFilter.class);

    private final MetadataMatcher metadataMatcher;
    private final WebClient.Builder webClientBuilder;

    private final ObjectMapper objectMapper = new ObjectMapper();

    public MetadataMatcherFilter(MetadataMatcher metadataMatcher, WebClient.Builder webClientBuilder) {
        this.metadataMatcher = metadataMatcher;
        this.webClientBuilder = webClientBuilder;
    }

    public GatewayFilter createFilter(String key, String value, String cloudUrl, String onPremUrl) {
        return (exchange, chain) ->
            metadataMatcher.match(exchange, key, value)
                .flatMap(match -> {
                    String targetUrl = match ? cloudUrl : onPremUrl;

                    URI requestUri = exchange.getRequest().getURI();
                    String path = requestUri.getPath();
                    String query = requestUri.getQuery();
                    String fullPath = query != null ? path + "?" + query : path;

                    WebClient webClient = webClientBuilder.baseUrl(targetUrl).build();

                    logger.debug("Calling {} service for path: {}", match ? "cloud" : "on-prem", fullPath);

                    return webClient.method(exchange.getRequest().getMethod())
                        .uri(fullPath)
                        .headers(headers -> headers.addAll(exchange.getRequest().getHeaders()))
                        .body(exchange.getRequest().getBody(), byte[].class)
                        .exchangeToMono(response -> {
                            exchange.getResponse().setStatusCode(response.statusCode());
                            exchange.getResponse().getHeaders().putAll(response.headers().asHttpHeaders());
                            return exchange.getResponse()
                                .writeWith(response.bodyToFlux(DataBuffer.class));
                        });
                });
    }
}
```

---

### ✅ **How to Use It in `GatewayRoutesConfig`**

```java
@Bean
public RouteLocator customRouteLocator(RouteLocatorBuilder builder, RewritePathFilter rewritePathFilter) {
    return builder.routes()
        .route("route-post-metadata-based-routing", r -> r
            .path("/trademark/cms/rest/case/**")
            .and()
            .method(HttpMethod.PUT)
            .filters(f -> f
                .filter(metadataMatcherFilter.createFilter("documentType", "mark", cloudUrl, onPremUrl))
                .filter(rewritePathFilter) // still useful for path transformation
            )
            .uri("http://dummy")) // this won't actually be used
        .build();
}
```

---

### ✅ **Key Benefits of This Approach**

* **No need to mutate the URI and forward:** You intercept the request and respond directly.
* **More control over error handling and response transformation.**
* You can still use filters like `RewritePathFilter` before calling the actual service.

---

### ✅ **Optional Enhancements**

* Add timeouts/retry logic in `WebClient`.
* Log response times for cloud vs. on-prem.
* Transform the response or add custom headers if needed.

---

Would you like me to help extract the response body (e.g., JSON), process or modify it before returning — as done in your `CustomAggregationFilter`?




@Component
public class MetadataMatcherFilter {

    private static final Logger logger = LoggerFactory.getLogger(MetadataMatcherFilter.class);

    private final MetadataMatcher metadataMatcher;
    private final WebClient.Builder webClientBuilder;

    public MetadataMatcherFilter(MetadataMatcher metadataMatcher, WebClient.Builder webClientBuilder) {
        this.metadataMatcher = metadataMatcher;
        this.webClientBuilder = webClientBuilder;
    }

    public GatewayFilter createFilter(String key, String value, String cloudUrl, String onPremUrl) {
        return (exchange, chain) ->
            metadataMatcher.match(exchange, key, value)
                .flatMap(match -> {
                    String targetUrl = match ? cloudUrl : onPremUrl;
                    URI originalUri = exchange.getRequest().getURI();
                    String fullTargetUri = targetUrl + originalUri.getPath() +
                        (originalUri.getQuery() != null ? "?" + originalUri.getQuery() : "");

                    WebClient client = webClientBuilder.baseUrl(targetUrl).build();

                    logger.debug("Proxying request to: {}", fullTargetUri);

                    return client.method(exchange.getRequest().getMethod())
                        .uri(fullTargetUri)
                        .headers(httpHeaders -> httpHeaders.addAll(exchange.getRequest().getHeaders()))
                        .body((outputMessage, context) -> exchange.getRequest().getBody())
                        .exchangeToMono(response -> {
                            exchange.getResponse().setStatusCode(response.statusCode());
                            exchange.getResponse().getHeaders().putAll(response.headers().asHttpHeaders());
                            return exchange.getResponse().writeWith(response.bodyToFlux(DataBuffer.class));
                        });
                });
    }
}
