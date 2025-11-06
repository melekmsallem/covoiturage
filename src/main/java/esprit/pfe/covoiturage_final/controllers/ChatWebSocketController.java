package esprit.pfe.covoiturage_final.controllers;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Controller
public class ChatWebSocketController {

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @MessageMapping("/chat/{bookingId}/send")
    @SendTo("/topic/chat/{bookingId}")
    public Map<String, Object> sendChatMessage(Map<String, Object> message, String bookingId) {
        System.out.println("WebSocket chat message received for booking " + bookingId + ": " + message);
        
        Map<String, Object> response = new HashMap<>();
        response.put("type", "NEW_MESSAGE");
        response.put("bookingId", Long.parseLong(bookingId));
        response.put("data", message);
        response.put("timestamp", LocalDateTime.now().toString());
        
        // Send to all subscribers of this booking's chat
        messagingTemplate.convertAndSend("/topic/chat/" + bookingId, response);
        
        return response;
    }

    @MessageMapping("/chat/{bookingId}/join")
    @SendTo("/topic/chat/{bookingId}")
    public Map<String, Object> joinChat(String bookingId) {
        System.out.println("User joined chat for booking " + bookingId);
        
        Map<String, Object> response = new HashMap<>();
        response.put("type", "USER_JOINED");
        response.put("bookingId", Long.parseLong(bookingId));
        response.put("timestamp", LocalDateTime.now().toString());
        
        return response;
    }

    @MessageMapping("/chat/{bookingId}/leave")
    @SendTo("/topic/chat/{bookingId}")
    public Map<String, Object> leaveChat(String bookingId) {
        System.out.println("User left chat for booking " + bookingId);
        
        Map<String, Object> response = new HashMap<>();
        response.put("type", "USER_LEFT");
        response.put("bookingId", Long.parseLong(bookingId));
        response.put("timestamp", LocalDateTime.now().toString());
        
        return response;
    }
}










