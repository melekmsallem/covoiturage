package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.entities.Option;
import esprit.pfe.covoiturage_final.repositories.OptionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/options")
@CrossOrigin(origins = "*", maxAge = 3600)
public class OptionController {
    
    @Autowired
    private OptionRepository optionRepository;
    
    @GetMapping
    public ResponseEntity<List<Option>> getAllOptions() {
        List<Option> options = optionRepository.findByIsActiveTrue();
        return ResponseEntity.ok(options);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<?> getOption(@PathVariable Long id) {
        try {
            Option option = optionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Option not found"));
            return ResponseEntity.ok(option);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/search")
    public ResponseEntity<List<Option>> searchOptions(@RequestParam String name) {
        List<Option> options = optionRepository.findByNameContainingIgnoreCase(name);
        return ResponseEntity.ok(options);
    }
    
    @GetMapping("/price-range")
    public ResponseEntity<List<Option>> getOptionsByPriceRange(
            @RequestParam Double minPrice, 
            @RequestParam Double maxPrice) {
        List<Option> options = optionRepository.findByPriceBetween(minPrice, maxPrice);
        return ResponseEntity.ok(options);
    }
}
