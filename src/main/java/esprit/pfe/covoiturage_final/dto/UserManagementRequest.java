package esprit.pfe.covoiturage_final.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserManagementRequest {
    
    private Long userId;
    private String action; // SUSPEND, ACTIVATE, VERIFY, DELETE
    private String reason;
    private LocalDateTime suspensionEndDate;
    private String adminNotes;
    
    public enum Action {
        SUSPEND("Suspend user account"),
        ACTIVATE("Activate user account"),
        VERIFY("Verify user account"),
        DELETE("Delete user account"),
        RESET_PASSWORD("Reset user password"),
        UPDATE_ROLE("Update user role");
        
        private final String description;
        
        Action(String description) {
            this.description = description;
        }
        
        public String getDescription() {
            return description;
        }
    }
}

