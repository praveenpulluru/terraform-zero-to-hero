.route("route-put-post-delete-to-cloud",
        				r -> r.path("/trademark/cms/rest/case/*/mark/**").and()
        				.method(HttpMethod.POST, HttpMethod.PUT)
        				.filters(f -> f.rewritePath("/trademark/cms/rest/case/(?<sn>\\d{8})\\/(?<doctype>[^/]+)\\/(?<filename>[^/]+)$","/cases/${sn}/MRK/${filename}"))
        				.uri(cloudUrl))

2025-06-24T10:50:09.418-04:00[0;39m [32mDEBUG[0;39m [35m34480[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mo.s.c.g.h.RoutePredicateHandlerMapping  [0;39m [2m:[0;39m Route matched: route-put-post-delete-to-cloud
[2m2025-06-24T10:50:09.421-04:00[0;39m [32mDEBUG[0;39m [35m34480[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mo.s.c.g.h.RoutePredicateHandlerMapping  [0;39m [2m:[0;39m Mapping [Exchange: PUT http://localhost:8081/trademark/cms/rest/case/76900900/mark/MRK_00.jpg] to Route{id='route-put-post-delete-to-cloud', uri=https://test.dev.abc.com:443, order=0, predicate=(Paths: [/trademark/cms/rest/case/*/mark/**], match trailing slash: true && Methods: [POST, PUT]), gatewayFilters=[[[RewritePath /trademark/cms/rest/case/(?<sn>\d{8})\/(?<doctype>[^/]+)\/(?<filename>[^/]+)$ = '/cases/${sn}/MRK/${filename}'], order = 0]], metadata={}}
[2m2025-06-24T10:50:09.421-04:00[0;39m [32mDEBUG[0;39m [35m34480[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mo.s.c.g.h.RoutePredicateHandlerMapping  [0;39m [2m:[0;39m [097aa6e0-1] Mapped to org.springframework.cloud.gateway.handler.FilteringWebHandler@45cd8607
[2m2025-06-24T10:50:09.423-04:00[0;39m [32mDEBUG[0;39m [35m34480[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mo.s.c.g.handler.FilteringWebHandler     [0;39m [2m:[0;39m Sorted gatewayFilterFactories: [[GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.RemoveCachedBodyFilter@61853c7e}, order = -2147483648], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.AdaptCachedBodyGlobalFilter@693f2213}, order = -2147482648], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.NettyWriteResponseFilter@2bfc2f8b}, order = -1], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.ForwardPathFilter@13ca16bf}, order = 0], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.GatewayMetricsFilter@44641d6c}, order = 0], [[RewritePath /trademark/cms/rest/case/(?<sn>\d{8})\/(?<doctype>[^/]+)\/(?<filename>[^/]+)$ = '/cases/${sn}/MRK/${filename}'], order = 0], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.RouteToRequestUrlFilter@32e5af53}, order = 10000], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.config.GatewayNoLoadBalancerClientAutoConfiguration$NoLoadBalancerClientFilter@1ae924f1}, order = 10150], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.WebsocketRoutingFilter@5be4be74}, order = 2147483646], GatewayFilterAdapter{delegate=gov.uspto.tmcms.gateway.filter.LoggingFilter@621624b1}, [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.NettyRoutingFilter@7523d5a1}, order = 2147483647], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.ForwardRoutingFilter@5980fa73}, order = 2147483647]]
[2m2025-06-24T10:50:09.435-04:00[0;39m [32m INFO[0;39m [35m34480[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mg.u.tmcms.gateway.filter.LoggingFilter  [0;39m [2m:[0;39m Incoming request http://localhost:8081/trademark/cms/rest/case/76900900/mark/MRK_00.jpg is routed to id: route-put-post-delete-to-cloud, uri: https://test.dev.abc.com:443/cases/76900900/MRK/MRK_00.jpg
[2m2025-06-24T10:50:09.442-04:00[0;39m [32mDEBUG[0;39m [35m34480[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mg.f.h.o.ObservedRequestHttpHeadersFilter[0;39m [2m:[0;39m Will instrument the HTTP request headers [Accept:"application/json, text/plain, */*", Content-Type:"multipart/form-data; boundary=--------------------------512336768750801785816216", User-Agent:"bruno-runtime/2.1.0", Authorization:"Basic Y21zVG1uZ1NJVDE6Q0BuIUBTIVQyIzIj", request-start-time:"1750776609287", Content-Length:"147335", Accept-Encoding:"gzip, compress, deflate, br", Host:"localhost:8081", Forwarded:"proto=http;host="localhost:8081";for="[0:0:0:0:0:0:0:1]:62602"", X-Forwarded-For:"0:0:0:0:0:0:0:1", X-Forwarded-Proto:"http", X-Forwarded-Port:"8081", X-Forwarded-Host:"localhost:8081"]
[2m2025-06-24T10:50:09.449-04:00[0;39m [32mDEBUG[0;39m [35m34480[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mg.f.h.o.ObservedRequestHttpHeadersFilter[0;39m [2m:[0;39m Client observation  {name=http.client.requests(null), error=null, context=name='http.client.requests', contextualName='null', error='null', lowCardinalityKeyValues=[http.method='PUT', http.status_code='UNKNOWN', spring.cloud.gateway.route.id='route-put-post-delete-to-cloud', spring.cloud.gateway.route.uri='https://test.dev.abc.com:443'], highCardinalityKeyValues=[http.uri='http://localhost:8081/cases/76900900/MRK/MRK_00.jpg'], map=[class io.micrometer.core.instrument.LongTaskTimer$Sample='SampleImpl{duration(seconds)=8.045E-4, duration(nanos)=804500.0, startTimeNanos=10089634032900}', class io.micrometer.core.instrument.Timer$Sample='io.micrometer.core.instrument.Timer$Sample@60fc3495'], parentObservation={name=http.server.requests(null), error=null, context=name='http.server.requests', contextualName='null', error='null', lowCardinalityKeyValues=[exception='none', method='PUT', outcome='SUCCESS', status='200', uri='UNKNOWN'], highCardinalityKeyValues=[http.url='/trademark/cms/rest/case/76900900/mark/MRK_00.jpg'], map=[class io.micrometer.core.instrument.LongTaskTimer$Sample='SampleImpl{duration(seconds)=0.0445788, duration(nanos)=4.45788E7, startTimeNanos=10089590442200}', class io.micrometer.core.instrument.Timer$Sample='io.micrometer.core.instrument.Timer$Sample@79486276'], parentObservation=null}} created for the request. New headers are [Accept:"application/json, text/plain, */*", Content-Type:"multipart/form-data; boundary=--------------------------512336768750801785816216", User-Agent:"bruno-runtime/2.1.0", Authorization:"Basic Y21zVG1uZ1NJVDE6Q0BuIUBTIVQyIzIj", request-start-time:"1750776609287", Content-Length:"147335", Accept-Encoding:"gzip, compress, deflate, br", Host:"localhost:8081", Forwarded:"proto=http;host="localhost:8081";for="[0:0:0:0:0:0:0:1]:62602"", X-Forwarded-For:"0:0:0:0:0:0:0:1", X-Forwarded-Proto:"http", X-Forwarded-Port:"8081", X-Forwarded-Host:"localhost:8081"]
[2m2025-06-24T10:50:10.008-04:00[0;39m [32mDEBUG[0;39m [35m34480[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mr.netty.http.client.HttpClientConnect   [0;39m [2m:[0;39m [82ecfd43-1, L:/10.192.179.37:62604 - R:tmcms.dev.uspto.gov/10.200.11.82:443] Handler is being applied: {uri=https://test.dev.abc.com/cases/76900900/MRK/MRK_00.jpg, method=PUT}
[2m2025-06-24T10:50:11.145-04:00[0;39m [32mDEBUG[0;39m [35m34480[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mr.n.http.client.HttpClientOperations    [0;39m [2m:[0;39m [82ecfd43-1, L:/10.192.179.37:62604 - R:tmcms.dev.uspto.gov/10.200.11.82:443] Received response (auto-read:false) : RESPONSE(decodeResult: success, version: HTTP/1.1)
HTTP/1.1 200 OK
Date: <filtered>
Content-Type: <filtered>
Content-Length: <filtered>
Connection: <filtered>
Vary: <filtered>
[2m2025-06-24T10:50:11.146-04:00[0;39m [32mDEBUG[0;39m [35m34480[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36m.f.h.o.ObservedResponseHttpHeadersFilter[0;39m [2m:[0;39m Will instrument the response
[2m2025-06-24T10:50:11.146-04:00[0;39m [32mDEBUG[0;39m [35m34480[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36m.f.h.o.ObservedResponseHttpHeadersFilter[0;39m [2m:[0;39m The response was handled for observation {name=http.client.requests(null), error=null, context=name='http.client.requests', contextualName='null', error='null', lowCardinalityKeyValues=[http.method='PUT', http.status_code='UNKNOWN', spring.cloud.gateway.route.id='route-put-post-delete-to-cloud', spring.cloud.gateway.route.uri='https://test.dev.abc.com:443'], highCardinalityKeyValues=[http.uri='http://localhost:8081/cases/76900900/MRK/MRK_00.jpg'], map=[class io.micrometer.core.instrument.LongTaskTimer$Sample='SampleImpl{duration(seconds)=1.6978521, duration(nanos)=1.6978521E9, startTimeNanos=10089634032900}', class io.micrometer.core.instrument.Timer$Sample='io.micrometer.core.instrument.Timer$Sample@60fc3495'], parentObservation={name=http.server.requests(null), error=null, context=name='http.server.requests', contextualName='null', error='null', lowCardinalityKeyValues=[exception='none', method='PUT', outcome='SUCCESS', status='200', uri='UNKNOWN'], highCardinalityKeyValues=[http.url='/trademark/cms/rest/case/76900900/mark/MRK_00.jpg'], map=[class io.micrometer.core.instrument.LongTaskTimer$Sample='SampleImpl{duration(seconds)=1.7415418, duration(nanos)=1.7415418E9, startTimeNanos=10089590442200}', class io.micrometer.core.instrument.Timer$Sample='io.micrometer.core.instrument.Timer$Sample@79486276'], parentObservation=null}}
[2m2025-06-24T10:50:11.151-04:00[0;39m [32mDEBUG[0;39m [35m34480[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mr.n.http.client.HttpClientOperations    [0;39m [2m:[0;39m [82ecfd43-1, L:/10.192.179.37:62604 - R:tmcms.dev.uspto.gov/10.200.11.82:443] Received last HTTP packet







.route("route-put-mark-documents", r -> r
        			    .path("/trademark/cms/rest/case/**")
        			    .and()
        			    .method(HttpMethod.POST, HttpMethod.PUT)
        			    .filters(f -> f.filter((exchange, chain) ->
        			        metadataMatcher.matchWithPredicate(exchange, "documentType", val -> "mark".equals(val))
        			            .flatMap(match -> {
        			                if (match) {
        			                    String oldPath = exchange.getRequest().getURI().getPath();
        			                    Matcher matcher = Pattern.compile(
        			                        "/trademark/cms/rest/case/(?<sn>\\d{8})/(?<doctype>[^/]+)/(?<filename>[^/]+)$"
        			                    ).matcher(oldPath);

        			                    if (matcher.find()) {
        			                        String sn = matcher.group("sn");
        			                        String filename = matcher.group("filename");

        			                        String newPath = "/cases/" + sn + "/MRK/" + filename;
        			                        URI newUri = UriComponentsBuilder.fromUri(exchange.getRequest().getURI())
        			                            .replacePath(newPath)
        			                            .build(true)
        			                            .toUri();

        			                        ServerHttpRequest mutatedRequest = exchange.getRequest().mutate()
        			                            .uri(newUri)
        			                            .build();

        			                        return chain.filter(exchange.mutate().request(mutatedRequest).build());
        			                    } else {
        			                        return chain.filter(exchange);
        			                    }
        			                }

        			                return chain.filter(exchange);
        			            })
        			    ))
        			    .uri(cloudUrl)

2025-06-24T10:52:04.781-04:00[0;39m [32mDEBUG[0;39m [35m23396[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mo.s.c.g.h.RoutePredicateHandlerMapping  [0;39m [2m:[0;39m Route matched: route-put-mark-documents
[2m2025-06-24T10:52:04.781-04:00[0;39m [32mDEBUG[0;39m [35m23396[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mo.s.c.g.h.RoutePredicateHandlerMapping  [0;39m [2m:[0;39m Mapping [Exchange: PUT http://localhost:8081/trademark/cms/rest/case/76900900/mark/MRK_00.jpg] to Route{id='route-put-mark-documents', uri=https://test.dev.abc.com:443, order=0, predicate=(Paths: [/trademark/cms/rest/case/**], match trailing slash: true && Methods: [POST, PUT]), gatewayFilters=[[gov.uspto.tmcms.gateway.config.GatewayRoutesConfig$$Lambda/0x000002482c48cb68@b21c985, order = 0]], metadata={}}
[2m2025-06-24T10:52:04.782-04:00[0;39m [32mDEBUG[0;39m [35m23396[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mo.s.c.g.h.RoutePredicateHandlerMapping  [0;39m [2m:[0;39m [76dd77d9-1] Mapped to org.springframework.cloud.gateway.handler.FilteringWebHandler@45f9d394
[2m2025-06-24T10:52:04.782-04:00[0;39m [32mDEBUG[0;39m [35m23396[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mo.s.c.g.handler.FilteringWebHandler     [0;39m [2m:[0;39m Sorted gatewayFilterFactories: [[GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.RemoveCachedBodyFilter@3a209918}, order = -2147483648], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.AdaptCachedBodyGlobalFilter@24e5389c}, order = -2147482648], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.NettyWriteResponseFilter@47a3d56a}, order = -1], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.ForwardPathFilter@6d7b001b}, order = 0], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.GatewayMetricsFilter@da09250}, order = 0], [gov.uspto.tmcms.gateway.config.GatewayRoutesConfig$$Lambda/0x000002482c48cb68@b21c985, order = 0], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.RouteToRequestUrlFilter@2cae5fa7}, order = 10000], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.config.GatewayNoLoadBalancerClientAutoConfiguration$NoLoadBalancerClientFilter@6d31f106}, order = 10150], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.WebsocketRoutingFilter@532dacf5}, order = 2147483646], GatewayFilterAdapter{delegate=gov.uspto.tmcms.gateway.filter.LoggingFilter@3855d9b2}, [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.NettyRoutingFilter@39f42d0e}, order = 2147483647], [GatewayFilterAdapter{delegate=org.springframework.cloud.gateway.filter.ForwardRoutingFilter@34aa8b61}, order = 2147483647]]
[MetadataMatcher] Match result for key 'documentType' = true (value: mark)
[2m2025-06-24T10:52:04.868-04:00[0;39m [32m INFO[0;39m [35m23396[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mg.u.tmcms.gateway.filter.LoggingFilter  [0;39m [2m:[0;39m Incoming request Unknown is routed to id: route-put-mark-documents, uri: https://test.dev.abc.com:443/cases/76900900/MRK/MRK_00.jpg
[2m2025-06-24T10:52:04.875-04:00[0;39m [32mDEBUG[0;39m [35m23396[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mg.f.h.o.ObservedRequestHttpHeadersFilter[0;39m [2m:[0;39m Will instrument the HTTP request headers [Accept:"application/json, text/plain, */*", Content-Type:"multipart/form-data; boundary=--------------------------276710959412599782859860", User-Agent:"bruno-runtime/2.1.0", Authorization:"Basic Y21zVG1uZ1NJVDE6Q0BuIUBTIVQyIzIj", request-start-time:"1750776724637", Content-Length:"147335", Accept-Encoding:"gzip, compress, deflate, br", Host:"localhost:8081", Forwarded:"proto=http;host="localhost:8081";for="[0:0:0:0:0:0:0:1]:62761"", X-Forwarded-For:"0:0:0:0:0:0:0:1", X-Forwarded-Proto:"http", X-Forwarded-Port:"8081", X-Forwarded-Host:"localhost:8081"]
[2m2025-06-24T10:52:04.880-04:00[0;39m [32mDEBUG[0;39m [35m23396[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mg.f.h.o.ObservedRequestHttpHeadersFilter[0;39m [2m:[0;39m Client observation  {name=http.client.requests(null), error=null, context=name='http.client.requests', contextualName='null', error='null', lowCardinalityKeyValues=[http.method='PUT', http.status_code='UNKNOWN', spring.cloud.gateway.route.id='route-put-mark-documents', spring.cloud.gateway.route.uri='https://test.dev.abc.com:443'], highCardinalityKeyValues=[http.uri='http://localhost:8081/cases/76900900/MRK/MRK_00.jpg'], map=[class io.micrometer.core.instrument.LongTaskTimer$Sample='SampleImpl{duration(seconds)=9.233E-4, duration(nanos)=923300.0, startTimeNanos=10205063810600}', class io.micrometer.core.instrument.Timer$Sample='io.micrometer.core.instrument.Timer$Sample@42a5aa10'], parentObservation={name=http.server.requests(null), error=null, context=name='http.server.requests', contextualName='null', error='null', lowCardinalityKeyValues=[exception='none', method='PUT', outcome='SUCCESS', status='200', uri='UNKNOWN'], highCardinalityKeyValues=[http.url='/trademark/cms/rest/case/76900900/mark/MRK_00.jpg'], map=[class io.micrometer.core.instrument.LongTaskTimer$Sample='SampleImpl{duration(seconds)=0.1119302, duration(nanos)=1.119302E8, startTimeNanos=10204953102800}', class io.micrometer.core.instrument.Timer$Sample='io.micrometer.core.instrument.Timer$Sample@780e2012'], parentObservation=null}} created for the request. New headers are [Accept:"application/json, text/plain, */*", Content-Type:"multipart/form-data; boundary=--------------------------276710959412599782859860", User-Agent:"bruno-runtime/2.1.0", Authorization:"Basic Y21zVG1uZ1NJVDE6Q0BuIUBTIVQyIzIj", request-start-time:"1750776724637", Content-Length:"147335", Accept-Encoding:"gzip, compress, deflate, br", Host:"localhost:8081", Forwarded:"proto=http;host="localhost:8081";for="[0:0:0:0:0:0:0:1]:62761"", X-Forwarded-For:"0:0:0:0:0:0:0:1", X-Forwarded-Proto:"http", X-Forwarded-Port:"8081", X-Forwarded-Host:"localhost:8081"]
[2m2025-06-24T10:52:05.517-04:00[0;39m [32mDEBUG[0;39m [35m23396[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mr.netty.http.client.HttpClientConnect   [0;39m [2m:[0;39m [beb9d6ae-1, L:/10.192.179.37:62765 - R:tmcms.dev.uspto.gov/10.200.11.82:443] Handler is being applied: {uri=https://test.dev.abc.com/cases/76900900/MRK/MRK_00.jpg, method=PUT}
[2m2025-06-24T10:53:05.548-04:00[0;39m [33m WARN[0;39m [35m23396[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mr.netty.http.client.HttpClientConnect   [0;39m [2m:[0;39m [beb9d6ae-1, L:/10.192.179.37:62765 ! R:tmcms.dev.uspto.gov/10.200.11.82:443] The connection observed an error

reactor.netty.http.client.PrematureCloseException: Connection prematurely closed BEFORE response

[2m2025-06-24T10:53:05.556-04:00[0;39m [32mDEBUG[0;39m [35m23396[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36m.o.ObservationClosingWebExceptionHandler[0;39m [2m:[0;39m An exception occurred and observation was not previously stopped, will stop it. The exception was [reactor.netty.http.client.PrematureCloseException: Connection prematurely closed BEFORE response]
[2m2025-06-24T10:53:05.570-04:00[0;39m [31mERROR[0;39m [35m23396[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36ma.w.r.e.AbstractErrorWebExceptionHandler[0;39m [2m:[0;39m [76dd77d9-1]  500 Server Error for HTTP PUT "/trademark/cms/rest/case/76900900/mark/MRK_00.jpg"

reactor.netty.http.client.PrematureCloseException: Connection prematurely closed BEFORE response
	Suppressed: reactor.core.publisher.FluxOnAssembly$OnAssemblyException: 
Error has been observed at the following site(s):
	*__checkpoint ⇢ org.springframework.cloud.gateway.filter.WeightCalculatorWebFilter [DefaultWebFilterChain]
	*__checkpoint ⇢ HTTP PUT "/trademark/cms/rest/case/76900900/mark/MRK_00.jpg" [ExceptionHandlingWebHandler]
Original Stack Trace:







