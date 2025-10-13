package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Notification;
import java.time.LocalDateTime;
import java.util.List;

public interface NotificationService {
    
    // Notification Management
    Notification createNotification(Long userId, Notification.NotificationType type, String title, String message);
    Notification createNotification(Long userId, Notification.NotificationType type, String title, String message, String relatedEntityType, Long relatedEntityId);
    Notification getNotificationById(Long notificationId);
    List<Notification> getUserNotifications(Long userId);
    List<Notification> getUnreadNotifications(Long userId);
    Long getUnreadCount(Long userId);
    Notification markAsRead(Long notificationId, Long userId);
    void markAllAsRead(Long userId);
    void deleteNotification(Long notificationId, Long userId);
    
    // Real-time Notifications
    void sendRealTimeNotification(Long userId, Notification notification);
    void sendRealTimeNotificationToAll(String message);
    void sendRealTimeNotificationToDrivers(String message);
    void sendRealTimeNotificationToPassengers(String message);
    
    // Email Notifications
    void sendEmailNotification(Notification notification);
    void sendEmailNotification(Long userId, String subject, String body);
    void processPendingEmailNotifications();
    
    // Push Notifications (for future mobile app integration)
    void sendPushNotification(Notification notification);
    void processPendingPushNotifications();
    
    // Specific Notification Types
    void notifyTripCreated(Long driverId, Long tripId, String tripDescription);
    void notifyTripCancelled(Long driverId, List<Long> passengerIds, Long tripId, String reason);
    void notifyBookingCreated(Long driverId, Long passengerId, Long bookingId, Integer seats);
    void notifyBookingConfirmed(Long passengerId, Long bookingId);
    void notifyBookingDeclined(Long passengerId, Long bookingId);
    void notifyBookingCancelled(Long driverId, Long passengerId, Long bookingId, String reason);
    void notifyPaymentPending(Long userId, Long paymentId, Double amount);
    void notifyPaymentCompleted(Long userId, Long paymentId, Double amount);
    void notifyPaymentFailed(Long userId, Long paymentId, String reason);
    void notifyRatingReceived(Long userId, String raterName, Integer rating, String comment);
    
    // Trip Reminders
    void scheduleTripReminder(Long tripId, LocalDateTime reminderTime);
    void processScheduledReminders();
}
