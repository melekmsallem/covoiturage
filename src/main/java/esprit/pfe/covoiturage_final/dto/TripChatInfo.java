package esprit.pfe.covoiturage_final.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TripChatInfo {
    private Long id;
    private Long tripId;
    private String tripRoute; // e.g., "Tunis → Sfax"
    private LocalDateTime createdAt;
    private Boolean isActive;
    private List<ParticipantInfo> participants;
    private Long unreadCount;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ParticipantInfo {
        private Long userId;
        private String firstName;
        private String lastName;
        private String userType; // "DRIVER" or "PASSENGER"
        private Boolean isOnline;
    }
}









