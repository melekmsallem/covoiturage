package esprit.pfe.covoiturage_final.exception;

import org.springframework.security.authentication.LockedException;

public class AccountSuspendedException extends LockedException {
    private String reason;
    private String endDate;

    public AccountSuspendedException(String msg, String reason, String endDate) {
        super(msg);
        this.reason = reason;
        this.endDate = endDate;
    }

    public String getReason() {
        return reason;
    }

    public String getEndDate() {
        return endDate;
    }
}

