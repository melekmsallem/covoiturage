package esprit.pfe.covoiturage_final.config;

import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.entities.UserRole;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class AdminInitializer implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        // Check if admin user already exists
        if (!userRepository.existsByUsername("admin")) {
            User admin = new User();
            admin.setUsername("admin");
            admin.setEmail("admin@covoiturage.com");
            admin.setPassword(passwordEncoder.encode("admin123"));
            admin.setFirstName("Admin");
            admin.setLastName("System");
            admin.setPhoneNumber("+216 12 345 678");
            admin.setRole(UserRole.ADMIN);
            admin.setIsActive(true);
            admin.setIsVerified(true);

            userRepository.save(admin);
            System.out.println("✅ Admin user created successfully!");
            System.out.println("   Username: admin");
            System.out.println("   Password: admin123");
            System.out.println("   Email: admin@covoiturage.com");
        } else {
            // Update existing admin user to ensure correct password
            User existingAdmin = userRepository.findByUsername("admin").orElse(null);
            if (existingAdmin != null) {
                existingAdmin.setPassword(passwordEncoder.encode("admin123"));
                existingAdmin.setRole(UserRole.ADMIN);
                existingAdmin.setIsActive(true);
                existingAdmin.setIsVerified(true);
                userRepository.save(existingAdmin);
                System.out.println("✅ Admin user updated successfully!");
                System.out.println("   Username: admin");
                System.out.println("   Password: admin123");
                System.out.println("   Email: admin@covoiturage.com");
            } else {
                System.out.println("ℹ️  Admin user already exists");
            }
        }
    }
}
