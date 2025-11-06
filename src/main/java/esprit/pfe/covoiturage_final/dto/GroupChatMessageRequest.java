package esprit.pfe.covoiturage_final.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GroupChatMessageRequest {
    @NotNull
    private Long tripId;
    
    @NotBlank
    private String message;
    
    private String messageType = "TEXT";
}









