package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Paiement;

public interface ReceiptService {
    byte[] generatePaymentReceiptPdf(Long paymentId);
    byte[] exportPaymentsToExcel(Long userId);
    byte[] exportAllPaymentsToExcel();
}



















