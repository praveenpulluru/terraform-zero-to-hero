package gov.uspto.tmcms.gateway.matcher;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.type.TypeReference;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.Predicate;

@Component
public class MetadataMatcher {

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Match metadata value using a custom predicate function.
     * Note: this method returns a Mono<Boolean> because reading the body is async.
     *
     * @param exchange       the current server exchange
     * @param property       the metadata property key
     * @param valuePredicate the predicate to evaluate the property's value
     * @return Mono<Boolean> if the metadata matches
     */
    public Mono<Boolean> matchWithPredicate(ServerWebExchange exchange, String property, Predicate<Object> valuePredicate) {
        return extractMetadataFromRequest(exchange)
            .map(metadata -> {
                if (metadata.containsKey(property)) {
                    return valuePredicate.test(metadata.get(property));
                }
                return false;
            })
            .onErrorReturn(false); // Return false in case of parsing error
    }

    /**
     * Extracts metadata from JSON request body.
     * Assumes JSON object in the format:
     * {
     *   "documentName": "MRK_00.jpg",
     *   "documentAlias": "mark",
     *   "createdByUserId": "eFile",
     *   "accessLevel": "public",
     *   "documentType": "mark",
     *   "docCode": "MRK"
     * }
     *
     * @param exchange the current exchange
     * @return Mono<Map<String, Object>> containing the parsed metadata
     */
    private Mono<Map<String, Object>> extractMetadataFromRequest(ServerWebExchange exchange) {
        if (!MediaType.APPLICATION_JSON.isCompatibleWith(exchange.getRequest().getHeaders().getContentType())) {
            return Mono.just(Map.of()); // Not JSON; return empty metadata
        }

        return exchange.getRequest().getBody()
            .reduce(new StringBuilder(), (builder, dataBuffer) -> {
                byte[] bytes = new byte[dataBuffer.readableByteCount()];
                dataBuffer.read(bytes);
                builder.append(new String(bytes, StandardCharsets.UTF_8));
                return builder;
            })
            .map(StringBuilder::toString)
            .flatMap(body -> {
                try {
                    Map<String, Object> metadata = objectMapper.readValue(body, new TypeReference<>() {});
                    return Mono.just(metadata);
                } catch (Exception e) {
                    return Mono.error(new RuntimeException("Failed to parse JSON metadata", e));
                }
            });
    }
}




.filters(f -> f.filter((exchange, chain) -> 
    metadataMatcher.matchWithPredicate(exchange, "documentType", val -> val.equals("mark"))
        .flatMap(match -> {
            if (match) {
                return chain.filter(exchange.mutate().request(createCloudRequest(exchange)).build());
            }
            return chain.filter(exchange);
        })
))
