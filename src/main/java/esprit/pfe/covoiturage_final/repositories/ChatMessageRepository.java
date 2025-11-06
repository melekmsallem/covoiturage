package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {
    
    // Individual chat methods (booking-based)
    List<ChatMessage> findByBookingIdOrderByTimestampAsc(Long bookingId);
    
    List<ChatMessage> findByBookingIdAndSenderIdOrderByTimestampAsc(Long bookingId, Long senderId);
    
    @Query("SELECT COUNT(c) FROM ChatMessage c WHERE c.bookingId = :bookingId AND c.senderId != :userId AND c.isRead = false")
    Long countUnreadMessages(@Param("bookingId") Long bookingId, @Param("userId") Long userId);
    
    @Query("SELECT c FROM ChatMessage c WHERE c.bookingId = :bookingId AND c.timestamp > :since ORDER BY c.timestamp ASC")
    List<ChatMessage> findMessagesSince(@Param("bookingId") Long bookingId, @Param("since") LocalDateTime since);
    
    @Query("SELECT c FROM ChatMessage c WHERE c.bookingId = :bookingId AND c.senderId != :userId AND c.isRead = false ORDER BY c.timestamp ASC")
    List<ChatMessage> findUnreadMessages(@Param("bookingId") Long bookingId, @Param("userId") Long userId);
    
    @Modifying
    @Transactional
    @Query("UPDATE ChatMessage c SET c.isRead = true WHERE c.bookingId = :bookingId AND c.senderId != :userId")
    void markMessagesAsRead(@Param("bookingId") Long bookingId, @Param("userId") Long userId);
    
    // Group chat methods (trip-based)
    List<ChatMessage> findByTripChatIdOrderByTimestampAsc(Long tripChatId);
    
    @Query("SELECT COUNT(c) FROM ChatMessage c WHERE c.tripChatId = :tripChatId AND c.senderId != :userId AND c.isRead = false")
    Long countUnreadGroupMessages(@Param("tripChatId") Long tripChatId, @Param("userId") Long userId);
    
    @Query("SELECT c FROM ChatMessage c WHERE c.tripChatId = :tripChatId AND c.timestamp > :since ORDER BY c.timestamp ASC")
    List<ChatMessage> findGroupMessagesSince(@Param("tripChatId") Long tripChatId, @Param("since") LocalDateTime since);
    
    @Query("SELECT c FROM ChatMessage c WHERE c.tripChatId = :tripChatId AND c.senderId != :userId AND c.isRead = false ORDER BY c.timestamp ASC")
    List<ChatMessage> findUnreadGroupMessages(@Param("tripChatId") Long tripChatId, @Param("userId") Long userId);
    
    @Modifying
    @Transactional
    @Query("UPDATE ChatMessage c SET c.isRead = true WHERE c.tripChatId = :tripChatId AND c.senderId != :userId")
    void markGroupMessagesAsRead(@Param("tripChatId") Long tripChatId, @Param("userId") Long userId);
}


