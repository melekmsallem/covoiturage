package esprit.pfe.covoiturage_final.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChatMessageRequest {
    
    @NotNull(message = "Booking ID is required")
    private Long bookingId;
    
    @NotBlank(message = "Message cannot be empty")
    private String message;
    
    private String messageType = "TEXT";
}












