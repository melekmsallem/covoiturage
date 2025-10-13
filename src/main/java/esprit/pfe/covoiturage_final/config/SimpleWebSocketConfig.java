package esprit.pfe.covoiturage_final.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Configuration
@EnableWebSocket
public class SimpleWebSocketConfig implements WebSocketConfigurer {

    private static final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(new SimpleWebSocketHandler(), "/ws")
                .setAllowedOriginPatterns("*");
    }

    public static class SimpleWebSocketHandler implements WebSocketHandler {

        @Override
        public void afterConnectionEstablished(WebSocketSession session) throws Exception {
            sessions.put(session.getId(), session);
            System.out.println("WebSocket connection established: " + session.getId());
            
            // Send welcome message
            Map<String, Object> welcomeMessage = new HashMap<>();
            welcomeMessage.put("type", "welcome");
            welcomeMessage.put("message", "Connected to Carpooling WebSocket!");
            welcomeMessage.put("timestamp", LocalDateTime.now().toString());
            welcomeMessage.put("sessionId", session.getId());
            
            session.sendMessage(new TextMessage(welcomeMessage.toString()));
        }

        @Override
        public void handleMessage(WebSocketSession session, org.springframework.web.socket.WebSocketMessage<?> message) throws Exception {
            System.out.println("WebSocket message received: " + message.getPayload());
            
            // Echo back the message with timestamp
            Map<String, Object> response = new HashMap<>();
            response.put("type", "echo");
            response.put("originalMessage", message.getPayload());
            response.put("timestamp", LocalDateTime.now().toString());
            response.put("sessionId", session.getId());
            
            session.sendMessage(new TextMessage(response.toString()));
        }

        @Override
        public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
            System.out.println("WebSocket transport error: " + exception.getMessage());
            sessions.remove(session.getId());
        }

        @Override
        public void afterConnectionClosed(WebSocketSession session, org.springframework.web.socket.CloseStatus closeStatus) throws Exception {
            System.out.println("WebSocket connection closed: " + session.getId());
            sessions.remove(session.getId());
        }

        @Override
        public boolean supportsPartialMessages() {
            return false;
        }
    }

    // Utility method to broadcast messages to all connected sessions
    public static void broadcastMessage(Map<String, Object> message) {
        TextMessage textMessage = new TextMessage(message.toString());
        sessions.values().forEach(session -> {
            try {
                if (session.isOpen()) {
                    session.sendMessage(textMessage);
                }
            } catch (IOException e) {
                System.err.println("Error broadcasting message: " + e.getMessage());
            }
        });
    }
}


