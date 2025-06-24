package gov.uspto.tmcms.gateway.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.cloud.gateway.support.ServerWebExchangeUtils;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.net.URI;
import java.util.Map;
import java.util.Objects;

@Configuration
public class GatewayRoutesConfig {

    private static final Logger logger = LoggerFactory.getLogger(GatewayRoutesConfig.class);

    private static final String PATH_PATTERN = "/trademark/cms/rest/case/{caseId}/mark/{fileName}";

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
            .route("mark_upload", r -> r
                .path(PATH_PATTERN)
                .and()
                .predicate(exchange -> {
                    // Check metadata manually (from Route's metadata, not available by default in exchange)
                    String documentType = r.getMetadata().get("documentType");
                    boolean match = "mark".equalsIgnoreCase(documentType);
                    logger.debug("[MetadataMatcher] Match result for key 'documentType' = {}", match);
                    return match;
                })
                .filters(f -> f
                    .filter((exchange, chain) -> {
                        URI uri = exchange.getAttribute(ServerWebExchangeUtils.GATEWAY_REQUEST_URL_ATTR);
                        if (uri == null) {
                            logger.error("GATEWAY_REQUEST_URL_ATTR is not available yet");
                            return chain.filter(exchange);
                        }

                        String rawPath = uri.getRawPath();
                        AntPathMatcher matcher = new AntPathMatcher();
                        Map<String, String> pathVariables = matcher.extractUriTemplateVariables(PATH_PATTERN, rawPath);

                        String caseId = pathVariables.get("caseId");
                        String fileName = pathVariables.get("fileName");

                        logger.info("Extracted caseId: {}, fileName: {}", caseId, fileName);

                        exchange.getRequest().mutate()
                            .header("X-Case-Id", caseId)
                            .header("X-File-Name", fileName)
                            .build();

                        return chain.filter(exchange);
                    }, 10100))
                .metadata("documentType", "mark")
                .uri("lb://your-target-service"))
            .build();
    }
}
