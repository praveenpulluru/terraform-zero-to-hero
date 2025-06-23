.rewritePath("/trademark/cms/rest/case/(?<sn>\\d{8})\\/(?<doctype>[^/]+)\\/(?<filename>[^/]+)$", "/cases/${sn}/MRK/${filename}".startsWith("/") ? "/cases/${sn}/MRK/${filename}" : "/cases/${sn}/MRK/${filename}")
.rewritePath("/trademark/cms/rest/case/(?<sn>\\d{8})\\/(?<doctype>[^/]+)\\/(?<filename>[^/]+)$", "/cases/${sn}/MRK/${filename}")
