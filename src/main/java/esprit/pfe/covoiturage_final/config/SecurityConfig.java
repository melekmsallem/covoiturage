package esprit.pfe.covoiturage_final.config;

import esprit.pfe.covoiturage_final.security.AuthTokenFilter;
import esprit.pfe.covoiturage_final.services.UserDetailsServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.boot.autoconfigure.security.servlet.PathRequest;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.core.annotation.Order;

import java.util.Arrays;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {
    @Autowired
    UserDetailsServiceImpl userDetailsService;

    @Bean
    public AuthTokenFilter authenticationJwtTokenFilter() {
        return new AuthTokenFilter();
    }

    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();

        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());

        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth ->
                auth
                    // Admin login page (explicit)
                    .requestMatchers("/admin-login.html").permitAll()
                    
                    // Admin dashboard - temporarily allow access for debugging
                    .requestMatchers("/admin-dashboard.html").permitAll()
                    .requestMatchers("/admin-dashboard-new.html").permitAll()
                    .requestMatchers("/admin-dashboard-fixed.html").permitAll()
                    
                    // Static resources
                    .requestMatchers("/js/**").permitAll()
                    .requestMatchers("/css/**").permitAll()
                    .requestMatchers("/images/**").permitAll()
                    .requestMatchers("/static/**").permitAll()
                    .requestMatchers("/favicon.ico").permitAll()
                    
                    // Test pages
                    .requestMatchers("/test-admin.html", "/backend-test.html", "/auth-test.html", "/login-test.html", "/websocket-test.html").permitAll()

                    // Public APIs
                    .requestMatchers("/api/auth/**").permitAll()
                    .requestMatchers("/api/public/**").permitAll()
                    .requestMatchers("/api/options/**").permitAll()
                    .requestMatchers("/api/cities/**").permitAll()
                    .requestMatchers("/api/trips/available").permitAll()
                    .requestMatchers("/api/trips/search").permitAll()
                    .requestMatchers("/api/trip-creation/form-data").permitAll()
                    .requestMatchers("/api/trip-creation/validate").permitAll()
                    .requestMatchers("/api/trip-creation/estimate").permitAll()
                    .requestMatchers("/api/trip-creation/debug-estimate").permitAll()
                    .requestMatchers("/api/users/check-username/**").permitAll()
                    .requestMatchers("/api/users/check-email/**").permitAll()
                    .requestMatchers("/api/car-models/**").permitAll()
                    .requestMatchers("/api/test/**").permitAll()
                    .requestMatchers("/api/dashboard-test/**").permitAll()
                    .requestMatchers("/api/simple/**").permitAll()

                    // Stripe payment endpoints and static callback pages
                    .requestMatchers("/api/stripe/**").permitAll()
                    .requestMatchers("/static/**").permitAll()
                    .requestMatchers("/payment-success.html", "/payment-cancel.html").permitAll()

                    // Admin auth APIs - Allow login/signup without authentication
                    .requestMatchers("/api/admin/auth/**").permitAll()

                    // Admin APIs - temporarily allow access for debugging
                    .requestMatchers("/api/admin/**").permitAll()
                    
                    // File upload endpoints
                    .requestMatchers("/api/files/**").permitAll()
                    
                    // Migration APIs - allow access for database migration
                    .requestMatchers("/api/migration/**").permitAll()

                    // Protected APIs
                    .requestMatchers("/api/trip-creation/create").authenticated()
                    // Note: Other trip-creation endpoints are handled above with permitAll()
                    // Dashboard: expose debug-auth only, protect the rest
                    .requestMatchers("/api/dashboard/debug-auth").permitAll()
                    .requestMatchers("/api/dashboard/**").authenticated()

                    // Other dev utilities
                    .requestMatchers("/api/websocket/**").permitAll()
                    .requestMatchers("/ws/**").permitAll()
                    .requestMatchers("/notifications/**").permitAll()
                    .requestMatchers("/h2-console/**").permitAll()

                    .anyRequest().authenticated()
            );

        http.authenticationProvider(authenticationProvider());
        http.addFilterBefore(authenticationJwtTokenFilter(), UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(Arrays.asList("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("authorization", "content-type", "x-auth-token"));
        configuration.setExposedHeaders(Arrays.asList("x-auth-token"));
        configuration.setAllowCredentials(false);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
