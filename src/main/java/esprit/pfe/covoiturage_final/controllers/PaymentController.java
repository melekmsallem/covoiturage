package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.entities.Paiement;
import esprit.pfe.covoiturage_final.services.PaymentService;
import esprit.pfe.covoiturage_final.services.ReceiptService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/payments")
@CrossOrigin(origins = "*", maxAge = 3600)
public class PaymentController {
    
    @Autowired
    private PaymentService paymentService;

    @Autowired
    private ReceiptService receiptService;
    
    @PostMapping
    public ResponseEntity<?> createPayment(@RequestBody CreatePaymentRequest request) {
        try {
            Paiement payment = paymentService.createPayment(
                request.getReservationId(),
                request.getPaymentMethod(),
                request.getAmount()
            );
            return ResponseEntity.ok(payment);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/{paymentId}/process")
    public ResponseEntity<?> processPayment(@PathVariable Long paymentId, @RequestBody ProcessPaymentRequest request) {
        try {
            Paiement payment = paymentService.processPayment(paymentId, request.getTransactionId(), request.getPaymentDetails());
            return ResponseEntity.ok(payment);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/{paymentId}/cancel")
    public ResponseEntity<?> cancelPayment(@PathVariable Long paymentId, @RequestBody CancelPaymentRequest request) {
        try {
            Paiement payment = paymentService.cancelPayment(paymentId, request.getReason());
            return ResponseEntity.ok(payment);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/{paymentId}/refund")
    public ResponseEntity<?> refundPayment(@PathVariable Long paymentId, @RequestBody RefundPaymentRequest request) {
        try {
            Paiement payment = paymentService.refundPayment(paymentId, request.getReason());
            return ResponseEntity.ok(payment);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/{paymentId}")
    public ResponseEntity<?> getPayment(@PathVariable Long paymentId) {
        try {
            Paiement payment = paymentService.getPaymentById(paymentId);
            return ResponseEntity.ok(payment);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/reservation/{reservationId}")
    public ResponseEntity<?> getPaymentByReservation(@PathVariable Long reservationId) {
        try {
            Paiement payment = paymentService.getPaymentByReservationId(reservationId);
            if (payment != null) {
                return ResponseEntity.ok(payment);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/my-payments")
    public ResponseEntity<?> getMyPayments() {
        try {
            Long userId = getCurrentUserId();
            List<Paiement> payments = paymentService.getPaymentsByUserId(userId);
            return ResponseEntity.ok(payments);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/status/{status}")
    public ResponseEntity<?> getPaymentsByStatus(@PathVariable String status) {
        try {
            Paiement.PaymentStatus paymentStatus = Paiement.PaymentStatus.valueOf(status.toUpperCase());
            List<Paiement> payments = paymentService.getPaymentsByStatus(paymentStatus);
            return ResponseEntity.ok(payments);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body("Invalid payment status");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/method/{method}")
    public ResponseEntity<?> getPaymentsByMethod(@PathVariable String method) {
        try {
            Paiement.PaymentMethod paymentMethod = Paiement.PaymentMethod.valueOf(method.toUpperCase());
            List<Paiement> payments = paymentService.getPaymentsByMethod(paymentMethod);
            return ResponseEntity.ok(payments);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body("Invalid payment method");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/statistics")
    public ResponseEntity<?> getPaymentStatistics() {
        try {
            PaymentStatistics stats = new PaymentStatistics();
            stats.setTotalRevenue(paymentService.getTotalRevenue());
            stats.setTotalTransactions(paymentService.getTotalTransactions());
            stats.setSuccessfulTransactions(paymentService.getSuccessfulTransactions());
            stats.setFailedTransactions(paymentService.getFailedTransactions());
            
            return ResponseEntity.ok(stats);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/{paymentId}/link")
    public ResponseEntity<?> generatePaymentLink(@PathVariable Long paymentId) {
        try {
            String paymentLink = paymentService.generatePaymentLink(paymentId);
            return ResponseEntity.ok(new PaymentLinkResponse(paymentLink));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/{paymentId}/receipt")
    public ResponseEntity<byte[]> downloadReceipt(@PathVariable Long paymentId) {
        try {
            byte[] pdfBytes = receiptService.generatePaymentReceiptPdf(paymentId);
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_PDF);
            headers.setContentDispositionFormData("attachment", "receipt_" + paymentId + ".pdf");
            return ResponseEntity.ok().headers(headers).body(pdfBytes);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(null);
        }
    }

    @GetMapping("/export/my-payments")
    public ResponseEntity<byte[]> exportMyPayments() {
        try {
            Long userId = getCurrentUserId();
            byte[] excelBytes = receiptService.exportPaymentsToExcel(userId);
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));
            headers.setContentDispositionFormData("attachment", "my_payments.xlsx");
            return ResponseEntity.ok().headers(headers).body(excelBytes);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(null);
        }
    }
    
    // Admin endpoints
    @GetMapping("/admin/all")
    public ResponseEntity<?> getAllPayments() {
        try {
            List<Paiement> payments = paymentService.getAllPayments();
            return ResponseEntity.ok(payments);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/admin/export")
    public ResponseEntity<byte[]> exportAllPayments() {
        try {
            byte[] excelBytes = receiptService.exportAllPaymentsToExcel();
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));
            headers.setContentDispositionFormData("attachment", "all_payments.xlsx");
            return ResponseEntity.ok().headers(headers).body(excelBytes);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(null);
        }
    }

    @GetMapping("/admin/pending-transfers")
    public ResponseEntity<?> getPendingBankTransfers() {
        try {
            List<Paiement> pendingTransfers = paymentService.getPaymentsByMethod(Paiement.PaymentMethod.BANK_TRANSFER)
                .stream()
                .filter(p -> p.getStatus() == Paiement.PaymentStatus.PENDING)
                .toList();
            return ResponseEntity.ok(pendingTransfers);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/admin/{paymentId}/approve-transfer")
    public ResponseEntity<?> approveBankTransfer(@PathVariable Long paymentId, @RequestBody ApproveTransferRequest request) {
        try {
            Paiement payment = paymentService.getPaymentById(paymentId);
            if (payment.getPaymentMethod() != Paiement.PaymentMethod.BANK_TRANSFER) {
                return ResponseEntity.badRequest().body("Payment is not a bank transfer");
            }
            if (payment.getStatus() != Paiement.PaymentStatus.PENDING) {
                return ResponseEntity.badRequest().body("Payment is not pending");
            }
            
            String notes = "Bank transfer approved by admin. " + (request.getNotes() != null ? request.getNotes() : "");
            String transactionId = request.getTransactionId() != null ? request.getTransactionId() : "TRANSFER_" + System.currentTimeMillis();
            Paiement approved = paymentService.processPayment(paymentId, transactionId, notes);
            return ResponseEntity.ok(approved);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PutMapping("/admin/{paymentId}/status")
    public ResponseEntity<?> updatePaymentStatus(@PathVariable Long paymentId, @RequestBody UpdatePaymentStatusRequest request) {
        try {
            Paiement.PaymentStatus status = Paiement.PaymentStatus.valueOf(request.getStatus().toUpperCase());
            Paiement payment = paymentService.updatePaymentStatus(paymentId, status, request.getNotes());
            return ResponseEntity.ok(payment);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body("Invalid payment status");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof esprit.pfe.covoiturage_final.entities.User) {
            esprit.pfe.covoiturage_final.entities.User user = (esprit.pfe.covoiturage_final.entities.User) authentication.getPrincipal();
            return user.getId();
        }
        throw new RuntimeException("User not authenticated");
    }
    
    // Request/Response classes
    public static class CreatePaymentRequest {
        private Long reservationId;
        private Paiement.PaymentMethod paymentMethod;
        private Double amount;
        
        public Long getReservationId() { return reservationId; }
        public void setReservationId(Long reservationId) { this.reservationId = reservationId; }
        
        public Paiement.PaymentMethod getPaymentMethod() { return paymentMethod; }
        public void setPaymentMethod(Paiement.PaymentMethod paymentMethod) { this.paymentMethod = paymentMethod; }
        
        public Double getAmount() { return amount; }
        public void setAmount(Double amount) { this.amount = amount; }
    }
    
    public static class ProcessPaymentRequest {
        private String transactionId;
        private String paymentDetails;
        
        public String getTransactionId() { return transactionId; }
        public void setTransactionId(String transactionId) { this.transactionId = transactionId; }
        
        public String getPaymentDetails() { return paymentDetails; }
        public void setPaymentDetails(String paymentDetails) { this.paymentDetails = paymentDetails; }
    }
    
    public static class CancelPaymentRequest {
        private String reason;
        
        public String getReason() { return reason; }
        public void setReason(String reason) { this.reason = reason; }
    }
    
    public static class RefundPaymentRequest {
        private String reason;
        
        public String getReason() { return reason; }
        public void setReason(String reason) { this.reason = reason; }
    }

    public static class ApproveTransferRequest {
        private String transactionId;
        private String notes;
        
        public String getTransactionId() { return transactionId; }
        public void setTransactionId(String transactionId) { this.transactionId = transactionId; }
        
        public String getNotes() { return notes; }
        public void setNotes(String notes) { this.notes = notes; }
    }
    
    public static class UpdatePaymentStatusRequest {
        private String status;
        private String notes;
        
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        
        public String getNotes() { return notes; }
        public void setNotes(String notes) { this.notes = notes; }
    }
    
    public static class PaymentLinkResponse {
        private String paymentLink;
        
        public PaymentLinkResponse(String paymentLink) {
            this.paymentLink = paymentLink;
        }
        
        public String getPaymentLink() { return paymentLink; }
        public void setPaymentLink(String paymentLink) { this.paymentLink = paymentLink; }
    }
    
    public static class PaymentStatistics {
        private Double totalRevenue;
        private Long totalTransactions;
        private Long successfulTransactions;
        private Long failedTransactions;
        
        public Double getTotalRevenue() { return totalRevenue; }
        public void setTotalRevenue(Double totalRevenue) { this.totalRevenue = totalRevenue; }
        
        public Long getTotalTransactions() { return totalTransactions; }
        public void setTotalTransactions(Long totalTransactions) { this.totalTransactions = totalTransactions; }
        
        public Long getSuccessfulTransactions() { return successfulTransactions; }
        public void setSuccessfulTransactions(Long successfulTransactions) { this.successfulTransactions = successfulTransactions; }
        
        public Long getFailedTransactions() { return failedTransactions; }
        public void setFailedTransactions(Long failedTransactions) { this.failedTransactions = failedTransactions; }
    }
}


