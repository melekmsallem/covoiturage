package esprit.pfe.covoiturage_final.utils;

import java.util.regex.Pattern;

public class ValidationUtils {
    
    // Tunisian license plate pattern: 3 numbers + TU + 4 numbers
    private static final Pattern TUNISIAN_LICENSE_PLATE_PATTERN = 
        Pattern.compile("^\\d{3}TU\\d{4}$");
    
    /**
     * Validates Tunisian license plate format
     * @param licensePlate the license plate to validate
     * @return true if valid, false otherwise
     */
    public static boolean isValidTunisianLicensePlate(String licensePlate) {
        if (licensePlate == null || licensePlate.trim().isEmpty()) {
            return false;
        }
        
        String cleanPlate = licensePlate.trim().toUpperCase();
        return TUNISIAN_LICENSE_PLATE_PATTERN.matcher(cleanPlate).matches();
    }
    
    /**
     * Formats a license plate to the standard Tunisian format
     * @param licensePlate the license plate to format
     * @return formatted license plate or null if invalid
     */
    public static String formatTunisianLicensePlate(String licensePlate) {
        if (licensePlate == null || licensePlate.trim().isEmpty()) {
            return null;
        }
        
        // Remove all non-alphanumeric characters and convert to uppercase
        String cleanPlate = licensePlate.replaceAll("[^0-9A-Za-z]", "").toUpperCase();
        
        // Check if it matches the pattern after cleaning
        if (TUNISIAN_LICENSE_PLATE_PATTERN.matcher(cleanPlate).matches()) {
            return cleanPlate;
        }
        
        return null;
    }
    
    /**
     * Gets the validation error message for license plate
     * @return the error message
     */
    public static String getLicensePlateErrorMessage() {
        return "License plate must follow Tunisian format: 3 numbers + TU + 4 numbers (e.g., 123TU4567)";
    }
}
















