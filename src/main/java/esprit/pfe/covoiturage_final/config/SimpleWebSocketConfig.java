package esprit.pfe.covoiturage_final.config;

import com.fasterxml.jackson.databind.ObjectMapper;
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

        private static final ObjectMapper objectMapper = new ObjectMapper();

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
            
            session.sendMessage(new TextMessage(objectMapper.writeValueAsString(welcomeMessage)));
        }

        @Override
        public void handleMessage(WebSocketSession session, org.springframework.web.socket.WebSocketMessage<?> message) throws Exception {
            System.out.println("WebSocket message received: " + message.getPayload());
            
            try {
                String payload = message.getPayload().toString();
                
                // Try to parse as JSON
                Map<String, Object> receivedMessage = objectMapper.readValue(payload, objectMapper.getTypeFactory().constructMapType(Map.class, String.class, Object.class));
                
                // Check if it's a location update
                if ("location-update".equals(receivedMessage.get("type")) || 
                    receivedMessage.containsKey("userId") && receivedMessage.containsKey("latitude")) {
                    
                    // Broadcast location update to all other sessions
                    receivedMessage.put("type", "location-update");
                    receivedMessage.put("timestamp", LocalDateTime.now().toString());
                    
                    String jsonMessage = objectMapper.writeValueAsString(receivedMessage);
                    
                    // Broadcast to all other sessions
                    sessions.values().forEach(s -> {
                        try {
                            if (s.isOpen() && !s.getId().equals(session.getId())) {
                                s.sendMessage(new TextMessage(jsonMessage));
                            }
                        } catch (IOException e) {
                            System.err.println("Error broadcasting to session: " + e.getMessage());
                        }
                    });
                    
                    System.out.println("Broadcasted location update from user " + receivedMessage.get("userId"));
                } else {
                    // Echo back the message with timestamp
                    Map<String, Object> response = new HashMap<>();
                    response.put("type", "echo");
                    response.put("originalMessage", receivedMessage);
                    response.put("timestamp", LocalDateTime.now().toString());
                    response.put("sessionId", session.getId());
                    
                    session.sendMessage(new TextMessage(objectMapper.writeValueAsString(response)));
                }
            } catch (Exception e) {
                // Not JSON, handle as text
                System.out.println("Handling non-JSON message");
                Map<String, Object> response = new HashMap<>();
                response.put("type", "echo");
                response.put("message", message.getPayload());
                response.put("timestamp", LocalDateTime.now().toString());
                
                session.sendMessage(new TextMessage(objectMapper.writeValueAsString(response)));
            }
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
        try {
            String jsonMessage = new ObjectMapper().writeValueAsString(message);
            TextMessage textMessage = new TextMessage(jsonMessage);
            sessions.values().forEach(session -> {
                try {
                    if (session.isOpen()) {
                        session.sendMessage(textMessage);
                    }
                } catch (IOException e) {
                    System.err.println("Error broadcasting message: " + e.getMessage());
                }
            });
        } catch (Exception e) {
            System.err.println("Error serializing broadcast message: " + e.getMessage());
        }
    }
}


