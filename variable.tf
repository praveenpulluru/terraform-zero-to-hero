import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.core.io.buffer.DataBufferUtils;
import org.springframework.http.codec.multipart.Part;
import org.springframework.http.codec.multipart.FormFieldPart;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.function.Predicate;

@Component
public class MetadataMatcher {

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Match metadata value using a custom predicate function.
     * @param exchange       the current server exchange
     * @param property       the metadata property key
     * @param valuePredicate the predicate to evaluate the property's value
     * @return Mono<Boolean> if the metadata matches
     */
    public Mono<Boolean> matchWithPredicate(ServerWebExchange exchange, String property, Predicate<Object> valuePredicate) {
        return extractMetadataFromRequest(exchange)
            .map(metadata -> metadata.containsKey(property) && valuePredicate.test(metadata.get(property)))
            .onErrorResume(ex -> {
                // log or handle error if needed
                return Mono.just(false);
            });
    }

    /**
     * Extracts metadata from a multipart request with a field named "metadata".
     * Assumes "metadata" is a JSON string part in the multipart body.
     */
    private Mono<Map<String, Object>> extractMetadataFromRequest(ServerWebExchange exchange) {
        if (!exchange.getRequest().getHeaders().getContentType().toString().startsWith("multipart/form-data")) {
            return Mono.just(Map.of());
        }

        return exchange.getMultipartData()
            .flatMap(parts -> {
                Part part = parts.getFirst("metadata"); // expecting field named "metadata"
                if (part instanceof FormFieldPart formFieldPart) {
                    String json = formFieldPart.value();
                    try {
                        Map<String, Object> metadata = objectMapper.readValue(json, new TypeReference<>() {});
                        return Mono.just(metadata);
                    } catch (Exception e) {
                        return Mono.error(new RuntimeException("Failed to parse multipart metadata JSON", e));
                    }
                } else {
                    return Mono.just(Map.of()); // metadata part not found or not text
                }
            });
    }
}
