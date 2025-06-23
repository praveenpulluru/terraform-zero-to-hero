import org.springframework.web.reactive.function.BodyExtractors;
import org.springframework.http.codec.multipart.FormFieldPart;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.web.server.ServerWebExchange;

import java.util.Map;
import java.util.List;

public class MetadataRoutingFilter implements GatewayFilter {

    private final ObjectMapper objectMapper;

    public MetadataRoutingFilter(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        return exchange.getRequest()
                .getBody() // This is the reactive stream of the request body
                .collectList() // Collect the body into a list of DataBuffer
                .flatMap(dataBuffers -> {
                    // Now we have a list of data buffers. We need to join them into a single byte array
                    DataBuffer combined = dataBuffers.stream()
                            .reduce(exchange.getResponse().bufferFactory().allocateBuffer(), (accumulated, current) -> {
                                // Create a new buffer to accumulate the data
                                DataBuffer newBuffer = accumulated.write(current.asByteBuffer());
                                return newBuffer;
                            });

                    // Process the body as a string (assuming it's JSON)
                    String jsonBody = new String(combined.asByteBuffer().array());

                    // Extract multipart data (metadata + file)
                    return exchange.getRequest()
                            .getBody()
                            .next() // Only extract the first part of the body
                            .flatMap(data -> {
                                // Now, extract multipart data (assuming JSON metadata and files)
                                return exchange.getRequest().getBody()
                                        .map(body -> body.toString())
                                        .flatMap(bodyContent -> {
                                            try {
                                                // Assuming metadata is in JSON format
                                                Map<String, Object> metadata = objectMapper.readValue(bodyContent, Map.class);

                                                // Now store it in exchange attributes
                                                exchange.getAttributes().put("metadata", metadata);
                                            } catch (Exception e) {
                                                return Mono.error(new RuntimeException("Failed to parse JSON", e));
                                            }
                                            return chain.filter(exchange);
                                        });
                            });
                });
    }
}
