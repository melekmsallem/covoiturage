package esprit.pfe.covoiturage_final.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SystemAnnouncementRequest {
    
    private String title;
    private String message;
    private String type; // INFO, WARNING, ERROR, SUCCESS
    private String priority; // LOW, MEDIUM, HIGH, URGENT
    private List<Long> targetUserIds; // null means all users
    private String targetUserType; // ALL, DRIVER, PASSENGER, ADMIN
    private LocalDateTime scheduledTime; // null means immediate
    private LocalDateTime expiryTime;
    private boolean requiresAcknowledgment;
    
    public enum Type {
        INFO("Information"),
        WARNING("Warning"),
        ERROR("Error"),
        SUCCESS("Success"),
        MAINTENANCE("Maintenance"),
        FEATURE_UPDATE("Feature Update");
        
        private final String description;
        
        Type(String description) {
            this.description = description;
        }
        
        public String getDescription() {
            return description;
        }
    }
    
    public enum Priority {
        LOW("Low Priority"),
        MEDIUM("Medium Priority"),
        HIGH("High Priority"),
        URGENT("Urgent");
        
        private final String description;
        
        Priority(String description) {
            this.description = description;
        }
        
        public String getDescription() {
            return description;
        }
    }
}

