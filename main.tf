package gov.uspto.tmcms.gateway.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.cloud.gateway.support.ServerWebExchangeUtils;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.server.PathContainer;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.net.URI;
import java.util.Map;

@Configuration
public class GatewayRoutesConfig {

    private static final Logger logger = LoggerFactory.getLogger(GatewayRoutesConfig.class);

    private static final String PATH_PATTERN = "/trademark/cms/rest/case/{caseId}/mark/{fileName}";

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
            .route("mark_upload", r -> r
                .path("/trademark/cms/rest/case/{caseId}/mark/{fileName}")
                .filters(f -> f.filter((exchange, chain) -> {
                    // Defer logic to after route resolution
                    URI uri = exchange.getAttribute(ServerWebExchangeUtils.GATEWAY_REQUEST_URL_ATTR);
                    if (uri == null) {
                        logger.error("GATEWAY_REQUEST_URL_ATTR is not available yet");
                        return chain.filter(exchange);
                    }

                    String rawPath = uri.getRawPath(); // already encoded
                    AntPathMatcher matcher = new AntPathMatcher();
                    Map<String, String> pathVariables = matcher.extractUriTemplateVariables(PATH_PATTERN, rawPath);

                    String caseId = pathVariables.get("caseId");
                    String fileName = pathVariables.get("fileName");

                    // Do something with caseId or fileName (e.g., set header or log)
                    logger.info("Extracted caseId: {}, fileName: {}", caseId, fileName);

                    // Example: Add to request headers
                    exchange.getRequest().mutate()
                        .header("X-Case-Id", caseId)
                        .header("X-File-Name", fileName)
                        .build();

                    return chain.filter(exchange);
                }, 10100)) // IMPORTANT: Ensure this filter runs AFTER routing
                .uri("lb://your-target-service")) // Replace with your actual service
            .build();
    }
}
