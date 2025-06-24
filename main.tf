[2m2025-06-24T10:35:39.929-04:00[0;39m [32mDEBUG[0;39m [35m21316[0;39m [2m--- [hybrid-api] [ctor-http-nio-3] [0;39m[36mo.s.c.g.h.RoutePredicateHandlerMapping  [0;39m [2m:[0;39m Route matched: route-put-mark-documents
[2m2025-06-24T10:35:39.929-04:00[0;39m [32mDEBUG[0;39m [35m21316[0;39m [2m--- [hybrid-api] [ctor-http-nio-3] [0;39m[36mo.s.c.g.h.RoutePredicateHandlerMapping  [0;39m [2m:[0;39m Mapping [Exchange: PUT http://localhost:8081/trademark/cms/rest/case/76900900/mark/MRK_00.jpg] to Route{id='route-put-mark-documents', uri=https://test.dev.abc.com:443, order=0, predicate=(Paths: [/trademark/cms/rest/case/**], match trailing slash: true && Methods: [PUT]), gatewayFilters=[[gov.uspto.tmcms.gateway.config.GatewayRoutesConfig$$Lambda/0x0000027e964aa700@32d37f0c, order = 0]], metadata={}}
[2m2025-06-24T10:35:39.929-04:00[0;39m [32mDEBUG[0;39m [35m21316[0;39m [2m--- [hybrid-api] [ctor-http-nio-3] [0;39m[36mo.s.c.g.h.RoutePredicateHandlerMapping  [0;39m [2m:[0;39m [aa787f76-2] Mapped to org.springframework.cloud.gateway.handler.FilteringWebHandler@c497a55
[MetadataMatcher] Match result for key 'documentType' = true (value: mark)
[2m2025-06-24T10:35:39.942-04:00[0;39m [32m INFO[0;39m [35m21316[0;39m [2m--- [hybrid-api] [ctor-http-nio-3] [0;39m[36mg.u.tmcms.gateway.filter.LoggingFilter  [0;39m [2m:[0;39m Incoming request Unknown is routed to id: route-put-mark-documents, uri: https://test.dev.abc.com:443/cases/76900900/MRK/MRK_00.jpg
[2m2025-06-24T10:36:40.097-04:00[0;39m [33m WARN[0;39m [35m21316[0;39m [2m--- [hybrid-api] [ctor-http-nio-3] [0;39m[36mr.netty.http.client.HttpClientConnect   [0;39m [2m:[0;39m [0b6c03a6-1, L:/10.192.179.37:61544 ! R:test.dev.abc.com/10.200.11.60:443] The connection observed an error

reactor.netty.http.client.PrematureCloseException: Connection prematurely closed BEFORE response

[2m2025-06-24T10:36:40.098-04:00[0;39m [31mERROR[0;39m [35m21316[0;39m [2m--- [hybrid-api] [ctor-http-nio-3] [0;39m[36ma.w.r.e.AbstractErrorWebExceptionHandler[0;39m [2m:[0;39m [aa787f76-2]  500 Server Error for HTTP PUT "/trademark/cms/rest/case/76900900/mark/MRK_00.jpg"

reactor.netty.http.client.PrematureCloseException: Connection prematurely closed BEFORE response
	Suppressed: reactor.core.publisher.FluxOnAssembly$OnAssemblyException: 
Error has been observed at the following site(s):
	*__checkpoint ⇢ org.springframework.cloud.gateway.filter.WeightCalculatorWebFilter [DefaultWebFilterChain]
	*__checkpoint ⇢ HTTP PUT "/trademark/cms/rest/case/76900900/mark/MRK_00.jpg" [ExceptionHandlingWebHandler]
Original Stack Trace:
