package esprit.pfe.covoiturage_final.services;

import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.element.Paragraph;
import com.itextpdf.layout.element.Table;
import esprit.pfe.covoiturage_final.entities.Paiement;
import esprit.pfe.covoiturage_final.entities.Reservation;
import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.entities.Voyage;
import esprit.pfe.covoiturage_final.repositories.PaiementRepository;
import esprit.pfe.covoiturage_final.repositories.ReservationRepository;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import esprit.pfe.covoiturage_final.repositories.VoyageRepository;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class ReceiptServiceImpl implements ReceiptService {

    @Autowired
    private PaiementRepository paiementRepository;

    @Autowired
    private ReservationRepository reservationRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private VoyageRepository voyageRepository;

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    @Override
    public byte[] generatePaymentReceiptPdf(Long paymentId) {
        Paiement payment = paiementRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        Reservation reservation = reservationRepository.findById(payment.getReservationId())
                .orElseThrow(() -> new RuntimeException("Reservation not found"));

        Voyage trip = voyageRepository.findById(reservation.getVoyageId())
                .orElseThrow(() -> new RuntimeException("Trip not found"));

        User passenger = userRepository.findById(reservation.getPassagerId())
                .orElseThrow(() -> new RuntimeException("Passenger not found"));

        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            PdfWriter writer = new PdfWriter(baos);
            PdfDocument pdf = new PdfDocument(writer);
            Document document = new Document(pdf);

            // Header
            document.add(new Paragraph("COVOITURAGE PAYMENT RECEIPT")
                    .setBold()
                    .setFontSize(20));
            document.add(new Paragraph("Receipt #" + payment.getId())
                    .setFontSize(12));
            document.add(new Paragraph("Date: " + (payment.getPaymentDate() != null 
                    ? payment.getPaymentDate().format(DATE_FORMATTER) : "N/A"))
                    .setFontSize(10));
            document.add(new Paragraph("\n"));

            // Passenger details
            document.add(new Paragraph("Passenger Information").setBold());
            document.add(new Paragraph("Name: " + passenger.getFirstName() + " " + passenger.getLastName()));
            document.add(new Paragraph("Email: " + passenger.getEmail()));
            document.add(new Paragraph("\n"));

            // Trip details
            document.add(new Paragraph("Trip Information").setBold());
            String depCity = trip.getDepartureVille() != null ? trip.getDepartureVille().getName() : "Unknown";
            String arrCity = trip.getArrivalVille() != null ? trip.getArrivalVille().getName() : "Unknown";
            document.add(new Paragraph("Route: " + depCity + " → " + arrCity));
            document.add(new Paragraph("Departure: " + (trip.getDepartureTime() != null 
                    ? trip.getDepartureTime().format(DATE_FORMATTER) : "N/A")));
            document.add(new Paragraph("Seats: " + reservation.getNumberOfSeats()));
            document.add(new Paragraph("\n"));

            // Payment details
            document.add(new Paragraph("Payment Information").setBold());
            document.add(new Paragraph("Amount: " + payment.getAmount() + " TND"));
            document.add(new Paragraph("Method: " + payment.getPaymentMethod()));
            document.add(new Paragraph("Status: " + payment.getStatus()));
            if (payment.getTransactionId() != null) {
                document.add(new Paragraph("Transaction ID: " + payment.getTransactionId()));
            }
            document.add(new Paragraph("\n"));

            document.add(new Paragraph("Thank you for using Covoiturage!").setItalic().setFontSize(10));

            document.close();
            return baos.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate PDF receipt: " + e.getMessage(), e);
        }
    }

    @Override
    public byte[] exportPaymentsToExcel(Long userId) {
        List<Paiement> payments = paiementRepository.findByReservationId(userId); // This needs proper query
        return generateExcel(payments);
    }

    @Override
    public byte[] exportAllPaymentsToExcel() {
        List<Paiement> payments = paiementRepository.findAll();
        return generateExcel(payments);
    }

    private byte[] generateExcel(List<Paiement> payments) {
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Payments");

            // Header row
            Row headerRow = sheet.createRow(0);
            String[] headers = {"ID", "Reservation ID", "Amount (TND)", "Method", "Status", "Transaction ID", "Payment Date", "Notes"};
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                CellStyle style = workbook.createCellStyle();
                Font font = workbook.createFont();
                font.setBold(true);
                style.setFont(font);
                cell.setCellStyle(style);
            }

            // Data rows
            int rowNum = 1;
            for (Paiement payment : payments) {
                Row row = sheet.createRow(rowNum++);
                row.createCell(0).setCellValue(payment.getId());
                row.createCell(1).setCellValue(payment.getReservationId());
                row.createCell(2).setCellValue(payment.getAmount());
                row.createCell(3).setCellValue(payment.getPaymentMethod().toString());
                row.createCell(4).setCellValue(payment.getStatus().toString());
                row.createCell(5).setCellValue(payment.getTransactionId() != null ? payment.getTransactionId() : "");
                row.createCell(6).setCellValue(payment.getPaymentDate() != null 
                        ? payment.getPaymentDate().format(DATE_FORMATTER) : "");
                row.createCell(7).setCellValue(payment.getNotes() != null ? payment.getNotes() : "");
            }

            // Auto-size columns
            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }

            workbook.write(baos);
            return baos.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate Excel export: " + e.getMessage(), e);
        }
    }
}



















