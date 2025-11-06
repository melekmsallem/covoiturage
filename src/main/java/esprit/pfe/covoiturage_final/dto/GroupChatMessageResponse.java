package esprit.pfe.covoiturage_final.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GroupChatMessageResponse {
    private Long id;
    private Long tripId;
    private Long tripChatId;
    private Long senderId;
    private String message;
    private LocalDateTime timestamp;
    private Boolean isRead;
    private String messageType;
    private String senderName;
    private String senderType; // "DRIVER" or "PASSENGER"
}









