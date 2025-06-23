import org.springframework.cloud.gateway.route.PredicateSpec;
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
    public boolean match(Map<String, String> metadata) {
        return metadata.containsKey(key) && metadata.get(key).equals(value);
    }

    // Static method that returns a Predicate<ServerWebExchange> for use in route configuration
    public static Predicate<ServerWebExchange> createPredicate(String key, String value) {
        return exchange -> {
            // Retrieve metadata from the exchange (e.g., headers or custom attributes)
            Map<String, String> metadata = getMetadataFromExchange(exchange);

            // Create an instance of MetadataMatcher and check if it matches
            MetadataMatcher matcher = new MetadataMatcher(key, value);
            return matcher.match(metadata);  // Return the result of the match
        };
    }

    // Example method to extract metadata from the exchange (customize as needed)
    private static Map<String, String> getMetadataFromExchange(ServerWebExchange exchange) {
        // Extract metadata from headers or request attributes
        return exchange.getRequest().getHeaders().toSingleValueMap(); // Example (customize this)
    }
}


### Explanation

* **`createPredicate(String key, String value)`**: This static method creates a `PredicateSpec` that checks if the metadata matches the key-value pair using `MetadataMatcher`.
* **`getMetadataFromExchange(ServerWebExchange exchange)`**: This method extracts metadata from the `ServerWebExchange`. You can customize this method to extract metadata from any part of the exchange (e.g., headers, query parameters, attributes).
* **Predicate**: The lambda expression now checks if the metadata in the exchange matches the given `key` and `value`.

### Usage in `RouteLocator`

Now, you can use this in your route configuration:

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
        PredicateSpec tmNsPredicate = MetadataMatcher.createPredicate("source", "tm-ns");
        PredicateSpec officeActionPredicate = MetadataMatcher.createPredicate("documentType", "officeaction");

        return builder.routes()
                .route("route-all-GET-to-agg-service", r -> r
                        .path("/tdk/cms/rest/**")
                        .and()
                        .method(HttpMethod.GET)
                        .and(tmNsPredicate) // Apply dynamic match for "source=tm-ns"
                        .filters(f -> f.filter(new CustomAggregationFilter(WebClient.builder(), onPremUrl, cloudUrl, "on-prem", "cloud")))
                        .uri("http://dummy"))

                .route("route-save-as-mark-to-cloud", r -> r
                        .path("/tdk/cms/rest/case/*/*/*/set-as-mark")
                        .and()
                        .method(HttpMethod.POST)
                        .and(officeActionPredicate) // Apply dynamic match for "documentType=officeaction"
                        .filters(f -> f.rewritePath("/tdk/cms/rest/case/(?<sn>\\d{8})\\/(?<doctype>[^/]+)\\/(?<filename>[^/]+)\\/set-as-mark", "/cases/${sn}/${doctype}/${filename}/set-as-mark"))
                        .uri(cloudUrl))

                // Add more routes as needed...
                .build();
    }
}
```

### Key Changes:

* **`MetadataMatcher.createPredicate`** now returns a **functional predicate** that Spring Cloud Gateway can use directly in your routes.
* **`getMetadataFromExchange`** is responsible for extracting metadata from the `ServerWebExchange`. This part is customizable based on how you're passing the metadata in the request.

### Conclusion

The main issue was that `PredicateSpec` requires a functional interface, and you were trying to return a lambda that didn't fit that signature. Now, `MetadataMatcher` creates a valid **predicate** that works with the Spring Cloud Gateway routing system.

Let me know if this resolves your issue or if you need further clarification!


Ah, I see! You want to create a more flexible and dynamic routing system where you can easily reuse the `MetadataMatcher` for different criteria (e.g., checking a source or document type). The idea is to avoid hardcoding specific properties in each route definition, and instead, allow your routing logic to use metadata matching dynamically.

Let's break this down into a more reusable solution where `MetadataMatcher` can accept different matching conditions for each route.

### Step 1: Update `MetadataMatcher`

We will modify the `MetadataMatcher` class so that it can match metadata based on dynamic key-value pairs. This will allow for more flexible usage (e.g., "source" = "tm-ns", or "documentType" = "officeaction").

```java
import java.util.Map;

public class MetadataMatcher {

    private String key;
    private String value;

    // Constructor to match any given key-value pair
    public MetadataMatcher(String key, String value) {
        this.key = key;
        this.value = value;
    }

    // The match method checks if the metadata contains the key-value pair
    public boolean match(Map<String, String> metadata) {
        return metadata.containsKey(key) && metadata.get(key).equals(value);
    }

    // Static method to match dynamically and return a PredicateSpec for use in the routes
    public static PredicateSpec createPredicate(Map<String, String> metadata, String key, String value) {
        return exchange -> {
            MetadataMatcher matcher = new MetadataMatcher(key, value);
            return matcher.match(metadata);
        };
    }
}
```

Here’s how it works:

* The `MetadataMatcher` class now holds a `key` and a `value`, which it checks in the metadata.
* The `match` method checks if the metadata has a specific key-value pair.
* The static `createPredicate` method is designed to be used directly in the route configuration to dynamically create matching predicates for routing.

### Step 2: Integrate `MetadataMatcher` with the Route Configuration

Now, we can integrate this `MetadataMatcher` logic directly into your route configuration. You can pass different key-value pairs for different routes dynamically.

Here’s how you can adjust your route definitions:

```java
@Configuration
public class GatewayRoutesConfig {

    @Value("${services.on-prem-url}")
    private String onPremUrl;

    @Value("${services.cloud-url}")
    private String cloudUrl;

    private static final String on_prem = "on-prem";
    private static final String cloud = "cloud";

    @Bean
    RouteLocator customRouteLocator(RouteLocatorBuilder builder) {

        // Route for "source" = "tm-ns"
        PredicateSpec tmNsPredicate = MetadataMatcher.createPredicate(Map.of("source", "tm-ns"));

        // Route for "documentType" = "officeaction"
        PredicateSpec officeActionPredicate = MetadataMatcher.createPredicate(Map.of("documentType", "officeaction"));

        return builder.routes()
                .route("route-all-GET-to-agg-service", r -> r
                        .path("/tdk/cms/rest/**")
                        .and()
                        .method(HttpMethod.GET)
                        .and(tmNsPredicate) // Apply the dynamic "tm-ns" match here
                        .filters(f -> f.filter(new CustomAggregationFilter(WebClient.builder(), onPremUrl, cloudUrl, on_prem, cloud)))
                        .uri("http://dummy"))

                // Route for "documentType" = "officeaction"
                .route("route-save-as-mark-to-cloud",
                        r -> r.path("/tdk/cms/rest/case/*/*/*/set-as-mark")
                                .and()
                                .method(HttpMethod.POST)
                                .and(officeActionPredicate) // Apply the dynamic "officeaction" match here
                                .filters(f -> f.rewritePath("/tdk/cms/rest/case/(?<sn>\\d{8})\\/(?<doctype>[^/]+)\\/(?<filename>[^/]+)\\/set-as-mark", "/cases/${sn}/${doctype}/${filename}/set-as-mark"))
                                .uri(cloudUrl))

                // Add other routes as needed...
                .build();
    }
}
```

### Step 3: Adjust the Route Configuration Logic

You can now use `MetadataMatcher` with different key-value pairs dynamically. The `PredicateSpec` allows you to compose multiple matching conditions using the `.and()` operator, and you can easily add conditions for different keys (e.g., `source`, `documentType`, etc.).

For example:

* For the first route, we're using a condition where the metadata must have `source="tm-ns"`.
* For the second route, we're checking if the `documentType="officeaction"`.

The route configuration becomes very modular and reusable.

### Key Concepts Here:

1. **`MetadataMatcher.createPredicate()`**: This static method allows you to create flexible predicates for different key-value pairs in the metadata. You can use this in any route to dynamically check whether the metadata matches the criteria.
2. **`PredicateSpec`**: This is the powerful Spring Cloud Gateway mechanism that allows for route matching conditions. By passing the `PredicateSpec` returned from `MetadataMatcher.createPredicate()`, you ensure that the route is only triggered if the metadata condition is satisfied.

### Step 4: Extending and Improving

If you want to improve this, you can extend `MetadataMatcher` to support more complex conditions, like matching multiple keys (e.g., both `source="tm-ns"` **and** `documentType="officeaction"`), or even using regular expressions or other complex matching rules.

For example, to match both `source="tm-ns"` **and** `documentType="officeaction"`:

```java
public static PredicateSpec createPredicate(Map<String, String> metadata, String key1, String value1, String key2, String value2) {
    return exchange -> {
        MetadataMatcher matcher1 = new MetadataMatcher(key1, value1);
        MetadataMatcher matcher2 = new MetadataMatcher(key2, value2);
        return matcher1.match(metadata) && matcher2.match(metadata);
    };
}
```

This gives you a lot of flexibility in defining dynamic and reusable route conditions based on your metadata structure.

---

Does this align more with what you're looking to achieve?
