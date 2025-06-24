.filters(f -> f.filter((exchange, chain) -> {
    String path = exchange.getRequest().getPath().toString();
    AntPathMatcher matcher = new AntPathMatcher();
    Map<String, String> variables = matcher.extractUriTemplateVariables(PATH_PATTERN, path);

    String caseId = variables.get("caseId");
    String fileName = variables.get("fileName");

    if (!fileName.startsWith("MRK_")) {
        logger.warn("Rejecting upload: fileName '{}' does not start with 'MRK_'", fileName);
        exchange.getResponse().setStatusCode(HttpStatus.BAD_REQUEST);
        return exchange.getResponse().setComplete();
    }

    logger.info("Accepted file upload for caseId={}, fileName={}", caseId, fileName);

    exchange.getRequest().mutate()
        .header("X-Case-Id", caseId)
        .header("X-File-Name", fileName)
        .build();

    return chain.filter(exchange);
}, 10100))










@Component
public class DocumentTypeRoutePredicateFactory extends AbstractRoutePredicateFactory<DocumentTypeRoutePredicateFactory.Config> {

    public DocumentTypeRoutePredicateFactory() {
        super(Config.class);
    }

    @Override
    public Predicate<ServerWebExchange> apply(Config config) {
        return exchange -> {
            String path = exchange.getRequest().getPath().toString();
            return path.contains("/" + config.documentType + "/");
        };
    }

    public static class Config {
        private String documentType;

        public String getDocumentType() {
            return documentType;
        }

        public void setDocumentType(String documentType) {
            this.documentType = documentType;
        }
    }
}



.route("mark_upload", r -> r
    .path(PATH_PATTERN)
    .predicate(new DocumentTypeRoutePredicateFactory().apply(c -> c.setDocumentType("mark")))
    .filters(...)
    .uri(...))
