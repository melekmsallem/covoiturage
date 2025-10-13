package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Notification;
import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.repositories.NotificationRepository;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
// WebSocket messaging will be implemented later
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
@Transactional
public class NotificationServiceImpl implements NotificationService {
    
    @Autowired
    private NotificationRepository notificationRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    // WebSocket messaging will be implemented later
    
    @Autowired
    private EmailService emailService;
    
    @Override
    public Notification createNotification(Long userId, Notification.NotificationType type, String title, String message) {
        return createNotification(userId, type, title, message, null, null);
    }
    
    @Override
    public Notification createNotification(Long userId, Notification.NotificationType type, String title, String message, String relatedEntityType, Long relatedEntityId) {
        Notification notification = new Notification();
        notification.setUserId(userId);
        notification.setType(type);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setRelatedEntityType(relatedEntityType);
        notification.setRelatedEntityId(relatedEntityId);
        notification.setStatus(Notification.NotificationStatus.UNREAD);
        
        final Notification savedNotification = notificationRepository.save(notification);
        
        // Send real-time notification
        sendRealTimeNotification(userId, savedNotification);
        
        // Schedule email notification (async)
        CompletableFuture.runAsync(() -> sendEmailNotification(savedNotification));
        
        return savedNotification;
    }
    
    @Override
    public Notification getNotificationById(Long notificationId) {
        return notificationRepository.findById(notificationId)
            .orElseThrow(() -> new RuntimeException("Notification not found"));
    }
    
    @Override
    public List<Notification> getUserNotifications(Long userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }
    
    @Override
    public List<Notification> getUnreadNotifications(Long userId) {
        return notificationRepository.findUnreadByUserId(userId);
    }
    
    @Override
    public Long getUnreadCount(Long userId) {
        return notificationRepository.countUnreadByUserId(userId);
    }
    
    @Override
    public Notification markAsRead(Long notificationId, Long userId) {
        Notification notification = notificationRepository.findById(notificationId)
            .orElseThrow(() -> new RuntimeException("Notification not found"));
        
        if (!notification.getUserId().equals(userId)) {
            throw new RuntimeException("You can only mark your own notifications as read");
        }
        
        notification.setStatus(Notification.NotificationStatus.READ);
        notification.setReadAt(LocalDateTime.now());
        
        return notificationRepository.save(notification);
    }
    
    @Override
    public void markAllAsRead(Long userId) {
        List<Notification> unreadNotifications = notificationRepository.findUnreadByUserId(userId);
        for (Notification notification : unreadNotifications) {
            notification.setStatus(Notification.NotificationStatus.READ);
            notification.setReadAt(LocalDateTime.now());
        }
        notificationRepository.saveAll(unreadNotifications);
    }
    
    @Override
    public void deleteNotification(Long notificationId, Long userId) {
        Notification notification = notificationRepository.findById(notificationId)
            .orElseThrow(() -> new RuntimeException("Notification not found"));
        
        if (!notification.getUserId().equals(userId)) {
            throw new RuntimeException("You can only delete your own notifications");
        }
        
        notificationRepository.delete(notification);
    }
    
    @Override
    public void sendRealTimeNotification(Long userId, Notification notification) {
        // WebSocket messaging will be implemented later
        System.out.println("Real-time notification sent to user " + userId + ": " + notification.getTitle());
    }
    
    @Override
    public void sendRealTimeNotificationToAll(String message) {
        // WebSocket messaging will be implemented later
        System.out.println("System announcement: " + message);
    }
    
    @Override
    public void sendRealTimeNotificationToDrivers(String message) {
        // WebSocket messaging will be implemented later
        System.out.println("Driver announcement: " + message);
    }
    
    @Override
    public void sendRealTimeNotificationToPassengers(String message) {
        // WebSocket messaging will be implemented later
        System.out.println("Passenger announcement: " + message);
    }
    
    @Override
    public void sendEmailNotification(Notification notification) {
        User user = userRepository.findById(notification.getUserId()).orElse(null);
        if (user != null && user.getEmail() != null) {
            emailService.sendNotificationEmail(user.getEmail(), notification.getTitle(), notification.getMessage());
            notification.setIsEmailSent(true);
            notificationRepository.save(notification);
        }
    }
    
    @Override
    public void sendEmailNotification(Long userId, String subject, String body) {
        User user = userRepository.findById(userId).orElse(null);
        if (user != null && user.getEmail() != null) {
            emailService.sendNotificationEmail(user.getEmail(), subject, body);
        }
    }
    
    @Override
    public void processPendingEmailNotifications() {
        LocalDateTime threshold = LocalDateTime.now().minusMinutes(5);
        List<Notification> pendingNotifications = notificationRepository.findPendingEmailNotifications(threshold);
        
        for (Notification notification : pendingNotifications) {
            sendEmailNotification(notification);
        }
    }
    
    @Override
    public void sendPushNotification(Notification notification) {
        // TODO: Implement push notification service (Firebase, etc.)
        notification.setIsPushSent(true);
        notificationRepository.save(notification);
    }
    
    @Override
    public void processPendingPushNotifications() {
        LocalDateTime threshold = LocalDateTime.now().minusMinutes(5);
        List<Notification> pendingNotifications = notificationRepository.findPendingPushNotifications(threshold);
        
        for (Notification notification : pendingNotifications) {
            sendPushNotification(notification);
        }
    }
    
    // Specific Notification Types Implementation
    @Override
    public void notifyTripCreated(Long driverId, Long tripId, String tripDescription) {
        createNotification(
            driverId,
            Notification.NotificationType.TRIP_CREATED,
            "Trip Created Successfully",
            "Your trip '" + tripDescription + "' has been created and is now available for booking.",
            "TRIP",
            tripId
        );
    }
    
    @Override
    public void notifyTripCancelled(Long driverId, List<Long> passengerIds, Long tripId, String reason) {
        // Notify driver
        createNotification(
            driverId,
            Notification.NotificationType.TRIP_CANCELLED,
            "Trip Cancelled",
            "Your trip has been cancelled. Reason: " + reason,
            "TRIP",
            tripId
        );
        
        // Notify all passengers
        for (Long passengerId : passengerIds) {
            createNotification(
                passengerId,
                Notification.NotificationType.TRIP_CANCELLED,
                "Trip Cancelled",
                "The trip you booked has been cancelled. Reason: " + reason,
                "TRIP",
                tripId
            );
        }
    }
    
    @Override
    public void notifyBookingCreated(Long driverId, Long passengerId, Long bookingId, Integer seats) {
        createNotification(
            driverId,
            Notification.NotificationType.BOOKING_CREATED,
            "New Booking Request",
            "You have a new booking request for " + seats + " seat(s).",
            "BOOKING",
            bookingId
        );
    }
    
    @Override
    public void notifyBookingConfirmed(Long passengerId, Long bookingId) {
        createNotification(
            passengerId,
            Notification.NotificationType.BOOKING_CONFIRMED,
            "Booking Confirmed",
            "Your booking has been confirmed by the driver.",
            "BOOKING",
            bookingId
        );
    }
    
    @Override
    public void notifyBookingDeclined(Long passengerId, Long bookingId) {
        createNotification(
            passengerId,
            Notification.NotificationType.BOOKING_CANCELLED,
            "Booking Declined",
            "Your booking has been declined by the driver.",
            "BOOKING",
            bookingId
        );
    }
    
    @Override
    public void notifyBookingCancelled(Long driverId, Long passengerId, Long bookingId, String reason) {
        if (driverId != null) {
            createNotification(
                driverId,
                Notification.NotificationType.BOOKING_CANCELLED,
                "Booking Cancelled",
                "A passenger has cancelled their booking. Reason: " + reason,
                "BOOKING",
                bookingId
            );
        }
        
        if (passengerId != null) {
            createNotification(
                passengerId,
                Notification.NotificationType.BOOKING_CANCELLED,
                "Booking Cancelled",
                "Your booking has been cancelled. Reason: " + reason,
                "BOOKING",
                bookingId
            );
        }
    }
    
    @Override
    public void notifyPaymentPending(Long userId, Long paymentId, Double amount) {
        createNotification(
            userId,
            Notification.NotificationType.PAYMENT_PENDING,
            "Payment Pending",
            "Payment of " + amount + " TND is pending for your booking.",
            "PAYMENT",
            paymentId
        );
    }
    
    @Override
    public void notifyPaymentCompleted(Long userId, Long paymentId, Double amount) {
        createNotification(
            userId,
            Notification.NotificationType.PAYMENT_COMPLETED,
            "Payment Completed",
            "Payment of " + amount + " TND has been completed successfully.",
            "PAYMENT",
            paymentId
        );
    }
    
    @Override
    public void notifyPaymentFailed(Long userId, Long paymentId, String reason) {
        createNotification(
            userId,
            Notification.NotificationType.PAYMENT_FAILED,
            "Payment Failed",
            "Payment failed. Reason: " + reason,
            "PAYMENT",
            paymentId
        );
    }
    
    @Override
    public void notifyRatingReceived(Long userId, String raterName, Integer rating, String comment) {
        createNotification(
            userId,
            Notification.NotificationType.RATING_RECEIVED,
            "New Rating Received",
            raterName + " rated you " + rating + " stars" + (comment != null ? ": " + comment : ""),
            "RATING",
            null
        );
    }
    
    @Override
    public void scheduleTripReminder(Long tripId, LocalDateTime reminderTime) {
        // TODO: Implement scheduled reminders using Spring's @Scheduled or Quartz
        // For now, we'll create a reminder notification
        createNotification(
            null, // Will be set when processing
            Notification.NotificationType.REMINDER,
            "Trip Reminder",
            "Your trip is starting soon!",
            "TRIP",
            tripId
        );
    }
    
    @Override
    public void processScheduledReminders() {
        // TODO: Implement reminder processing logic
    }
}
