package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.entities.Ville;
import esprit.pfe.covoiturage_final.repositories.VilleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/cities")
@CrossOrigin(origins = "*", maxAge = 3600)
public class CityController {
    
    @Autowired
    private VilleRepository villeRepository;
    
    @GetMapping
    public ResponseEntity<List<Ville>> getAllCities() {
        List<Ville> cities = villeRepository.findAll();
        return ResponseEntity.ok(cities);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<?> getCity(@PathVariable Long id) {
        try {
            Ville city = villeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("City not found"));
            return ResponseEntity.ok(city);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/search")
    public ResponseEntity<List<Ville>> searchCities(@RequestParam String name) {
        List<Ville> cities = villeRepository.findByNameContainingIgnoreCase(name);
        return ResponseEntity.ok(cities);
    }
    
    @GetMapping("/by-name/{name}")
    public ResponseEntity<?> getCityByName(@PathVariable String name) {
        Optional<Ville> city = villeRepository.findByName(name);
        if (city.isPresent()) {
            return ResponseEntity.ok(city.get());
        } else {
            return ResponseEntity.notFound().build();
        }
    }
    
    @GetMapping("/by-country")
    public ResponseEntity<List<Ville>> getCitiesByCountry(@RequestParam String country) {
        List<Ville> cities = villeRepository.findByPays(country);
        return ResponseEntity.ok(cities);
    }
    
    @GetMapping("/by-postal-code")
    public ResponseEntity<List<Ville>> getCitiesByPostalCode(@RequestParam String postalCode) {
        List<Ville> cities = villeRepository.findByCodePostal(postalCode);
        return ResponseEntity.ok(cities);
    }
}
