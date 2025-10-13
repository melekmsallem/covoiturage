package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.exception.AccountSuspendedException;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {
    @Autowired
    UserRepository userRepository;

    @Override
    @Transactional
    public UserDetails loadUserByUsername(String usernameOrEmail) throws UsernameNotFoundException {
        // Accept either username or email uniformly and trim potential whitespace
        final String identifier = usernameOrEmail == null ? "" : usernameOrEmail.trim();

        User user = userRepository
                .findByUsernameOrEmail(identifier, identifier)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "User Not Found with username or email: " + identifier));

        // Check if user is suspended and throw custom exception with suspension details
        if (!user.getIsActive()) {
            String endDate = user.getSuspensionEndDate() != null ? 
                user.getSuspensionEndDate().toString() : "Indefinite";
            throw new AccountSuspendedException(
                "Your account has been suspended", 
                user.getSuspensionReason() != null ? user.getSuspensionReason() : "No reason provided",
                endDate
            );
        }

        return user; // User already implements UserDetails
    }
}
