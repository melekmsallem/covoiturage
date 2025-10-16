package esprit.pfe.covoiturage_final.entities;

import com.fasterxml.jackson.annotation.JsonValue;

public enum UserRole {
    PASSAGER("Passager"),
    CONDUCTEUR("Conducteur"),
    ADMIN("Admin");
    
    private final String displayName;
    
    UserRole(String displayName) {
        this.displayName = displayName;
    }
    
    @JsonValue
    public String getDisplayName() {
        return displayName;
    }
    
    @Override
    public String toString() {
        return displayName;
    }
}
