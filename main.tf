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

                    URI requestUri = exchange.getRequest().getURI();
                    String path = requestUri.getPath();
                    String query = requestUri.getQuery();
                    String fullPath = query != null ? path + "?" + query : path;

                    WebClient webClient = webClientBuilder.baseUrl(targetUrl).build();

                    logger.debug("Proxying to {} with path: {}", match ? "cloud" : "on-prem", fullPath);

                    HttpMethod method = exchange.getRequest().getMethod();
                    if (method == null) {
                        return Mono.error(new IllegalStateException("HTTP method is null"));
                    }

                    return webClient.method(method)
                        .uri(fullPath)
                        .headers(httpHeaders -> {
                            httpHeaders.addAll(exchange.getRequest().getHeaders());
                            httpHeaders.remove(HttpHeaders.HOST); // avoid forwarding host header
                        })
                        .body(BodyInserters.fromDataBuffers(exchange.getRequest().getBody()))
                        .exchange() // instead of exchangeToMono() in older versions
                        .flatMap(clientResponse -> {
                            exchange.getResponse().setStatusCode(clientResponse.statusCode());
                            clientResponse.headers().asHttpHeaders()
                                .forEach((name, values) -> exchange.getResponse().getHeaders().put(name, values));

                            exchange.getResponse().getHeaders().remove(HttpHeaders.TRANSFER_ENCODING);

                            return exchange.getResponse()
                                .writeWith(clientResponse.bodyToFlux(DataBuffer.class));
                        });
                });
    }
}




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

                    URI requestUri = exchange.getRequest().getURI();
                    String path = requestUri.getPath();
                    String query = requestUri.getQuery();
                    String fullPath = query != null ? path + "?" + query : path;

                    WebClient webClient = webClientBuilder.baseUrl(targetUrl).build();

                    logger.debug("Proxying to {} with path: {}", match ? "cloud" : "on-prem", fullPath);

                    HttpMethod method = exchange.getRequest().getMethod();
                    if (method == null) {
                        return Mono.error(new IllegalStateException("HTTP method is null"));
                    }

                    return webClient.method(method)
                        .uri(fullPath)
                        .headers(httpHeaders -> {
                            httpHeaders.addAll(exchange.getRequest().getHeaders());
                            httpHeaders.remove(HttpHeaders.HOST); // optional: avoid Host header conflicts
                        })
                        .body(BodyInserters.fromDataBuffers(exchange.getRequest().getBody()))
                        .exchangeToMono(clientResponse -> {
                            exchange.getResponse().setStatusCode(clientResponse.statusCode());
                            clientResponse.headers().asHttpHeaders()
                                .forEach((name, values) -> exchange.getResponse().getHeaders().put(name, values));

                            // Clean up Transfer-Encoding/Content-Length if needed
                            exchange.getResponse().getHeaders().remove(HttpHeaders.TRANSFER_ENCODING);

                            return exchange.getResponse()
                                .writeWith(clientResponse.bodyToFlux(DataBuffer.class));
                        });
                });
    }
}
