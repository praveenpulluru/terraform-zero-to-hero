package gov.uspto.tmcms.gateway.matcher;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;
import java.util.function.Predicate;

@Component
public class MetadataMatcher {

    private final ObjectMapper objectMapper = new ObjectMapper();

    public boolean matchWithPredicate(HttpServletRequest request, String property, Predicate<Object> predicate) {
        Map<String, Object> metadata = extractMetadataFromRequest(request);
        return metadata.containsKey(property) && predicate.test(metadata.get(property));
    }

    private Map<String, Object> extractMetadataFromRequest(HttpServletRequest request) {
        if (!(request instanceof MultipartHttpServletRequest multipartRequest)) {
            return Map.of();
        }

        MultipartFile metadataPart = multipartRequest.getFile("metadata");
        if (metadataPart == null) {
            return Map.of();
        }

        try {
            return objectMapper.readValue(metadataPart.getInputStream(), new TypeReference<>() {});
        } catch (IOException e) {
            throw new RuntimeException("Failed to parse metadata JSON", e);
        }
    }
}
package gov.uspto.tmcms.gateway.filter;

import gov.uspto.tmcms.gateway.matcher.MetadataMatcher;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.IOException;

@Component
public class MetadataRoutingFilter extends OncePerRequestFilter {

    private final MetadataMatcher metadataMatcher;

    public MetadataRoutingFilter(MetadataMatcher metadataMatcher) {
        this.metadataMatcher = metadataMatcher;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
        throws ServletException, IOException {

        String originalPath = request.getRequestURI();

        if ("PUT".equalsIgnoreCase(request.getMethod()) &&
                originalPath.matches("^/trademark/cms/rest/case/\\d{8}/[^/]+/[^/]+$") &&
                metadataMatcher.matchWithPredicate(request, "documentType", val -> "mark".equals(val))) {

            // Extract SN and filename
            String[] parts = originalPath.split("/");
            String sn = parts[5];
            String filename = parts[7];

            String newPath = "/cases/" + sn + "/MRK/" + filename;

            // Forward the request to new path
            request.getRequestDispatcher(newPath).forward(request, response);
            return;
        }

        filterChain.doFilter(request, response);
    }
}
