public class MetadataMatcher {

    // Method to match metadata property (this can be modified to match based on any property dynamically)
    public static boolean matchMetadata(Map<String, Object> metadata, String matchProperty) {
        return metadata.containsKey(matchProperty) && metadata.get(matchProperty) != null;
    }
}
@Configuration
public class GatewayRoutesConfig {

    @Value("${services.on-prem-url}")
    private String onPremUrl;

    @Value("${services.cloud-url}")
    private String cloudUrl;

    private static final String on_prem = "on-prem";
    private static final String cloud = "cloud";

    @Value("${metadata.property.match}")
    private String metadataPropertyToMatch; // Property to match in metadata

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                // Route POST, PUT, DELETE to Cloud or On-Prem based on Metadata
                .route("route-post-put-delete-dynamic",
                        r -> r.path("/tdk/cms/rest/**")
                                .and()
                                .method(HttpMethod.POST, HttpMethod.PUT, HttpMethod.DELETE)
                                .filters(f -> f.filter(new MetadataRoutingFilter(onPremUrl, cloudUrl, metadataPropertyToMatch)))
                                .uri("http://dummy")) // dummy uri just to match the route
                .build();
    }
}
