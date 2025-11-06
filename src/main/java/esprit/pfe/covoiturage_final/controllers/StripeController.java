package esprit.pfe.covoiturage_final.controllers;

import com.stripe.Stripe;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.model.checkout.Session;
import com.stripe.model.Event;
import com.stripe.net.Webhook;
import com.stripe.param.checkout.SessionCreateParams;
import esprit.pfe.covoiturage_final.entities.CoinTransaction;
import esprit.pfe.covoiturage_final.services.CoinService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
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

    private final CoinService coinService;

    public StripeController(CoinService coinService) {
        this.coinService = coinService;
    }

    @PostMapping("/checkout-session/coins")
    public ResponseEntity<?> createCoinPurchaseSession(
            @RequestParam Long userId,
            @RequestParam Double coinAmount,
            Authentication authentication) {
        try {
            if (stripeSecretKey == null || stripeSecretKey.isBlank()) {
                log.error("Stripe checkout session failed: secret key not configured for coin purchase");
                return ResponseEntity.status(HttpStatus.PRECONDITION_REQUIRED)
                        .body("Stripe secret key not configured");
            }
            Stripe.apiKey = stripeSecretKey;
            log.info("Creating Stripe checkout session for coin purchase: userId={}, amount={}", userId, coinAmount);

            if (!coinService.validateCoinAmount(coinAmount)) {
                return ResponseEntity.badRequest().body("Invalid coin amount");
            }

            long amountEurCents = toEurCents(coinAmount);

            SessionCreateParams params = SessionCreateParams.builder()
                    .setMode(SessionCreateParams.Mode.PAYMENT)
                    .setSuccessUrl(successUrl + "?type=coins&userId=" + userId)
                    .setCancelUrl(cancelUrl + "?type=coins&userId=" + userId)
                    .addLineItem(SessionCreateParams.LineItem.builder()
                            .setQuantity(1L)
                            .setPriceData(SessionCreateParams.LineItem.PriceData.builder()
                                    .setCurrency(stripeCurrency.toLowerCase())
                                    .setUnitAmount(amountEurCents)
                                    .setProductData(SessionCreateParams.LineItem.PriceData.ProductData.builder()
                                            .setName("Coins Purchase - " + coinAmount + " coins")
                                            .setDescription("Purchase " + coinAmount + " coins for carpooling")
                                            .build())
                                    .build())
                            .build())
                    .putMetadata("userId", String.valueOf(userId))
                    .putMetadata("coinAmount", String.valueOf(coinAmount))
                    .putMetadata("type", "coin_purchase")
                    .build();

            Session session = Session.create(params);

            Map<String, Object> resp = new HashMap<>();
            resp.put("url", session.getUrl());
            resp.put("sessionId", session.getId());
            resp.put("coinAmount", coinAmount);
            log.info("Stripe checkout session created successfully for coin purchase: userId={}, sessionId={}", userId, session.getId());
            return ResponseEntity.ok(resp);
        } catch (Exception e) {
            log.error("Failed to create Stripe checkout session for coin purchase: userId={}, error={}", userId, e.getMessage(), e);
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
                String type = session.getMetadata() != null ? session.getMetadata().get("type") : null;
                
                if ("coin_purchase".equals(type)) {
                    // Handle coin purchase
                    String userIdStr = session.getMetadata() != null ? session.getMetadata().get("userId") : null;
                    String coinAmountStr = session.getMetadata() != null ? session.getMetadata().get("coinAmount") : null;
                    
                    if (userIdStr != null && coinAmountStr != null) {
                        try {
                            Long userId = Long.parseLong(userIdStr);
                            Double coinAmount = Double.parseDouble(coinAmountStr);
                            String stripePaymentId = session.getPaymentIntent();
                            
                            coinService.purchaseCoins(userId, coinAmount, stripePaymentId);
                            log.info("Coins purchased successfully via webhook: userId={}, amount={}, stripePaymentId={}", userId, coinAmount, stripePaymentId);
                        } catch (Exception e) {
                            log.error("Failed to process coin purchase from webhook: userId={}, amount={}, error={}", userIdStr, coinAmountStr, e.getMessage(), e);
                        }
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


