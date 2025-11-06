package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "chat_messages", indexes = {
    @Index(name = "idx_chat_booking_id", columnList = "booking_id"),
    @Index(name = "idx_chat_trip_chat_id", columnList = "trip_chat_id"),
    @Index(name = "idx_chat_sender_id", columnList = "sender_id"),
    @Index(name = "idx_chat_timestamp", columnList = "timestamp")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChatMessage {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "booking_id", nullable = true)
    private Long bookingId;
    
    @Column(name = "trip_chat_id")
    private Long tripChatId;
    
    @Column(name = "sender_id", nullable = false)
    private Long senderId;
    
    @Column(name = "receiver_id")
    private Long receiverId;
    
    @Column(name = "message", nullable = false, columnDefinition = "TEXT")
    private String message;
    
    @Column(name = "timestamp", nullable = false)
    private LocalDateTime timestamp;
    
    @Column(name = "is_read", nullable = false)
    private Boolean isRead = false;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "message_type", nullable = false)
    private MessageType messageType = MessageType.TEXT;
    
    @PrePersist
    protected void onCreate() {
        timestamp = LocalDateTime.now();
    }
    
    public enum MessageType {
        TEXT, IMAGE, SYSTEM
    }
}



