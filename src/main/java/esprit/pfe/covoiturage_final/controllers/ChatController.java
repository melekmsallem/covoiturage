package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.dto.ChatMessageRequest;
import esprit.pfe.covoiturage_final.dto.ChatMessageResponse;
import esprit.pfe.covoiturage_final.dto.GroupChatMessageRequest;
import esprit.pfe.covoiturage_final.dto.GroupChatMessageResponse;
import esprit.pfe.covoiturage_final.dto.TripChatInfo;
import esprit.pfe.covoiturage_final.services.ChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*", maxAge = 3600)
public class ChatController {
    
    @Autowired
    private ChatService chatService;
    
    @PostMapping("/send")
    public ResponseEntity<?> sendMessage(@Valid @RequestBody ChatMessageRequest request) {
        try {
            Long senderId = getCurrentUserId();
            ChatMessageResponse response = chatService.sendMessage(request, senderId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/booking/{bookingId}/messages")
    public ResponseEntity<?> getMessages(@PathVariable Long bookingId) {
        try {
            Long userId = getCurrentUserId();
            List<ChatMessageResponse> messages = chatService.getMessages(bookingId, userId);
            return ResponseEntity.ok(messages);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/booking/{bookingId}/messages/since/{since}")
    public ResponseEntity<?> getMessagesSince(@PathVariable Long bookingId, @PathVariable String since) {
        try {
            Long userId = getCurrentUserId();
            List<ChatMessageResponse> messages = chatService.getMessagesSince(bookingId, userId, since);
            return ResponseEntity.ok(messages);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/booking/{bookingId}/unread-count")
    public ResponseEntity<?> getUnreadCount(@PathVariable Long bookingId) {
        try {
            Long userId = getCurrentUserId();
            Long unreadCount = chatService.getUnreadCount(bookingId, userId);
            return ResponseEntity.ok(Map.of("unreadCount", unreadCount));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }
    
    @PostMapping("/booking/{bookingId}/mark-read")
    public ResponseEntity<?> markMessagesAsRead(@PathVariable Long bookingId) {
        try {
            Long userId = getCurrentUserId();
            chatService.markMessagesAsRead(bookingId, userId);
            return ResponseEntity.ok(Map.of("success", true, "message", "Messages marked as read"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }
    
    // Group chat endpoints
    @PostMapping("/group/send")
    public ResponseEntity<?> sendGroupMessage(@Valid @RequestBody GroupChatMessageRequest request) {
        try {
            Long senderId = getCurrentUserId();
            GroupChatMessageResponse response = chatService.sendGroupMessage(request, senderId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }
    
    @GetMapping("/trip/{tripId}/messages")
    public ResponseEntity<?> getGroupMessages(@PathVariable Long tripId) {
        try {
            Long userId = getCurrentUserId();
            List<GroupChatMessageResponse> messages = chatService.getGroupMessages(tripId, userId);
            return ResponseEntity.ok(messages);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }
    
    @GetMapping("/trip/{tripId}/messages/since/{since}")
    public ResponseEntity<?> getGroupMessagesSince(@PathVariable Long tripId, @PathVariable String since) {
        try {
            Long userId = getCurrentUserId();
            List<GroupChatMessageResponse> messages = chatService.getGroupMessagesSince(tripId, userId, since);
            return ResponseEntity.ok(messages);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }
    
    @GetMapping("/trip/{tripId}/unread-count")
    public ResponseEntity<?> getGroupUnreadCount(@PathVariable Long tripId) {
        try {
            Long userId = getCurrentUserId();
            Long unreadCount = chatService.getGroupUnreadCount(tripId, userId);
            return ResponseEntity.ok(Map.of("unreadCount", unreadCount));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }
    
    @PostMapping("/trip/{tripId}/mark-read")
    public ResponseEntity<?> markGroupMessagesAsRead(@PathVariable Long tripId) {
        try {
            Long userId = getCurrentUserId();
            chatService.markGroupMessagesAsRead(tripId, userId);
            return ResponseEntity.ok(Map.of("success", true, "message", "Group messages marked as read"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }
    
    @GetMapping("/trip/{tripId}/info")
    public ResponseEntity<?> getTripChatInfo(@PathVariable Long tripId) {
        try {
            Long userId = getCurrentUserId();
            TripChatInfo info = chatService.getTripChatInfo(tripId, userId);
            return ResponseEntity.ok(info);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }
    
    @PostMapping("/trip/{tripId}/create")
    public ResponseEntity<?> createOrGetTripChat(@PathVariable Long tripId) {
        try {
            Long userId = getCurrentUserId();
            TripChatInfo info = chatService.createOrGetTripChat(tripId, userId);
            return ResponseEntity.ok(info);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }
    
    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof esprit.pfe.covoiturage_final.entities.User) {
            esprit.pfe.covoiturage_final.entities.User user = (esprit.pfe.covoiturage_final.entities.User) authentication.getPrincipal();
            return user.getId();
        }
        throw new RuntimeException("User not authenticated");
    }
}
