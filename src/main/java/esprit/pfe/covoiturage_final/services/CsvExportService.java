package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.*;
import esprit.pfe.covoiturage_final.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.StringWriter;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class CsvExportService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private VoyageRepository voyageRepository;
    
    @Autowired
    private ReservationRepository reservationRepository;
    
    @Autowired
    private PaiementRepository paiementRepository;
    
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    
    public String exportUsers() {
        List<User> users = userRepository.findAll();
        StringWriter writer = new StringWriter();
        
        // CSV Header
        writer.append("ID,Username,Email,First Name,Last Name,Phone,Role,Active,Verified,Created At\n");
        
        // CSV Data
        for (User user : users) {
            writer.append(String.valueOf(user.getId())).append(",");
            writer.append(escapeCsv(user.getUsername())).append(",");
            writer.append(escapeCsv(user.getEmail())).append(",");
            writer.append(escapeCsv(user.getFirstName())).append(",");
            writer.append(escapeCsv(user.getLastName())).append(",");
            writer.append(escapeCsv(user.getPhoneNumber())).append(",");
            writer.append(user.getRole() != null ? user.getRole().name() : "").append(",");
            writer.append(String.valueOf(user.getIsActive())).append(",");
            writer.append(String.valueOf(user.getIsVerified())).append(",");
            writer.append(user.getCreatedAt() != null ? user.getCreatedAt().format(DATE_FORMATTER) : "").append("\n");
        }
        
        return writer.toString();
    }
    
    public String exportTrips() {
        List<Voyage> trips = voyageRepository.findAll();
        StringWriter writer = new StringWriter();
        
        // CSV Header
        writer.append("ID,Driver ID,Departure,Arrival,Departure Time,Price,Max Seats,Available Seats,Status,Created At\n");
        
        // CSV Data
        for (Voyage trip : trips) {
            writer.append(String.valueOf(trip.getId())).append(",");
            writer.append(String.valueOf(trip.getConducteurId())).append(",");
            writer.append(trip.getDepartureVille() != null ? escapeCsv(trip.getDepartureVille().getName()) : "").append(",");
            writer.append(trip.getArrivalVille() != null ? escapeCsv(trip.getArrivalVille().getName()) : "").append(",");
            writer.append(trip.getDepartureTime() != null ? trip.getDepartureTime().format(DATE_FORMATTER) : "").append(",");
            writer.append(String.valueOf(trip.getPricePerSeat())).append(",");
            writer.append(String.valueOf(trip.getMaxSeats())).append(",");
            writer.append(String.valueOf(trip.getAvailableSeats())).append(",");
            writer.append(trip.getStatus() != null ? trip.getStatus().name() : "").append(",");
            writer.append(trip.getCreatedAt() != null ? trip.getCreatedAt().format(DATE_FORMATTER) : "").append("\n");
        }
        
        return writer.toString();
    }
    
    public String exportBookings() {
        List<Reservation> bookings = reservationRepository.findAll();
        StringWriter writer = new StringWriter();
        
        // CSV Header
        writer.append("ID,Passenger ID,Trip ID,Seats,Total Price,Status,Created At\n");
        
        // CSV Data
        for (Reservation booking : bookings) {
            writer.append(String.valueOf(booking.getId())).append(",");
            writer.append(String.valueOf(booking.getPassagerId())).append(",");
            writer.append(String.valueOf(booking.getVoyageId())).append(",");
            writer.append(String.valueOf(booking.getNumberOfSeats())).append(",");
            writer.append(String.valueOf(booking.getTotalPrice())).append(",");
            writer.append(booking.getStatus() != null ? booking.getStatus().name() : "").append(",");
            writer.append(booking.getReservationDate() != null ? booking.getReservationDate().format(DATE_FORMATTER) : "").append("\n");
        }
        
        return writer.toString();
    }
    
    public String exportPayments() {
        List<Paiement> payments = paiementRepository.findAll();
        StringWriter writer = new StringWriter();
        
        // CSV Header
        writer.append("ID,Booking ID,Amount,Payment Method,Status,Payment Date\n");
        
        // CSV Data
        for (Paiement payment : payments) {
            writer.append(String.valueOf(payment.getId())).append(",");
            writer.append(String.valueOf(payment.getReservationId())).append(",");
            writer.append(String.valueOf(payment.getAmount())).append(",");
            writer.append(payment.getPaymentMethod() != null ? payment.getPaymentMethod().name() : "").append(",");
            writer.append(payment.getStatus() != null ? payment.getStatus().name() : "").append(",");
            writer.append(payment.getPaymentDate() != null ? payment.getPaymentDate().format(DATE_FORMATTER) : "").append("\n");
        }
        
        return writer.toString();
    }
    
    private String escapeCsv(String value) {
        if (value == null) {
            return "";
        }
        
        // Escape quotes and wrap in quotes if needed
        if (value.contains(",") || value.contains("\"") || value.contains("\n")) {
            return "\"" + value.replace("\"", "\"\"") + "\"";
        }
        
        return value;
    }
}

