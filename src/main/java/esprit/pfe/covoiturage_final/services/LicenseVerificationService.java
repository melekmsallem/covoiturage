package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Conducteur;
import esprit.pfe.covoiturage_final.repositories.ConducteurRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class LicenseVerificationService {

    @Autowired
    private ConducteurRepository conducteurRepository;

    /**
     * Upload license image for a driver
     */
    public void uploadLicenseImage(Long driverId, String imagePath) {
        Optional<Conducteur> driverOpt = conducteurRepository.findById(driverId);
        if (driverOpt.isPresent()) {
            Conducteur driver = driverOpt.get();
            driver.setLicenseImagePath(imagePath);
            driver.setLicenseVerified(false); // Reset verification status
            conducteurRepository.save(driver);
        } else {
            throw new RuntimeException("Driver not found with ID: " + driverId);
        }
    }

    /**
     * Verify a driver's license (admin action)
     */
    public void verifyLicense(Long driverId, boolean verified) {
        Optional<Conducteur> driverOpt = conducteurRepository.findById(driverId);
        if (driverOpt.isPresent()) {
            Conducteur driver = driverOpt.get();
            driver.setLicenseVerified(verified);
            if (verified) {
                driver.setLicenseVerificationDate(LocalDateTime.now());
                driver.setIsVerified(true); // Also mark driver as verified
            } else {
                driver.setLicenseVerificationDate(null);
                driver.setIsVerified(false);
            }
            conducteurRepository.save(driver);
        } else {
            throw new RuntimeException("Driver not found with ID: " + driverId);
        }
    }

    /**
     * Get drivers pending license verification
     */
    public List<Conducteur> getDriversPendingVerification() {
        return conducteurRepository.findByLicenseImagePathIsNotNullAndLicenseVerifiedFalse();
    }

    /**
     * Get verified drivers
     */
    public List<Conducteur> getVerifiedDrivers() {
        return conducteurRepository.findByLicenseVerifiedTrue();
    }

    /**
     * Check if driver's license is verified
     */
    public boolean isLicenseVerified(Long driverId) {
        Optional<Conducteur> driverOpt = conducteurRepository.findById(driverId);
        return driverOpt.map(Conducteur::getLicenseVerified).orElse(false);
    }

    /**
     * Get driver's license image path
     */
    public String getLicenseImagePath(Long driverId) {
        Optional<Conducteur> driverOpt = conducteurRepository.findById(driverId);
        return driverOpt.map(Conducteur::getLicenseImagePath).orElse(null);
    }
}








