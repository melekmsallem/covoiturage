package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.AuthResponse;
import esprit.pfe.covoiturage_final.dto.SignInRequest;
import esprit.pfe.covoiturage_final.dto.SignUpRequest;
import esprit.pfe.covoiturage_final.entities.*;
import esprit.pfe.covoiturage_final.repositories.ConducteurRepository;
import esprit.pfe.covoiturage_final.repositories.PassagerRepository;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import esprit.pfe.covoiturage_final.security.JwtUtils;
import esprit.pfe.covoiturage_final.utils.ValidationUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserServiceImpl implements UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PassagerRepository passagerRepository;

    @Autowired
    private ConducteurRepository conducteurRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private CoinService coinService;

    @Override
    public AuthResponse signUp(SignUpRequest signUpRequest) {
        // Check if username or email already exists
        if (userRepository.existsByUsername(signUpRequest.getUsername())) {
            throw new RuntimeException("Username is already taken!");
        }

        if (userRepository.existsByEmail(signUpRequest.getEmail())) {
            throw new RuntimeException("Email is already in use!");
        }

        // Create user based on role
        User user;
        switch (signUpRequest.getRole()) {
            case PASSAGER:
                Passager passager = new Passager(
                    signUpRequest.getUsername(),
                    signUpRequest.getEmail(),
                    passwordEncoder.encode(signUpRequest.getPassword()),
                    signUpRequest.getFirstName(),
                    signUpRequest.getLastName(),
                    signUpRequest.getPhoneNumber()
                );
                if (signUpRequest.getPreferredPaymentMethod() != null) {
                    passager.setPreferredPaymentMethod(signUpRequest.getPreferredPaymentMethod());
                }
                user = passagerRepository.save(passager);
                break;

            case CONDUCTEUR:
                // Validate that license number is provided for drivers
                if (signUpRequest.getLicenseNumber() == null || signUpRequest.getLicenseNumber().trim().isEmpty()) {
                    throw new RuntimeException("License number is required for drivers");
                }
                
                Conducteur conducteur = new Conducteur(
                    signUpRequest.getUsername(),
                    signUpRequest.getEmail(),
                    passwordEncoder.encode(signUpRequest.getPassword()),
                    signUpRequest.getFirstName(),
                    signUpRequest.getLastName(),
                    signUpRequest.getPhoneNumber()
                );
                conducteur.setLicenseNumber(signUpRequest.getLicenseNumber().trim());
                
                if (signUpRequest.getVehicleModel() != null) {
                    conducteur.setVehicleModel(signUpRequest.getVehicleModel());
                }
                if (signUpRequest.getVehicleColor() != null) {
                    conducteur.setVehicleColor(signUpRequest.getVehicleColor());
                }
                if (signUpRequest.getVehiclePlate() != null) {
                    // Validate and format the license plate
                    String formattedPlate = ValidationUtils.formatTunisianLicensePlate(signUpRequest.getVehiclePlate());
                    if (formattedPlate == null) {
                        throw new RuntimeException(ValidationUtils.getLicensePlateErrorMessage());
                    }
                    conducteur.setVehiclePlate(formattedPlate);
                }
                if (signUpRequest.getMaxPassengers() != null) {
                    conducteur.setMaxPassengers(signUpRequest.getMaxPassengers());
                }
                user = conducteurRepository.save(conducteur);
                break;

            case ADMIN:
                Admin admin = new Admin(
                    signUpRequest.getUsername(),
                    signUpRequest.getEmail(),
                    passwordEncoder.encode(signUpRequest.getPassword()),
                    signUpRequest.getFirstName(),
                    signUpRequest.getLastName(),
                    signUpRequest.getPhoneNumber()
                );
                user = userRepository.save(admin);
                break;

            default:
                throw new RuntimeException("Invalid user role!");
        }

        // Initialize coin balance for new user (100 coins as welcome bonus)
        try {
            System.out.println("Initializing coin balance for user " + user.getId() + " with 100 coins");
            CoinTransaction transaction = coinService.addBonusCoins(
                user.getId(), 
                100.0, 
                "Welcome bonus for new account"
            );
            System.out.println("Coin balance initialized successfully. Transaction ID: " + transaction.getId());
            
            // Verify the balance was set correctly
            Double balance = coinService.getUserBalance(user.getId());
            System.out.println("User " + user.getId() + " coin balance: " + balance);
        } catch (Exception e) {
            // Log error but don't fail the registration
            System.err.println("Failed to initialize coin balance for user " + user.getId() + ": " + e.getMessage());
            e.printStackTrace();
        }

        // Generate JWT token
        Authentication authentication = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(signUpRequest.getUsername(), signUpRequest.getPassword())
        );

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);

        return new AuthResponse(jwt, "Bearer", user.getId(), user.getUsername(), 
                              user.getEmail(), user.getFirstName(), user.getLastName(), user.getRole());
    }

    @Override
    public AuthResponse signIn(SignInRequest signInRequest) {
        String identifier = signInRequest.getUsernameOrEmail() == null ? "" : signInRequest.getUsernameOrEmail().trim();
        Authentication authentication = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(identifier, signInRequest.getPassword())
        );

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);

        User user = userRepository.findByUsernameOrEmail(identifier, identifier)
            .orElseThrow(() -> new RuntimeException("User not found"));

        return new AuthResponse(jwt, "Bearer", user.getId(), user.getUsername(), 
                              user.getEmail(), user.getFirstName(), user.getLastName(), user.getRole());
    }

    @Override
    public User getUserById(Long id) {
        return userRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
    }

    @Override
    public User getUserByUsername(String username) {
        return userRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("User not found with username: " + username));
    }

    @Override
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    @Override
    public List<User> getUsersByRole(UserRole role) {
        return userRepository.findByRole(role);
    }

    @Override
    public User updateUser(Long id, User userDetails) {
        User user = getUserById(id);
        
        // Update basic user fields
        if (userDetails.getFirstName() != null) {
            user.setFirstName(userDetails.getFirstName());
        }
        if (userDetails.getLastName() != null) {
            user.setLastName(userDetails.getLastName());
        }
        if (userDetails.getPhoneNumber() != null) {
            user.setPhoneNumber(userDetails.getPhoneNumber());
        }
        if (userDetails.getEmail() != null) {
            user.setEmail(userDetails.getEmail());
        }
        
        // Update driver-specific fields if user is a Conducteur
        if (user instanceof Conducteur && userDetails instanceof Conducteur) {
            Conducteur driver = (Conducteur) user;
            Conducteur driverDetails = (Conducteur) userDetails;
            
            if (driverDetails.getLicenseNumber() != null) {
                driver.setLicenseNumber(driverDetails.getLicenseNumber());
            }
            if (driverDetails.getLicenseImagePath() != null) {
                // Normalize path separators (Windows backslashes to forward slashes)
                String normalizedPath = driverDetails.getLicenseImagePath().replace('\\', '/');
                driver.setLicenseImagePath(normalizedPath);
            }
            if (driverDetails.getLicenseVerified() != null) {
                driver.setLicenseVerified(driverDetails.getLicenseVerified());
            }
            if (driverDetails.getIsVerified() != null) {
                driver.setIsVerified(driverDetails.getIsVerified());
            }
            if (driverDetails.getVehicleModel() != null) {
                driver.setVehicleModel(driverDetails.getVehicleModel());
            }
            if (driverDetails.getVehicleColor() != null) {
                driver.setVehicleColor(driverDetails.getVehicleColor());
            }
            // Only update vehiclePlate if a new valid value is explicitly provided
            // During verification submission, we don't update vehiclePlate, so we skip it here
            // This prevents validation errors if the existing vehiclePlate has an invalid format
            if (driverDetails.getVehiclePlate() != null && !driverDetails.getVehiclePlate().trim().isEmpty()) {
                String formattedPlate = ValidationUtils.formatTunisianLicensePlate(driverDetails.getVehiclePlate());
                if (formattedPlate != null) {
                    driver.setVehiclePlate(formattedPlate);
                }
                // If invalid format, don't update - keep existing value to avoid validation error
            }
            // If vehiclePlate is null or empty in driverDetails, don't update it (preserve existing value)
        }
        
        return userRepository.save(user);
    }

    @Override
    public void deleteUser(Long id) {
        User user = getUserById(id);
        user.setIsActive(false);
        userRepository.save(user);
    }

    @Override
    public boolean existsByUsername(String username) {
        return userRepository.existsByUsername(username);
    }

    @Override
    public boolean existsByEmail(String email) {
        return userRepository.existsByEmail(email);
    }

    @Override
    public User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null) {
            throw new RuntimeException("User not authenticated - no authentication found");
        }
        
        if (!authentication.isAuthenticated()) {
            throw new RuntimeException("User not authenticated - authentication not authenticated");
        }
        
        Object principal = authentication.getPrincipal();
        System.out.println("DEBUG: getCurrentUser - Principal type: " + 
            (principal != null ? principal.getClass().getName() : "null"));
        
        // If principal is directly our User entity, return it
        if (principal instanceof User user) {
            System.out.println("DEBUG: getCurrentUser - Found User entity directly, ID: " + user.getId());
            return user;
        }
        
        final String identifier;
        if (principal instanceof org.springframework.security.core.userdetails.User userDetails) {
            identifier = userDetails.getUsername();
            System.out.println("DEBUG: getCurrentUser - Found Spring UserDetails, username: " + identifier);
        } else if (principal instanceof String s && !"anonymousUser".equals(s)) {
            identifier = s;
            System.out.println("DEBUG: getCurrentUser - Found String principal: " + identifier);
        } else {
            System.out.println("DEBUG: getCurrentUser - Invalid principal type: " + 
                (principal != null ? principal.getClass().getName() : "null"));
            throw new RuntimeException("User not authenticated - invalid principal type: " + 
                (principal != null ? principal.getClass().getName() : "null"));
        }
        
        User foundUser = userRepository.findByUsername(identifier)
            .orElseGet(() -> userRepository.findByEmail(identifier)
                .orElse(null));
        
        if (foundUser == null) {
            throw new RuntimeException("User not found for principal: " + identifier);
        }
        
        System.out.println("DEBUG: getCurrentUser - Found user by identifier, ID: " + foundUser.getId());
        return foundUser;
    }
}
