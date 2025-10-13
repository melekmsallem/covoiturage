package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    
    List<Notification> findByUserId(Long userId);
    
    List<Notification> findByUserIdAndStatus(Long userId, Notification.NotificationStatus status);
    
    List<Notification> findByUserIdOrderByCreatedAtDesc(Long userId);
    
    List<Notification> findByType(Notification.NotificationType type);
    
    List<Notification> findByStatus(Notification.NotificationStatus status);
    
    List<Notification> findByCreatedAtBetween(LocalDateTime startDate, LocalDateTime endDate);
    
    @Query("SELECT n FROM Notification n WHERE n.userId = :userId AND n.status = 'UNREAD' ORDER BY n.createdAt DESC")
    List<Notification> findUnreadByUserId(@Param("userId") Long userId);
    
    @Query("SELECT COUNT(n) FROM Notification n WHERE n.userId = :userId AND n.status = 'UNREAD'")
    Long countUnreadByUserId(@Param("userId") Long userId);
    
    @Query("SELECT n FROM Notification n WHERE n.relatedEntityType = :entityType AND n.relatedEntityId = :entityId")
    List<Notification> findByRelatedEntity(@Param("entityType") String entityType, @Param("entityId") Long entityId);
    
    @Query("SELECT n FROM Notification n WHERE n.isEmailSent = false AND n.createdAt < :threshold")
    List<Notification> findPendingEmailNotifications(@Param("threshold") LocalDateTime threshold);
    
    @Query("SELECT n FROM Notification n WHERE n.isPushSent = false AND n.createdAt < :threshold")
    List<Notification> findPendingPushNotifications(@Param("threshold") LocalDateTime threshold);
    
    // Admin dashboard methods
    Long countByStatus(Notification.NotificationStatus status);
    Long countByCreatedAtAfter(LocalDateTime date);
}





