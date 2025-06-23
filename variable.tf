2025-06-23T16:51:06.602-04:00[0;39m [32mDEBUG[0;39m [35m33660[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36mo.s.c.g.h.RoutePredicateHandlerMapping  [0;39m [2m:[0;39m [534d6357-1] Mapped to org.springframework.cloud.gateway.handler.FilteringWebHandler@45f9d394
[2m2025-06-23T16:51:06.634-04:00[0;39m [31mERROR[0;39m [35m33660[0;39m [2m--- [hybrid-api] [ctor-http-nio-2] [0;39m[36ma.w.r.e.AbstractErrorWebExceptionHandler[0;39m [2m:[0;39m [534d6357-1]  500 Server Error for HTTP PUT "/trademark/cms/rest/case/76900900/mark/MRK_00.jpg"

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
		at reactor.core.publisher.InternalMonoOperator.subscribe(InternalMonoOperator.java:76) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoDefer.subscribe(MonoDefer.java:53) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoDefer.subscribe(MonoDefer.java:53) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.Mono.subscribe(Mono.java:4576) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoIgnoreThen$ThenIgnoreMain.subscribeNext(MonoIgnoreThen.java:265) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoIgnoreThen.subscribe(MonoIgnoreThen.java:51) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.InternalMonoOperator.subscribe(InternalMonoOperator.java:76) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoDefer.subscribe(MonoDefer.java:53) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoDefer.subscribe(MonoDefer.java:53) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.InternalMonoOperator.subscribe(InternalMonoOperator.java:76) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoDefer.subscribe(MonoDefer.java:53) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.Mono.subscribe(Mono.java:4576) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoIgnoreThen$ThenIgnoreMain.subscribeNext(MonoIgnoreThen.java:265) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoIgnoreThen.subscribe(MonoIgnoreThen.java:51) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.InternalMonoOperator.subscribe(InternalMonoOperator.java:76) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoFlatMap$FlatMapMain.onNext(MonoFlatMap.java:165) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxOnErrorResume$ResumeSubscriber.onNext(FluxOnErrorResume.java:79) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxSwitchIfEmpty$SwitchIfEmptySubscriber.onNext(FluxSwitchIfEmpty.java:74) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoNext$NextSubscriber.onNext(MonoNext.java:82) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxConcatMapNoPrefetch$FluxConcatMapNoPrefetchSubscriber.innerNext(FluxConcatMapNoPrefetch.java:259) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxConcatMap$ConcatMapInner.onNext(FluxConcatMap.java:865) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxMap$MapSubscriber.onNext(FluxMap.java:122) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxSwitchIfEmpty$SwitchIfEmptySubscriber.onNext(FluxSwitchIfEmpty.java:74) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxMap$MapSubscriber.onNext(FluxMap.java:122) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxMap$MapSubscriber.onNext(FluxMap.java:122) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoNext$NextSubscriber.onNext(MonoNext.java:82) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxFilterWhen$FluxFilterWhenSubscriber.drain(FluxFilterWhen.java:302) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxFilterWhen$FluxFilterWhenSubscriber.request(FluxFilterWhen.java:160) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoNext$NextSubscriber.request(MonoNext.java:108) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxMap$MapSubscriber.request(FluxMap.java:164) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxMap$MapSubscriber.request(FluxMap.java:164) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.Operators$MultiSubscriptionSubscriber.request(Operators.java:2331) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxMap$MapSubscriber.request(FluxMap.java:164) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.Operators$MultiSubscriptionSubscriber.request(Operators.java:2331) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxConcatMapNoPrefetch$FluxConcatMapNoPrefetchSubscriber.request(FluxConcatMapNoPrefetch.java:339) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoNext$NextSubscriber.request(MonoNext.java:108) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.Operators$MultiSubscriptionSubscriber.set(Operators.java:2367) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.Operators$MultiSubscriptionSubscriber.onSubscribe(Operators.java:2241) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoNext$NextSubscriber.onSubscribe(MonoNext.java:70) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxConcatMapNoPrefetch$FluxConcatMapNoPrefetchSubscriber.onSubscribe(FluxConcatMapNoPrefetch.java:164) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxIterable.subscribe(FluxIterable.java:201) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.FluxIterable.subscribe(FluxIterable.java:83) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.InternalMonoOperator.subscribe(InternalMonoOperator.java:76) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoDefer.subscribe(MonoDefer.java:53) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.InternalMonoOperator.subscribe(InternalMonoOperator.java:76) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoDefer.subscribe(MonoDefer.java:53) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.Mono.subscribe(Mono.java:4576) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoIgnoreThen$ThenIgnoreMain.subscribeNext(MonoIgnoreThen.java:265) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoIgnoreThen.subscribe(MonoIgnoreThen.java:51) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.InternalMonoOperator.subscribe(InternalMonoOperator.java:76) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.core.publisher.MonoDeferContextual.subscribe(MonoDeferContextual.java:55) ~[reactor-core-3.7.4.jar:3.7.4]
		at reactor.netty.http.server.HttpServer$HttpServerHandle.onStateChange(HttpServer.java:1249) ~[reactor-netty-http-1.2.4.jar:1.2.4]
		at reactor.netty.ReactorNetty$CompositeConnectionObserver.onStateChange(ReactorNetty.java:716) ~[reactor-netty-core-1.2.4.jar:1.2.4]
		at reactor.netty.transport.ServerTransport$ChildObserver.onStateChange(ServerTransport.java:486) ~[reactor-netty-core-1.2.4.jar:1.2.4]
		at reactor.netty.http.server.HttpServerOperations.handleDefaultHttpRequest(HttpServerOperations.java:856) ~[reactor-netty-http-1.2.4.jar:1.2.4]
		at reactor.netty.http.server.HttpServerOperations.onInboundNext(HttpServerOperations.java:782) ~[reactor-netty-http-1.2.4.jar:1.2.4]
		at reactor.netty.channel.ChannelOperationsHandler.channelRead(ChannelOperationsHandler.java:115) ~[reactor-netty-core-1.2.4.jar:1.2.4]
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:444) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:420) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.AbstractChannelHandlerContext.fireChannelRead(AbstractChannelHandlerContext.java:412) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at reactor.netty.http.server.HttpTrafficHandler.channelRead(HttpTrafficHandler.java:272) ~[reactor-netty-http-1.2.4.jar:1.2.4]
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:442) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:420) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.AbstractChannelHandlerContext.fireChannelRead(AbstractChannelHandlerContext.java:412) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.CombinedChannelDuplexHandler$DelegatingChannelHandlerContext.fireChannelRead(CombinedChannelDuplexHandler.java:436) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.handler.codec.ByteToMessageDecoder.fireChannelRead(ByteToMessageDecoder.java:346) ~[netty-codec-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.handler.codec.ByteToMessageDecoder.fireChannelRead(ByteToMessageDecoder.java:333) ~[netty-codec-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.handler.codec.ByteToMessageDecoder.callDecode(ByteToMessageDecoder.java:455) ~[netty-codec-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.handler.codec.ByteToMessageDecoder.channelRead(ByteToMessageDecoder.java:290) ~[netty-codec-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.CombinedChannelDuplexHandler.channelRead(CombinedChannelDuplexHandler.java:251) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:442) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:420) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.AbstractChannelHandlerContext.fireChannelRead(AbstractChannelHandlerContext.java:412) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.DefaultChannelPipeline$HeadContext.channelRead(DefaultChannelPipeline.java:1357) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:440) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:420) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.DefaultChannelPipeline.fireChannelRead(DefaultChannelPipeline.java:868) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.nio.AbstractNioByteChannel$NioByteUnsafe.read(AbstractNioByteChannel.java:166) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.nio.NioEventLoop.processSelectedKey(NioEventLoop.java:796) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.nio.NioEventLoop.processSelectedKeysOptimized(NioEventLoop.java:732) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.nio.NioEventLoop.processSelectedKeys(NioEventLoop.java:658) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.channel.nio.NioEventLoop.run(NioEventLoop.java:562) ~[netty-transport-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.util.concurrent.SingleThreadEventExecutor$4.run(SingleThreadEventExecutor.java:998) ~[netty-common-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.util.internal.ThreadExecutorMap$2.run(ThreadExecutorMap.java:74) ~[netty-common-4.1.119.Final.jar:4.1.119.Final]
		at io.netty.util.concurrent.FastThreadLocalRunnable.run(FastThreadLocalRunnable.java:30) ~[netty-common-4.1.119.Final.jar:4.1.119.Final]
		at java.base/java.lang.Thread.run(Thread.java:1583) ~[na:na]

import java.net.URI;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.web.server.ServerWebExchange;

import gov.uspto.tmcms.gateway.matcher.MetadataMatcher;

@Configuration
public class GatewayRoutesConfig {

	@Value("${services.on-prem-url}")
	private String onPremUrl;

	@Value("${services.cloud-url}")
	private String cloudUrl;

	private static final String on_prem = "on-prem";
	private static final String cloud = "cloud";
	
	private final MetadataMatcher metadataMatcher;

    public GatewayRoutesConfig(MetadataMatcher metadataMatcher) {
        this.metadataMatcher = metadataMatcher;
    }

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
        		.route("route-put-post-delete-to-cloud",
        				r -> r.path("/trademark/cms/rest/case/*/mark/**").and()
        				.method(HttpMethod.POST, HttpMethod.PUT)
        				.filters(f -> f.filter((exchange, chain) -> {
                            if (shouldRouteToCloud(exchange)) {
                                return chain.filter(exchange.mutate().request(createCloudRequest(exchange)).build());
                            }
                            return chain.filter(exchange);
                        }).rewritePath("/trademark/cms/rest/case/(?<sn>\\d{8})\\/(?<doctype>[^/]+)\\/(?<filename>[^/]+)$","/cases/${sn}/MRK/${filename}")
        						)
        				.uri(cloudUrl))

                .route("route-save-as-mark-to-cloud", r -> r.path("/trademark/cms/rest/case/*/mark")
                        .and()
                        .method(HttpMethod.POST)
                        .filters(f -> f.filter((exchange, chain) -> {
                            if (shouldRouteToCloud(exchange)) {
                                return chain.filter(exchange.mutate().request(createCloudRequest(exchange)).build());
                            }
                            return chain.filter(exchange);
                        }))
                        .uri(cloudUrl))
                .build();
    }

    private boolean shouldRouteToCloud(ServerWebExchange exchange) {
        return metadataMatcher.match(exchange, "documentType", "mark");  // Example of matching based on documentType
    }

    private boolean shouldRouteToOnPrem(ServerWebExchange exchange) {
        return metadataMatcher.match(exchange, "sourceMedium", "EMAIL");  // Example of matching based on sourceMedium
    }

    private ServerHttpRequest createCloudRequest(ServerWebExchange exchange) {
        return exchange.getRequest().mutate().uri(URI.create(cloudUrl)).build();
    }

    private ServerHttpRequest createOnPremRequest(ServerWebExchange exchange) {
        return exchange.getRequest().mutate().uri(URI.create(onPremUrl)).build();
    }

}
