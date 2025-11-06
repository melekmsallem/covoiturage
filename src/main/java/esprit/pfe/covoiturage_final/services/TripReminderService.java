package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Voyage;
import esprit.pfe.covoiturage_final.repositories.VoyageRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Service to handle trip start reminders for drivers
 * Sends notifications 1 hour before trip departure time
 */
@Service
@Transactional
public class TripReminderService {
    
    private static final Logger log = LoggerFactory.getLogger(TripReminderService.class);
    
    @Autowired
    private VoyageRepository voyageRepository;
    
    @Autowired
    private NotificationService notificationService;
    
    /**
     * Check every 5 minutes for trips starting in 1 hour
     * Send reminder notifications to drivers
     */
    @Scheduled(cron = "0 */5 * * * *") // Every 5 minutes
    public void checkAndSendTripReminders() {
        try {
            LocalDateTime now = LocalDateTime.now();
            LocalDateTime reminderThreshold = now.plusHours(1);
            
            // Find trips that start between now + 55 minutes and now + 1 hour 5 minutes
            LocalDateTime lowerBound = reminderThreshold.minusMinutes(5);
            LocalDateTime upperBound = reminderThreshold.plusMinutes(5);
            
            List<Voyage> upcomingTrips = voyageRepository.findByDepartureTimeBetweenAndStatus(
                lowerBound, upperBound, Voyage.VoyageStatus.PLANNED
            );
            
            log.info("Checking trip reminders: Found {} trips starting soon", upcomingTrips.size());
            
            for (Voyage trip : upcomingTrips) {
                try {
                    sendTripStartReminder(trip);
                } catch (Exception e) {
                    log.error("Failed to send reminder for trip {}: {}", trip.getId(), e.getMessage());
                }
            }
        } catch (Exception e) {
            log.error("Error in trip reminder check: {}", e.getMessage(), e);
        }
    }
    
    /**
     * Send trip start reminder notification to driver
     */
    private void sendTripStartReminder(Voyage trip) {
        String title = "Trip Starting Soon - Ready to Go?";
        String message = String.format(
            "Your trip from %s to %s starts in 1 hour! " +
            "Click to view your route and pickup points.",
            trip.getDepartureVille() != null ? trip.getDepartureVille().getName() : "Unknown",
            trip.getArrivalVille() != null ? trip.getArrivalVille().getName() : "Unknown"
        );
        
        notificationService.createNotification(
            trip.getConducteurId(),
            esprit.pfe.covoiturage_final.entities.Notification.NotificationType.REMINDER,
            title,
            message,
            "TRIP",
            trip.getId()
        );
        
        log.info("Sent reminder notification to driver {} for trip {}", trip.getConducteurId(), trip.getId());
    }
}

