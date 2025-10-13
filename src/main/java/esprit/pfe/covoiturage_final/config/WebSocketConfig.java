package esprit.pfe.covoiturage_final.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // Enable a simple broker for destinations prefixed with "/topic" and "/queue"
        config.enableSimpleBroker("/topic", "/queue");
        // Set application destination prefix to "/app"
        config.setApplicationDestinationPrefixes("/app");
        // Set user destination prefix for user-specific messages
        config.setUserDestinationPrefix("/user");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Register the "/ws" endpoint for WebSocket connections
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")
                .withSockJS();
        
        // Register the "/ws/websocket" endpoint for raw WebSocket connections
        registry.addEndpoint("/ws/websocket")
                .setAllowedOriginPatterns("*");
        
        // Register the "/notifications" endpoint for notification-specific connections
        registry.addEndpoint("/notifications")
                .setAllowedOriginPatterns("*")
                .withSockJS();
    }
}





