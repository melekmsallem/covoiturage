package esprit.pfe.covoiturage_final.services;

public interface EmailService {
    
    void sendNotificationEmail(String to, String subject, String body);
    void sendWelcomeEmail(String to, String username);
    void sendTripConfirmationEmail(String to, String passengerName, String tripDetails);
    void sendBookingConfirmationEmail(String to, String driverName, String tripDetails);
    void sendPaymentConfirmationEmail(String to, String amount, String paymentDetails);
    void sendTripReminderEmail(String to, String tripDetails, String reminderTime);
    void sendSystemAnnouncementEmail(String to, String subject, String message);
}





