package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.AuthResponse;
import esprit.pfe.covoiturage_final.dto.SignInRequest;
import esprit.pfe.covoiturage_final.dto.SignUpRequest;
import esprit.pfe.covoiturage_final.entities.*;
import esprit.pfe.covoiturage_final.repositories.ConducteurRepository;
import esprit.pfe.covoiturage_final.repositories.PassagerRepository;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import esprit.pfe.covoiturage_final.security.JwtUtils;
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
                Conducteur conducteur = new Conducteur(
                    signUpRequest.getUsername(),
                    signUpRequest.getEmail(),
                    passwordEncoder.encode(signUpRequest.getPassword()),
                    signUpRequest.getFirstName(),
                    signUpRequest.getLastName(),
                    signUpRequest.getPhoneNumber()
                );
                if (signUpRequest.getLicenseNumber() != null) {
                    conducteur.setLicenseNumber(signUpRequest.getLicenseNumber());
                }
                if (signUpRequest.getVehicleModel() != null) {
                    conducteur.setVehicleModel(signUpRequest.getVehicleModel());
                }
                if (signUpRequest.getVehicleColor() != null) {
                    conducteur.setVehicleColor(signUpRequest.getVehicleColor());
                }
                if (signUpRequest.getVehiclePlate() != null) {
                    conducteur.setVehiclePlate(signUpRequest.getVehiclePlate());
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
        Authentication authentication = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(signInRequest.getUsernameOrEmail(), signInRequest.getPassword())
        );

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);

        User user = userRepository.findByUsernameOrEmail(signInRequest.getUsernameOrEmail(), signInRequest.getUsernameOrEmail())
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
        
        user.setFirstName(userDetails.getFirstName());
        user.setLastName(userDetails.getLastName());
        user.setPhoneNumber(userDetails.getPhoneNumber());
        user.setEmail(userDetails.getEmail());
        
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
}
