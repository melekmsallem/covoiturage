package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Paiement;

import java.util.List;

public interface PaymentService {
    
    // Payment Processing
    Paiement createPayment(Long reservationId, Paiement.PaymentMethod paymentMethod, Double amount);
    Paiement processPayment(Long paymentId, String transactionId);
    Paiement processPayment(Long paymentId, String transactionId, String paymentDetails);
    Paiement cancelPayment(Long paymentId, String reason);
    Paiement refundPayment(Long paymentId, String reason);
    
    // Payment Retrieval
    Paiement getPaymentById(Long paymentId);
    Paiement getPaymentByReservationId(Long reservationId);
    List<Paiement> getPaymentsByUserId(Long userId);
    List<Paiement> getPaymentsByStatus(Paiement.PaymentStatus status);
    List<Paiement> getPaymentsByMethod(Paiement.PaymentMethod paymentMethod);
    
    // Payment Statistics
    Double getTotalRevenue();
    Double getRevenueByDateRange(java.time.LocalDateTime startDate, java.time.LocalDateTime endDate);
    Double getRevenueByUser(Long userId);
    Long getTotalTransactions();
    Long getSuccessfulTransactions();
    Long getFailedTransactions();
    
    // Payment Validation
    boolean validatePaymentAmount(Double amount);
    boolean validatePaymentMethod(Paiement.PaymentMethod paymentMethod);
    boolean canProcessPayment(Long reservationId);
    
    // Admin Functions
    List<Paiement> getAllPayments();
    Paiement updatePaymentStatus(Long paymentId, Paiement.PaymentStatus status, String notes);
    void processPendingPayments();
    
    // Integration with External Payment Gateways
    String generatePaymentLink(Long paymentId);
    boolean verifyPaymentCallback(String callbackData);
    String processStripePayment(Long paymentId, String stripeToken);
    String processPayPalPayment(Long paymentId, String paypalOrderId);
}
