package esprit.pfe.covoiturage_final.controllers;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Controller
public class WebSocketController {

    @MessageMapping("/hello")
    @SendTo("/topic/greetings")
    public Map<String, Object> greeting(Map<String, Object> message) {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Hello from WebSocket!");
        response.put("timestamp", LocalDateTime.now().toString());
        response.put("received", message);
        return response;
    }

    @MessageMapping("/test")
    @SendTo("/topic/test")
    public Map<String, Object> test() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "WebSocket connection is working!");
        response.put("timestamp", LocalDateTime.now().toString());
        return response;
    }

    @MessageMapping("/chat")
    @SendTo("/topic/public")
    public Map<String, Object> chat(Map<String, Object> message) {
        Map<String, Object> response = new HashMap<>();
        response.put("type", "echo");
        response.put("message", "Echo: " + message.get("content"));
        response.put("sender", message.get("sender"));
        response.put("timestamp", LocalDateTime.now().toString());
        response.put("original", message);
        return response;
    }

    @MessageMapping("/trip-updates")
    @SendTo("/topic/trip-updates")
    public Map<String, Object> tripUpdates(Map<String, Object> message) {
        Map<String, Object> response = new HashMap<>();
        response.put("type", "trip-update");
        response.put("message", "Trip update received: " + message.get("content"));
        response.put("timestamp", LocalDateTime.now().toString());
        return response;
    }

    @MessageMapping("/booking-updates")
    @SendTo("/topic/booking-updates")
    public Map<String, Object> bookingUpdates(Map<String, Object> message) {
        Map<String, Object> response = new HashMap<>();
        response.put("type", "booking-update");
        response.put("message", "Booking update received: " + message.get("content"));
        response.put("timestamp", LocalDateTime.now().toString());
        return response;
    }
}


