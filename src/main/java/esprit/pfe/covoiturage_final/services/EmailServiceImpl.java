package esprit.pfe.covoiturage_final.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailServiceImpl implements EmailService {
    
    @Autowired
    private JavaMailSender mailSender;
    
    @Value("${spring.mail.username}")
    private String fromEmail;
    
    @Override
    public void sendNotificationEmail(String to, String subject, String body) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(to);
            message.setSubject(subject);
            message.setText(body);
            
            mailSender.send(message);
            System.out.println("Email sent successfully to " + to + ": " + subject);
        } catch (Exception e) {
            System.err.println("Failed to send email to " + to + ": " + e.getMessage());
        }
    }
    
    @Override
    public void sendWelcomeEmail(String to, String username) {
        String subject = "Welcome to Covoiturage Platform";
        String body = String.format("""
            Dear %s,
            
            Welcome to the Covoiturage platform! We're excited to have you on board.
            
            You can now:
            - Create or book trips
            - Connect with other travelers
            - Save money and reduce your carbon footprint
            
            If you have any questions, please don't hesitate to contact our support team.
            
            Best regards,
            The Covoiturage Team
            """, username);
        
        sendNotificationEmail(to, subject, body);
    }
    
    @Override
    public void sendTripConfirmationEmail(String to, String passengerName, String tripDetails) {
        String subject = "Trip Confirmation";
        String body = String.format("""
            Dear %s,
            
            Your trip has been confirmed! Here are the details:
            
            %s
            
            Please arrive on time and have a safe journey!
            
            Best regards,
            The Covoiturage Team
            """, passengerName, tripDetails);
        
        sendNotificationEmail(to, subject, body);
    }
    
    @Override
    public void sendBookingConfirmationEmail(String to, String driverName, String tripDetails) {
        String subject = "New Booking Confirmation";
        String body = String.format("""
            Dear %s,
            
            You have received a new booking for your trip:
            
            %s
            
            Please confirm or cancel this booking in your dashboard.
            
            Best regards,
            The Covoiturage Team
            """, driverName, tripDetails);
        
        sendNotificationEmail(to, subject, body);
    }
    
    @Override
    public void sendPaymentConfirmationEmail(String to, String amount, String paymentDetails) {
        String subject = "Payment Confirmation";
        String body = String.format("""
            Dear User,
            
            Your payment of %s TND has been processed successfully.
            
            Payment Details:
            %s
            
            Thank you for using Covoiturage!
            
            Best regards,
            The Covoiturage Team
            """, amount, paymentDetails);
        
        sendNotificationEmail(to, subject, body);
    }
    
    @Override
    public void sendTripReminderEmail(String to, String tripDetails, String reminderTime) {
        String subject = "Trip Reminder";
        String body = String.format("""
            Dear User,
            
            This is a reminder that your trip is starting soon (%s):
            
            %s
            
            Please make sure you're ready and have the driver's contact information.
            
            Have a safe journey!
            
            Best regards,
            The Covoiturage Team
            """, reminderTime, tripDetails);
        
        sendNotificationEmail(to, subject, body);
    }
    
    @Override
    public void sendSystemAnnouncementEmail(String to, String subject, String message) {
        String body = String.format("""
            Dear User,
            
            %s
            
            %s
            
            Best regards,
            The Covoiturage Team
            """, subject, message);
        
        sendNotificationEmail(to, subject, body);
    }
}
