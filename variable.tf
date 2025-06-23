Got it! If the metadata you're looking for is part of the **request payload** (the body) rather than the headers, then extracting metadata from the request headers isn't going to work. Since you're dealing with a POST/PUT request where the metadata is in the body, you will need to extract that information from the request **payload** instead.

### Key Steps for Accessing Metadata in Request Body:

1. **Read the Request Body**: The metadata will be part of the request body, so you’ll need to read and parse the body before extracting the metadata.

2. **Deserialize the Payload**: You need to deserialize the payload (usually JSON or XML) into a suitable object or map that contains the metadata.

3. **Access Metadata**: Once the payload is deserialized, you can access the metadata properties and use them for routing decisions.

### Solution

You’ll need to extract the body of the request in a way that doesn’t block the flow of the gateway, since the request body is typically read once. For this, Spring Cloud Gateway provides a mechanism to read the body asynchronously and provide it for use in filters or predicates.

#### 1. **Creating an Async Filter for Reading the Request Body**

You can create an asynchronous filter that will read the request body, deserialize it, and make the metadata available for your `MetadataMatcher`.

Here’s how you can do this:

### Code Example

#### a. **Create a Filter to Extract Metadata from the Request Body**

```java
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.reactive.function.BodyExtractors;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.Map;

public class MetadataRoutingFilter implements GatewayFilter {

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        // Read the body as JSON (for example, assuming metadata is in a JSON structure)
        return exchange.getRequest().getBody()
                .collectList() // Collect the body into a list of data
                .flatMap(data -> {
                    // Concatenate the list into a single byte array
                    byte[] body = data.stream()
                            .reduce(new byte[0], (a, b) -> {
                                byte[] combined = new byte[a.length + b.length];
                                System.arraycopy(a, 0, combined, 0, a.length);
                                System.arraycopy(b, 0, combined, a.length, b.length);
                                return combined;
                            });

                    // Assuming the body is JSON, parse it into a Map (or custom object)
                    String jsonBody = new String(body);
                    Map<String, Object> metadata = parseJsonToMap(jsonBody);

                    // Store metadata for later use
                    exchange.getAttributes().put("metadata", metadata);

                    // Continue with the filter chain
                    return chain.filter(exchange);
                });
    }

    // Helper method to parse the JSON string into a Map (or any custom object)
    private Map<String, Object> parseJsonToMap(String json) {
        // Use a library like Jackson or Gson to parse the JSON body
        // Here's a simple example using Jackson (you could also use Gson or another library):
        ObjectMapper objectMapper = new ObjectMapper();
        try {
            return objectMapper.readValue(json, Map.class);
        } catch (Exception e) {
            throw new RuntimeException("Failed to parse JSON", e);
        }
    }
}
```

#### b. **Create the Predicate to Match the Metadata**

Now that the metadata is available in the `ServerWebExchange` attributes, you can write a `Predicate<ServerWebExchange>` to match the metadata:

```java
import org.springframework.web.server.ServerWebExchange;
import java.util.Map;
import java.util.function.Predicate;

public class MetadataMatcher {

    private String key;
    private String value;

    public MetadataMatcher(String key, String value) {
        this.key = key;
        this.value = value;
    }

    // Method to match metadata
    public boolean match(Map<String, Object> metadata) {
        return metadata.containsKey(key) && metadata.get(key).equals(value);
    }

    // Static method that returns a Predicate<ServerWebExchange> for use in route configuration
    public static Predicate<ServerWebExchange> createPredicate(String key, String value) {
        return exchange -> {
            // Retrieve metadata from the exchange (attributes, set in filter)
            Map<String, Object> metadata = (Map<String, Object>) exchange.getAttribute("metadata");

            // If metadata is null or not available, return false
            if (metadata == null) {
                return false;
            }

            // Create an instance of MetadataMatcher and check if it matches
            MetadataMatcher matcher = new MetadataMatcher(key, value);
            return matcher.match(metadata);  // Return the result of the match
        };
    }
}
```

#### c. **Configure the Filter and Route**

Finally, in your `RouteLocator` configuration, you can use the `MetadataRoutingFilter` to read the body and the `MetadataMatcher.createPredicate` to match the metadata.

```java
@Configuration
public class GatewayRoutesConfig {

    @Value("${services.on-prem-url}")
    private String onPremUrl;

    @Value("${services.cloud-url}")
    private String cloudUrl;

    @Bean
    RouteLocator customRouteLocator(RouteLocatorBuilder builder) {

        // Use MetadataMatcher to create predicates for different keys/values
        Predicate<ServerWebExchange> tmNsPredicate = MetadataMatcher.createPredicate("source", "tm-ns");
        Predicate<ServerWebExchange> officeActionPredicate = MetadataMatcher.createPredicate("documentType", "officeaction");

        return builder.routes()
                .route("route-all-GET-to-agg-service", r -> r
                        .path("/tdk/cms/rest/**")
                        .and()
                        .method(HttpMethod.GET)
                        .and(tmNsPredicate) // Apply dynamic match for "source=tm-ns"
                        .filters(f -> f.filter(new MetadataRoutingFilter())) // Add filter to read request body
                        .uri("http://dummy"))

                .route("route-save-as-mark-to-cloud", r -> r
                        .path("/tdk/cms/rest/case/*/*/*/set-as-mark")
                        .and()
                        .method(HttpMethod.POST)
                        .and(officeActionPredicate) // Apply dynamic match for "documentType=officeaction"
                        .filters(f -> f.filter(new MetadataRoutingFilter())) // Add filter to read request body
                        .uri(cloudUrl))

                // Add more routes as needed...
                .build();
    }
}
```

### Explanation:

1. **Reading Request Body**: The `MetadataRoutingFilter` reads the body of the request asynchronously. The request body is expected to be in JSON format.

2. **Deserialization**: The `parseJsonToMap` method is used to convert the JSON string into a `Map<String, Object>`, which contains the metadata you want to match.

3. **Predicate Matching**: The `MetadataMatcher.createPredicate` method checks if the metadata matches the specified key-value pair.

4. **Adding Filter**: The `MetadataRoutingFilter` is added to the route to extract and parse the metadata before applying the predicate.

### Additional Notes:

* You may want to handle **content types** like `application/json` or `application/x-www-form-urlencoded`, depending on what the client sends.
* Be sure to handle any edge cases, like large payloads, empty bodies, etc.
* This solution assumes you're using **JSON**. If you're using other formats (like XML or custom formats), you’ll need to modify the deserialization logic accordingly.

Let me know if this works for you or if you need further assistance!
