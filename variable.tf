.filter(new RewritePathGatewayFilterFactory()
    .apply(config -> config.setRegexp("/old/(?<segment>.*)").setReplacement("/new/${segment}")))
