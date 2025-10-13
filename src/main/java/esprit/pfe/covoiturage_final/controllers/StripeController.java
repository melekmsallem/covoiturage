package esprit.pfe.covoiturage_final.controllers;

import com.stripe.Stripe;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.model.checkout.Session;
import com.stripe.model.Event;
import com.stripe.net.Webhook;
import com.stripe.param.checkout.SessionCreateParams;
import esprit.pfe.covoiturage_final.entities.Paiement;
import esprit.pfe.covoiturage_final.entities.Reservation;
import esprit.pfe.covoiturage_final.repositories.ReservationRepository;
import esprit.pfe.covoiturage_final.services.PaymentService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/stripe")
@CrossOrigin(origins = "*", maxAge = 3600)
public class StripeController {

    private static final Logger log = LoggerFactory.getLogger(StripeController.class);

    @Value("${stripe.secret-key:}")
    private String stripeSecretKey;

    @Value("${stripe.webhook-secret:}")
    private String stripeWebhookSecret;

    @Value("${stripe.currency:EUR}")
    private String stripeCurrency;

    @Value("${payments.tnd-to-eur-rate:0.29}")
    private double tndToEurRate;

    @Value("${stripe.success-url}")
    private String successUrl;

    @Value("${stripe.cancel-url}")
    private String cancelUrl;

    private final ReservationRepository reservationRepository;
    private final PaymentService paymentService;

    public StripeController(ReservationRepository reservationRepository, PaymentService paymentService) {
        this.reservationRepository = reservationRepository;
        this.paymentService = paymentService;
    }

    @PostMapping("/checkout-session/{reservationId}")
    public ResponseEntity<?> createCheckoutSession(@PathVariable Long reservationId) {
        try {
            if (stripeSecretKey == null || stripeSecretKey.isBlank()) {
                log.error("Stripe checkout session failed: secret key not configured for reservation {}", reservationId);
                return ResponseEntity.status(HttpStatus.PRECONDITION_REQUIRED)
                        .body("Stripe secret key not configured");
            }
            Stripe.apiKey = stripeSecretKey;
            log.info("Creating Stripe checkout session for reservation {}", reservationId);

            Reservation reservation = reservationRepository.findById(reservationId)
                    .orElseThrow(() -> new RuntimeException("Reservation not found"));

            // Require confirmed reservation for Stripe checkout
            if (reservation.getStatus() != Reservation.ReservationStatus.CONFIRMED) {
                return ResponseEntity.badRequest().body("Reservation must be CONFIRMED");
            }

            double amountTnd = reservation.getTotalPrice() == null ? 0.0 : reservation.getTotalPrice();
            if (amountTnd <= 0) {
                return ResponseEntity.badRequest().body("Invalid reservation amount");
            }

            // Create or reuse a pending local payment
            Paiement localPayment;
            try {
                localPayment = paymentService.createPayment(reservationId, Paiement.PaymentMethod.CREDIT_CARD, amountTnd);
            } catch (RuntimeException ex) {
                Paiement existing = paymentService.getPaymentByReservationId(reservationId);
                if (existing == null) throw ex;
                localPayment = existing;
            }

            long amountEurCents = toEurCents(amountTnd);

            SessionCreateParams params = SessionCreateParams.builder()
                    .setMode(SessionCreateParams.Mode.PAYMENT)
                    .setSuccessUrl(successUrl)
                    .setCancelUrl(cancelUrl)
                    .addLineItem(SessionCreateParams.LineItem.builder()
                            .setQuantity(1L)
                            .setPriceData(SessionCreateParams.LineItem.PriceData.builder()
                                    .setCurrency(stripeCurrency.toLowerCase())
                                    .setUnitAmount(amountEurCents)
                                    .setProductData(SessionCreateParams.LineItem.PriceData.ProductData.builder()
                                            .setName("Reservation #" + reservation.getId())
                                            .build())
                                    .build())
                            .build())
                    .putMetadata("paymentId", String.valueOf(localPayment.getId()))
                    .putMetadata("reservationId", String.valueOf(reservationId))
                    .build();

            Session session = Session.create(params);

            Map<String, Object> resp = new HashMap<>();
            resp.put("url", session.getUrl());
            resp.put("sessionId", session.getId());
            log.info("Stripe checkout session created successfully for reservation {}: sessionId={}", reservationId, session.getId());
            return ResponseEntity.ok(resp);
        } catch (Exception e) {
            log.error("Failed to create Stripe checkout session for reservation {}: {}", reservationId, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(e.getMessage());
        }
    }

    @PostMapping("/webhook")
    public ResponseEntity<String> handleWebhook(@RequestHeader("Stripe-Signature") String sigHeader,
                                                @RequestBody String payload) {
        if (stripeWebhookSecret == null || stripeWebhookSecret.isBlank()) {
            log.warn("Stripe webhook rejected: secret not configured");
            return new ResponseEntity<>("Webhook secret not configured", HttpStatus.PRECONDITION_REQUIRED);
        }
        Event event;
        try {
            event = Webhook.constructEvent(payload, sigHeader, stripeWebhookSecret);
        } catch (SignatureVerificationException e) {
            log.error("Stripe webhook signature verification failed: {}", e.getMessage());
            return new ResponseEntity<>("Invalid signature", HttpStatus.BAD_REQUEST);
        }

        log.info("Stripe webhook received: type={}, id={}", event.getType(), event.getId());

        if ("checkout.session.completed".equals(event.getType())) {
            Session session = (Session) event.getDataObjectDeserializer().getObject().orElse(null);
            if (session != null) {
                String paymentIdStr = session.getMetadata() != null ? session.getMetadata().get("paymentId") : null;
                String reservationIdStr = session.getMetadata() != null ? session.getMetadata().get("reservationId") : null;
                if (paymentIdStr != null) {
                    try {
                        Long paymentId = Long.parseLong(paymentIdStr);
                        String transactionId = session.getPaymentIntent();
                        paymentService.processPayment(paymentId, transactionId, "Stripe Checkout completed");
                        log.info("Payment {} processed successfully via webhook for reservation {}", paymentId, reservationIdStr);
                    } catch (Exception e) {
                        log.error("Failed to process payment from webhook: paymentId={}, error={}", paymentIdStr, e.getMessage(), e);
                    }
                }
            }
        }
        return new ResponseEntity<>("OK", HttpStatus.OK);
    }

    private long toEurCents(double amountTnd) {
        BigDecimal eur = BigDecimal.valueOf(amountTnd)
                .multiply(BigDecimal.valueOf(tndToEurRate))
                .setScale(2, RoundingMode.HALF_UP);
        return eur.multiply(BigDecimal.valueOf(100)).longValue();
    }
}


