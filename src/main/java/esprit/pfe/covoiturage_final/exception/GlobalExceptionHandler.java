package esprit.pfe.covoiturage_final.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(AccountSuspendedException.class)
    public ResponseEntity<?> handleAccountSuspendedException(AccountSuspendedException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("error", "Account Suspended");
        error.put("message", "Your account has been suspended.");
        error.put("reason", ex.getReason());
        error.put("suspensionEndDate", ex.getEndDate());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
    }

    @ExceptionHandler(LockedException.class)
    public ResponseEntity<?> handleLockedException(LockedException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("error", "Account Suspended");
        error.put("message", "Your account has been suspended. Please contact the administrator for more information.");
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
    }

    @ExceptionHandler(DisabledException.class)
    public ResponseEntity<?> handleDisabledException(DisabledException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("error", "Account Disabled");
        error.put("message", "Your account is disabled. Please contact the administrator.");
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
    }

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<?> handleBadCredentialsException(BadCredentialsException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("error", "Invalid Credentials");
        error.put("message", "Invalid username or password. Please try again.");
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
    }
}

