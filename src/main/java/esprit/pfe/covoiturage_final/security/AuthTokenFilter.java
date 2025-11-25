package esprit.pfe.covoiturage_final.security;

import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.services.UserDetailsServiceImpl;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

public class AuthTokenFilter extends OncePerRequestFilter {
    private final JwtUtils jwtUtils;

    private final UserDetailsServiceImpl userDetailsService;

    public AuthTokenFilter(JwtUtils jwtUtils, UserDetailsServiceImpl userDetailsService) {
        this.jwtUtils = jwtUtils;
        this.userDetailsService = userDetailsService;
    }

    private static final Logger LOGGER = LoggerFactory.getLogger(AuthTokenFilter.class);

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String jwt = parseJwt(request);
            LOGGER.debug("Request URI: {}, JWT extracted: {}", request.getRequestURI(), jwt != null);
            
            if (jwt != null && jwtUtils.validateJwtToken(jwt)) {
                String usernameOrEmail = jwtUtils.getUserNameFromJwtToken(jwt);
                if (usernameOrEmail != null) {
                    usernameOrEmail = usernameOrEmail.trim();
                }

                LOGGER.debug("JWT token extracted username: {}", usernameOrEmail);

                try {
                    UserDetails userDetails = userDetailsService.loadUserByUsername(usernameOrEmail);
                    LOGGER.debug("UserDetails loaded for username: {}, user ID: {}", usernameOrEmail, ((User) userDetails).getId());
                    UsernamePasswordAuthenticationToken authentication =
                            new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                    SecurityContextHolder.getContext().setAuthentication(authentication);
                    LOGGER.debug("Authentication set successfully for user: {}", usernameOrEmail);
                } catch (Exception e) {
                    LOGGER.error("Cannot set user authentication for subject: {}", usernameOrEmail, e);
                }
            } else {
                LOGGER.warn("JWT validation failed or no JWT found for URI: {}", request.getRequestURI());
            }
        } catch (Exception e) {
            LOGGER.error("Cannot set user authentication: {}", e);
        }

        filterChain.doFilter(request, response);
    }

    private String parseJwt(HttpServletRequest request) {
        String headerAuth = request.getHeader("Authorization");

        if (StringUtils.hasText(headerAuth) && headerAuth.startsWith("Bearer ")) {
            return headerAuth.substring(7);
        }

        return null;
    }
}