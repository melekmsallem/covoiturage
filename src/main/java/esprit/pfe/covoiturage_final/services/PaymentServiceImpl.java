package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Paiement;
import esprit.pfe.covoiturage_final.entities.Reservation;
import esprit.pfe.covoiturage_final.repositories.PaiementRepository;
import esprit.pfe.covoiturage_final.repositories.ReservationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class PaymentServiceImpl implements PaymentService {
    
    @Autowired
    private PaiementRepository paiementRepository;
    
    @Autowired
    private ReservationRepository reservationRepository;
    
    @Autowired
    private NotificationService notificationService;
    
    @Override
    public Paiement createPayment(Long reservationId, Paiement.PaymentMethod paymentMethod, Double amount) {
        Reservation reservation = reservationRepository.findById(reservationId)
            .orElseThrow(() -> new RuntimeException("Reservation not found"));
        
        if (!canProcessPayment(reservationId)) {
            throw new RuntimeException("Cannot process payment for this reservation");
        }
        
        if (!validatePaymentAmount(amount)) {
            throw new RuntimeException("Invalid payment amount");
        }
        
        if (!validatePaymentMethod(paymentMethod)) {
            throw new RuntimeException("Invalid payment method");
        }
        
        // Check if payment already exists
        Paiement existingPayment = paiementRepository.findOneByReservationId(reservationId);
        if (existingPayment != null) {
            throw new RuntimeException("Payment already exists for this reservation");
        }
        
        Paiement payment = new Paiement();
        payment.setReservationId(reservationId);
        payment.setAmount(amount);
        payment.setPaymentMethod(paymentMethod);
        payment.setStatus(Paiement.PaymentStatus.PENDING);
        payment.setTransactionId(generateTransactionId());
        payment.setNotes("Payment created");
        
        payment = paiementRepository.save(payment);
        
        // Send notification
        notificationService.notifyPaymentPending(reservation.getPassagerId(), payment.getId(), amount);
        
        return payment;
    }
    
    @Override
    public Paiement processPayment(Long paymentId, String transactionId) {
        return processPayment(paymentId, transactionId, null);
    }
    
    @Override
    public Paiement processPayment(Long paymentId, String transactionId, String paymentDetails) {
        Paiement payment = paiementRepository.findById(paymentId)
            .orElseThrow(() -> new RuntimeException("Payment not found"));
        
        if (payment.getStatus() != Paiement.PaymentStatus.PENDING) {
            throw new RuntimeException("Payment is not in pending status");
        }
        
        // Simulate payment processing (in real implementation, integrate with payment gateway)
        boolean paymentSuccessful = simulatePaymentProcessing(payment);
        
        if (paymentSuccessful) {
            payment.setStatus(Paiement.PaymentStatus.COMPLETED);
            payment.setTransactionId(transactionId);
            payment.setPaymentDate(LocalDateTime.now());
            payment.setNotes("Payment processed successfully");
            
            // Update reservation status if needed
            Reservation reservation = reservationRepository.findById(payment.getReservationId()).orElse(null);
            if (reservation != null && reservation.getStatus() == Reservation.ReservationStatus.PENDING) {
                reservation.setStatus(Reservation.ReservationStatus.CONFIRMED);
                reservationRepository.save(reservation);
            }
            
            // Send notification
            notificationService.notifyPaymentCompleted(reservation.getPassagerId(), payment.getId(), payment.getAmount());
            
        } else {
            payment.setStatus(Paiement.PaymentStatus.FAILED);
            payment.setNotes("Payment processing failed");
            
            // Send notification
            Reservation reservationForNotification = reservationRepository.findById(payment.getReservationId()).orElse(null);
            if (reservationForNotification != null) {
                notificationService.notifyPaymentFailed(reservationForNotification.getPassagerId(), payment.getId(), "Payment processing failed");
            }
        }
        
        return paiementRepository.save(payment);
    }
    
    @Override
    public Paiement cancelPayment(Long paymentId, String reason) {
        Paiement payment = paiementRepository.findById(paymentId)
            .orElseThrow(() -> new RuntimeException("Payment not found"));
        
        if (payment.getStatus() == Paiement.PaymentStatus.COMPLETED) {
            throw new RuntimeException("Cannot cancel completed payment");
        }
        
        payment.setStatus(Paiement.PaymentStatus.FAILED);
        payment.setNotes("Payment cancelled: " + reason);
        payment.setPaymentDate(LocalDateTime.now());
        
        return paiementRepository.save(payment);
    }
    
    @Override
    public Paiement refundPayment(Long paymentId, String reason) {
        Paiement payment = paiementRepository.findById(paymentId)
            .orElseThrow(() -> new RuntimeException("Payment not found"));
        
        if (payment.getStatus() != Paiement.PaymentStatus.COMPLETED) {
            throw new RuntimeException("Can only refund completed payments");
        }
        
        // Create refund payment record
        Paiement refund = new Paiement();
        refund.setReservationId(payment.getReservationId());
        refund.setAmount(-payment.getAmount()); // Negative amount for refund
        refund.setPaymentMethod(payment.getPaymentMethod());
        refund.setStatus(Paiement.PaymentStatus.COMPLETED);
        refund.setTransactionId(generateTransactionId());
        refund.setPaymentDate(LocalDateTime.now());
        refund.setNotes("Refund for payment ID " + paymentId + ". Reason: " + reason);
        
        return paiementRepository.save(refund);
    }
    
    @Override
    public Paiement getPaymentById(Long paymentId) {
        return paiementRepository.findById(paymentId)
            .orElseThrow(() -> new RuntimeException("Payment not found"));
    }
    
    @Override
    public Paiement getPaymentByReservationId(Long reservationId) {
        return paiementRepository.findOneByReservationId(reservationId);
    }
    
    @Override
    public List<Paiement> getPaymentsByUserId(Long userId) {
        // This would require a join with reservations, for now return empty list
        // In a real implementation, you'd add this method to the repository
        return List.of();
    }
    
    @Override
    public List<Paiement> getPaymentsByStatus(Paiement.PaymentStatus status) {
        return paiementRepository.findByStatus(status);
    }
    
    @Override
    public List<Paiement> getPaymentsByMethod(Paiement.PaymentMethod paymentMethod) {
        return paiementRepository.findByPaymentMethod(paymentMethod);
    }
    
    @Override
    public Double getTotalRevenue() {
        return paiementRepository.getTotalRevenueBetween(
            LocalDateTime.of(2020, 1, 1, 0, 0),
            LocalDateTime.now()
        );
    }
    
    @Override
    public Double getRevenueByDateRange(LocalDateTime startDate, LocalDateTime endDate) {
        return paiementRepository.getTotalRevenueBetween(startDate, endDate);
    }
    
    @Override
    public Double getRevenueByUser(Long userId) {
        // This would require a more complex query with joins
        return 0.0;
    }
    
    @Override
    public Long getTotalTransactions() {
        return paiementRepository.count();
    }
    
    @Override
    public Long getSuccessfulTransactions() {
        return paiementRepository.countByStatus(Paiement.PaymentStatus.COMPLETED);
    }
    
    @Override
    public Long getFailedTransactions() {
        return paiementRepository.countByStatus(Paiement.PaymentStatus.FAILED);
    }
    
    @Override
    public boolean validatePaymentAmount(Double amount) {
        return amount != null && amount > 0 && amount <= 10000; // Max 10,000 TND
    }
    
    @Override
    public boolean validatePaymentMethod(Paiement.PaymentMethod paymentMethod) {
        return paymentMethod != null;
    }
    
    @Override
    public boolean canProcessPayment(Long reservationId) {
        Reservation reservation = reservationRepository.findById(reservationId).orElse(null);
        return reservation != null && reservation.getStatus() == Reservation.ReservationStatus.CONFIRMED;
    }
    
    @Override
    public List<Paiement> getAllPayments() {
        return paiementRepository.findAll();
    }
    
    @Override
    public Paiement updatePaymentStatus(Long paymentId, Paiement.PaymentStatus status, String notes) {
        Paiement payment = paiementRepository.findById(paymentId)
            .orElseThrow(() -> new RuntimeException("Payment not found"));
        
        payment.setStatus(status);
        payment.setNotes(notes);
        payment.setPaymentDate(LocalDateTime.now());
        
        return paiementRepository.save(payment);
    }
    
    @Override
    public void processPendingPayments() {
        List<Paiement> pendingPayments = paiementRepository.findByStatus(Paiement.PaymentStatus.PENDING);
        
        for (Paiement payment : pendingPayments) {
            // Check if payment is older than 30 minutes
            if (payment.getPaymentDate() == null || 
                payment.getPaymentDate().isBefore(LocalDateTime.now().minusMinutes(30))) {
                
                // Cancel old pending payments
                payment.setStatus(Paiement.PaymentStatus.FAILED);
                payment.setNotes("Payment timeout - automatically cancelled");
                paiementRepository.save(payment);
            }
        }
    }
    
    @Override
    public String generatePaymentLink(Long paymentId) {
        // Generate a secure payment link
        return "https://covoiturage.tn/payment/" + paymentId + "?token=" + generateTransactionId();
    }
    
    @Override
    public boolean verifyPaymentCallback(String callbackData) {
        // Verify payment gateway callback
        // This would contain real verification logic
        return true;
    }
    
    @Override
    public String processStripePayment(Long paymentId, String stripeToken) {
        // Integration with Stripe payment gateway
        // This would contain real Stripe integration logic
        return "stripe_transaction_" + System.currentTimeMillis();
    }
    
    @Override
    public String processPayPalPayment(Long paymentId, String paypalOrderId) {
        // Integration with PayPal payment gateway
        // This would contain real PayPal integration logic
        return "paypal_transaction_" + System.currentTimeMillis();
    }
    
    // Helper methods
    private String generateTransactionId() {
        return "TXN_" + UUID.randomUUID().toString().replace("-", "").substring(0, 16).toUpperCase();
    }
    
    private boolean simulatePaymentProcessing(Paiement payment) {
        // Simulate payment processing with 90% success rate
        // In real implementation, this would integrate with actual payment gateway
        return Math.random() > 0.1; // 90% success rate
    }
}
