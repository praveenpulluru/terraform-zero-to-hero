Thanks for sharing the detailed logs — they're very helpful.

---

### ✅ The Core Problem

The error you’re getting is:

> `java.lang.IllegalArgumentException: The path does not have a leading slash:`

This is coming from the Spring Gateway **`rewritePath` filter**, and it's telling us that the **path it's trying to rewrite to is either empty or missing a `/` at the start** — likely because the **filter order or mutated request is interfering with the original path**.

---

### 🔍 What’s Happening

You're conditionally mutating the request URI **before** the `rewritePath` filter is applied:

```java
.filters(f -> f
    .filter((exchange, chain) -> {
        // this gets run first
        ...
        exchange.mutate().request(...) // this breaks the expected URI/path
    })
    .rewritePath(...) // too late, the path is already "lost"
)
```

Once you call `exchange.mutate().request(...)` inside your `filter`, you're replacing the `ServerHttpRequest`, **which resets the path context** that `rewritePath` relies on.

---

### ✅ Solution: Move `rewritePath` manually into your filter logic

Since you need conditional logic based on `metadataMatcher`, and you can't let Spring Gateway handle the path rewrite natively after you've mutated the request, you **must do the path rewrite manually inside your filter**.

---

### ✅ Updated Working Version (No `rewritePath` DSL)

Replace the second route with this:

```java
.route("route-put-mark-documents", r -> r
    .path("/trademark/cms/rest/case/**")
    .and()
    .method("PUT")
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
                        // If path didn't match, just proceed without changes
                        return chain.filter(exchange);
                    }
                }

                return chain.filter(exchange);
            })
    ))
    .uri(cloudUrl)
)
```

---

### ✅ Benefits

* No more `rewritePath(...)` issues.
* Conditional logic based on multipart metadata works correctly.
* Avoids mutating the request in a way that breaks downstream filters.

---

### ✅ Optional: Extract the rewrite logic into a utility if reused

Let me know if you'd like that refactored into a cleaner helper method.

---

Would you also like to conditionally forward non-`mark` requests to `onPremUrl`? I can help wire that into the same route.
