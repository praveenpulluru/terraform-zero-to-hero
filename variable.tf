import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.core.Ordered;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

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
            String newPath = "/cases/" + sn + "/MRK/" + filename;

            // Rebuild the request with the new path
            ServerHttpRequest newRequest = exchange.getRequest().mutate()
                    .path(newPath)
                    .build();

            return chain.filter(exchange.mutate().request(newRequest).build());
        }

        return chain.filter(exchange);
    }

    @Override
    public int getOrder() {
        return -1; // Runs before most filters
    }
}




@Bean
public RouteLocator customRouteLocator(RouteLocatorBuilder builder, RewritePathFilter rewritePathFilter) {
    return builder.routes()
            .route("route-put-post-delete-to-cloud",
                    r -> r.path("/trademark/cms/rest/case/*/mark/**")
                            .and()
                            .method(HttpMethod.POST, HttpMethod.PUT)
                            .filters(f -> f
                                    .filter((exchange, chain) -> {
                                        if (shouldRouteToCloud(exchange)) {
                                            return chain.filter(exchange.mutate().request(createCloudRequest(exchange)).build());
                                        }
                                        return chain.filter(exchange);
                                    })
                                    .filter(rewritePathFilter)
                            )
                            .uri(cloudUrl)
            )
            .build();
}

