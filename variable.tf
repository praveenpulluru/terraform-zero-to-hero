The error you’re seeing is due to a type mismatch in how the `and()` method is being used in your route configuration.

In Spring Cloud Gateway, the `and()` method in the context of route configuration (like `RouteLocatorBuilder`) is part of the `PredicateSpec` chain and expects a `Predicate<ServerWebExchange>` as the argument. However, you're passing a `MetadataMatcher`, which does not match the expected type.

### Problem

The method `and()` expects a **predicate** to be passed, but you're trying to pass a `MetadataMatcher`, which is a custom class and doesn't directly implement `Predicate<ServerWebExchange>`. The `MetadataMatcher` is likely a utility you created for matching metadata inside the request body, but it isn't directly usable in `and()` without adapting it to fit the required interface.

### Solution

To resolve this, you need to adapt the `MetadataMatcher` to fit into the `PredicateSpec` chain by wrapping it in a **`Predicate<ServerWebExchange>`**.

### Step 1: Modify the `MetadataMatcher`

You can modify the `MetadataMatcher` to make it return a `Predicate<ServerWebExchange>`. Here’s how:

```java
public class MetadataMatcher {

    private String key;
    private String value;

    public MetadataMatcher(String key, String value) {
        this.key = key;
        this.value = value;
    }

    // This method returns a Predicate<ServerWebExchange> so it can be used in the and() method
    public Predicate<ServerWebExchange> toPredicate(Map<String, String> metadata) {
        return exchange -> {
            // Match logic goes here
            // For example, you can access metadata from exchange attributes
            Map<String, Object> metadataFromExchange = exchange.getAttribute("metadata");
            if (metadataFromExchange != null) {
                Object metaValue = metadataFromExchange.get(key);
                return metaValue != null && metaValue.equals(value);
            }
            return false;
        };
    }
}
```

### Step 2: Use the `MetadataMatcher` in the Route Configuration

Now, when you are setting up your routes, you can call `toPredicate()` on your `MetadataMatcher` to convert it into a `Predicate<ServerWebExchange>`:

```java
@Configuration
public class GatewayRoutesConfig {

    @Value("${services.on-prem-url}")
    private String onPremUrl;

    @Value("${services.cloud-url}")
    private String cloudUrl;

    @Bean
    RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                // Example of using MetadataMatcher in a route configuration
                .route("route-all-GET-to-agg-service", r -> r
                        .path("/tdk/cms/rest/**")
                        .and()
                        .method(HttpMethod.GET)
                        .and()
                        // Use MetadataMatcher as a Predicate for routing
                        .predicate(new MetadataMatcher("source", "tm-ns").toPredicate(Map.of("source", "tm-ns")))
                        .uri("http://dummy"))
                .route("route-save-as-mark-to-cloud", r -> r
                        .path("/tdk/cms/rest/case/*/*/*/set-as-mark")
                        .and()
                        .method(HttpMethod.POST)
                        .and()
                        .predicate(new MetadataMatcher("documentType", "officeaction").toPredicate(Map.of("documentType", "officeaction")))
                        .uri(cloudUrl))
                .build();
    }
}
```

### Explanation:

1. **`MetadataMatcher` to Predicate**: I added a `toPredicate()` method inside `MetadataMatcher` that converts it into a `Predicate<ServerWebExchange>`. This allows the matcher to be used directly in the `and()` method.

2. **Using MetadataMatcher in Routing**: Now you can use `new MetadataMatcher("source", "tm-ns").toPredicate(metadata)` in the `and()` method. The `metadata` can be passed as part of the route setup. If needed, you can also retrieve it from the `ServerWebExchange` or any other context.

### Additional Notes:

* **Predicate Logic**: The logic in `toPredicate()` can be modified based on how you want to match the metadata. For example, if the metadata is dynamically fetched from the request body, you'd need to adjust it accordingly.
* **Performance Considerations**: If your metadata is large or complex, ensure that you only store and process what's necessary to avoid memory overhead.

With this solution, you're adapting your custom `MetadataMatcher` into something that fits into Spring Cloud Gateway's reactive and functional routing model.

Let me know if this resolves the issue or if you need any further assistance!
