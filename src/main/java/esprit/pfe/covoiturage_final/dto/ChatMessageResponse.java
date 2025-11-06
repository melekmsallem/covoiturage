package esprit.pfe.covoiturage_final.dto;

import esprit.pfe.covoiturage_final.entities.ChatMessage;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChatMessageResponse {
    
    private Long id;
    private Long bookingId;
    private Long senderId;
    private String senderName;
    private String message;
    private LocalDateTime timestamp;
    private Boolean isRead;
    private String messageType;
    
    // User info for display
    private String senderFirstName;
    private String senderLastName;
    private String senderUsername;
}












