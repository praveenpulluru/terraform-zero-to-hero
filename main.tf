import static org.springframework.cloud.gateway.support.ServerWebExchangeUtils.GATEWAY_REQUEST_URL_ATTR;

import java.net.URI;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

.route("route-put-mark-documents", r -> r
    .path("/trademark/cms/rest/case/**")
    .and()
    .method(HttpMethod.POST, HttpMethod.PUT)
    .filters(f -> f.filter((exchange, chain) ->
        metadataMatcher.matchWithPredicate(exchange, "documentType", val -> "mark".equals(val))
            .flatMap(match -> {
                if (match) {
                    String oldPath = exchange.getRequest().getURI().getPath();
                    Matcher matcher = Pattern.compile(
                        "/trademark/cms/rest/case/(?<sn>\\d{8})/(?<doctype>[^/]+)/(?<filename>[^/]+)$"
                    ).matcher(oldPath);

                    if (matcher.find()) {
                        String sn = matcher.group("sn");
                        String filename = matcher.group("filename");

                        // Build the new path only
                        String newPath = "/cases/" + sn + "/MRK/" + filename;

                        // Replace only the path part of the original URI
                        URI originalUri = exchange.getRequiredAttribute(GATEWAY_REQUEST_URL_ATTR);
                        URI newUri = UriComponentsBuilder.fromUri(originalUri)
                            .replacePath(newPath)
                            .build(true)
                            .toUri();

                        // Safely update the GATEWAY_REQUEST_URL_ATTR (preferred way to mutate route)
                        exchange.getAttributes().put(GATEWAY_REQUEST_URL_ATTR, newUri);

                        return chain.filter(exchange);
                    }
                }

                return chain.filter(exchange);
            })
    ))
    .uri(cloudUrl)
)
