2025-06-23T16:56:40.222-04:00[0;39m [32mDEBUG[0;39m [35m12780[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mo.s.c.g.h.RoutePredicateHandlerMapping  [0;39m [2m:[0;39m Route matched: route-put-post-delete-to-cloud
[2m2025-06-23T16:56:40.226-04:00[0;39m [32mDEBUG[0;39m [35m12780[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mo.s.c.g.h.RoutePredicateHandlerMapping  [0;39m [2m:[0;39m Mapping [Exchange: PUT http://localhost:8081/trademark/cms/rest/case/76900900/mark/MRK_00.jpg] to Route{id='route-put-post-delete-to-cloud', uri=https://test.dev.tttt.tt:443, order=0, predicate=(Paths: [/trademark/cms/rest/case/*/mark/**], match trailing slash: true && Methods: [POST, PUT]), gatewayFilters=[[gov.uspto.tmcms.gateway.config.GatewayRoutesConfig$$Lambda/0x000001e84c48add0@7822fa85, order = 0], [[RewritePath /trademark/cms/rest/case/(?<sn>\d{8})\/(?<doctype>[^/]+)\/(?<filename>[^/]+)$ = '/cases/${sn}/MRK/${filename}'], order = 0]], metadata={}}
[2m2025-06-23T16:56:40.226-04:00[0;39m [32mDEBUG[0;39m [35m12780[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mo.s.c.g.h.RoutePredicateHandlerMapping  [0;39m [2m:[0;39m [ec6e5f49-1] Mapped to org.springframework.cloud.gateway.handler.FilteringWebHandler@6ba6557e
[2m2025-06-23T16:56:40.256-04:00[0;39m [31mERROR[0;39m [35m12780[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36ma.w.r.e.AbstractErrorWebExceptionHandler[0;39m [2m:[0;39m [ec6e5f49-1]  500 Server Error for HTTP PUT "/trademark/cms/rest/case/76900900/mark/MRK_00.jpg"

java.lang.IllegalArgumentException: The path does not have a leading slash: 
	at org.springframework.util.Assert.isTrue(Assert.java:135) ~[spring-core-6.2.5.jar:6.2.5]
	Suppressed: reactor.core.publisher.FluxOnAssembly$OnAssemblyException: 
Error has been observed at the following site(s):
	*__checkpoint ⇢ org.springframework.cloud.gateway.filter.WeightCalculatorWebFilter [DefaultWebFilterChain]
	*__checkpoint ⇢ HTTP PUT "/trademark/cms/rest/case/76900900/mark/MRK_00.jpg" [ExceptionHandlingWebHandler]
Original Stack Trace:
		at org.springframework.util.Assert.isTrue(Assert.java:135) ~[spring-core-6.2.5.jar:6.2.5]
		at org.springframework.http.server.reactive.DefaultServerHttpRequestBuilder.path(DefaultServerHttpRequestBuilder.java:102) ~[spring-web-6.2.5.jar:6.2.5]
		at org.springframework.cloud.gateway.filter.factory.RewritePathGatewayFilterFactory$1.filter(RewritePathGatewayFilterFactory.java:72) ~[spring-cloud-gateway-server-4.2.1.jar:4.2.1]
		at org.springframework.cloud.gateway.filter.OrderedGatewayFilter.filter(OrderedGatewayFilter.java:44) ~[spring-cloud-gateway-server-4.2.1.jar:4.2.1]
		at org.springframework.cloud.gateway.handler.FilteringWebHandler$DefaultGatewayFilterChain.lambda$filter$0(FilteringWebHandler.java:158) ~[spring-cloud-gateway-server-4.2.1.jar:4.2.1]
		at reactor.core.publisher.MonoDefer.subscribe(MonoDefer.java:45) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoDefer.subscribe(MonoDefer.java:53) ~[reactor-core-3.7.4.jar:3.7.4]
