Ah, I see! If your request is a **multipart form** with the content being a file and the metadata as a separate part, the approach changes slightly. In this case, you'll need to handle **multipart form data**.

Here’s how we can approach it:

1. **Extract the Metadata**: You'll want to parse the **metadata** object from the multipart form. This metadata is typically sent as a JSON or form data object.
2. **Extract the File**: You'll need to handle the file part as well, since the content is a file (image, PDF, etc.).
3. **Route Based on Metadata**: Once the metadata is extracted, you can use it to decide how to route the request.

### Steps to Handle Multipart Form Data in Spring Cloud Gateway

Spring Cloud Gateway itself doesn’t provide out-of-the-box support for handling multipart form data, so you'll need to write a custom filter to process the multipart body, extract both the file and the metadata, and then route based on the metadata.

### 1. **Create the Metadata Routing Filter for Multipart Form Data**

Here's how you can implement a custom `GatewayFilter` that processes the multipart form and extracts both the **metadata** (as a JSON object) and the **file** (as a part).

```java
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.http.HttpMethod;
import org.springframework.web.reactive.function.BodyExtractors;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.core.io.buffer.DataBufferUtils;
import reactor.core.publisher.Mono;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.http.codec.multipart.FormFieldPart;
import com.fasterxml.jackson.databind.ObjectMapper;

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
                .getBody()
                .flatMap(buffer -> DataBufferUtils.join(buffer)) // Join the body (multipart data)
                .flatMap(dataBuffer -> {
                    // Convert the DataBuffer to a byte array to extract multipart form data
                    byte[] body = new byte[dataBuffer.readableByteCount()];
                    dataBuffer.read(body);
                    DataBufferUtils.release(dataBuffer); // Don't forget to release buffer

                    // Handle the multipart form and extract metadata and file parts
                    return exchange.getRequest()
                            .getMultipartData()
                            .flatMap(parts -> {
                                FormFieldPart metadataPart = (FormFieldPart) parts.get("metadata");
                                if (metadataPart != null) {
                                    String metadataJson = metadataPart.value();
                                    try {
                                        Map<String, Object> metadata = objectMapper.readValue(metadataJson, Map.class);

                                        // Save metadata in the exchange attributes for further routing
                                        exchange.getAttributes().put("metadata", metadata);

                                    } catch (Exception e) {
                                        return Mono.error(new RuntimeException("Failed to parse metadata JSON", e));
                                    }
                                }

                                // Optionally handle the file part if needed
                                List<FilePart> fileParts = (List<FilePart>) parts.get("file");
                                if (fileParts != null && !fileParts.isEmpty()) {
                                    // Process the file part (you can store the file or process it here)
                                    FilePart filePart = fileParts.get(0);
                                    // Do something with the file if necessary
                                }

                                return chain.filter(exchange);
                            });
                });
    }
}
```

### 2. **Modify `RouteLocator` to Handle Multipart Form Data**

Now that your filter processes the metadata and file, you can modify the route configuration to use this filter. The filter will extract the metadata and make it available in the exchange, which you can use for routing.

```java
@Configuration
public class GatewayRoutesConfig {

    @Value("${services.cloud-url}")
    private String cloudUrl;

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("route-put-post-delete-to-cloud", r -> r
                        .path("/trademark/cms/rest/case/**/mark/**")  // Match the dynamic URL path
                        .and()
                        .method(HttpMethod.PUT)
                        .filters(f -> f.filter(new MetadataRoutingFilter(objectMapper)))  // Custom filter to extract metadata
                        .predicate(exchange -> {
                            // Access metadata from the exchange attributes
                            Map<String, Object> metadata = exchange.getAttribute("metadata");

                            // Perform any matching logic based on metadata
                            if (metadata != null && metadata.containsKey("documentType")) {
                                String documentType = (String) metadata.get("documentType");
                                return "mark".equals(documentType);  // Example: match documentType "mark"
                            }

                            return false;
                        })
                        .uri(cloudUrl))  // Route to the cloud URL
                .build();
    }
}
```

### 3. **Multipart Request Example**

Your request should now look something like this:

```http
POST http://localhost:8081/trademark/cms/rest/case/{caseid}/mark/{filename}.jpg
Content-Type: multipart/form-data; boundary=---boundary

---boundary
Content-Disposition: form-data; name="metadata"
Content-Type: application/json

{
    "documentType": "mark",
    "createdBy": "user123",
    "documentAlias": "MRK_001"
}

---boundary
Content-Disposition: form-data; name="file"; filename="MRK_001.jpg"
Content-Type: image/jpeg

... (binary content of the image) ...
---boundary--
```

### Key Considerations:

1. **File Handling**: The filter allows you to access the file part (e.g., `file`), but you may need to do further processing (store it, pass it on to another service, etc.) depending on your requirements.
2. **Metadata Parsing**: The `metadata` part is assumed to be a JSON string. You can adjust this to handle other formats (like key-value pairs) if needed.
3. **Routing Logic**: After parsing the metadata and extracting the file, you can match based on any metadata field. In the example, I used `documentType` to demonstrate routing.

### 4. **Error Handling**:

You might want to handle errors gracefully, such as invalid metadata format or missing parts in the multipart form. Use `Mono.error()` or return custom error responses depending on the issue.

---

### Conclusion

This solution involves reading the multipart form data, extracting both the metadata (as JSON) and the file, and then performing routing decisions based on the extracted metadata.

Let me know if you have any further questions or need more help with this implementation!
