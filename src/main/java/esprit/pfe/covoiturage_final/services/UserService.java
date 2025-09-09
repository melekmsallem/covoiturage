package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.SignInRequest;
import esprit.pfe.covoiturage_final.dto.SignUpRequest;
import esprit.pfe.covoiturage_final.dto.AuthResponse;
import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.entities.UserRole;

import java.util.List;

public interface UserService {
    AuthResponse signUp(SignUpRequest signUpRequest);
    AuthResponse signIn(SignInRequest signInRequest);
    User getUserById(Long id);
    User getUserByUsername(String username);
    List<User> getAllUsers();
    List<User> getUsersByRole(UserRole role);
    User updateUser(Long id, User userDetails);
    void deleteUser(Long id);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
}
