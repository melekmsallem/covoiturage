package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.entities.CarModel;
import esprit.pfe.covoiturage_final.services.CarModelService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/car-models")
@CrossOrigin(origins = "*", maxAge = 3600)
public class CarModelController {

    @Autowired
    private CarModelService carModelService;

    @GetMapping
    public ResponseEntity<List<CarModel>> getAllCarModels() {
        List<CarModel> carModels = carModelService.getAllCarModels();
        return ResponseEntity.ok(carModels);
    }

    @GetMapping("/search")
    public ResponseEntity<List<CarModel>> searchCarModels(@RequestParam String query) {
        List<CarModel> carModels = carModelService.searchCarModels(query);
        return ResponseEntity.ok(carModels);
    }

    @GetMapping("/brands")
    public ResponseEntity<List<String>> getAllBrands() {
        List<String> brands = carModelService.getAllBrands();
        return ResponseEntity.ok(brands);
    }

    @GetMapping("/brand/{brand}")
    public ResponseEntity<List<CarModel>> getModelsByBrand(@PathVariable String brand) {
        List<CarModel> models = carModelService.getModelsByBrand(brand);
        return ResponseEntity.ok(models);
    }

    @PostMapping("/initialize")
    public ResponseEntity<String> initializeCarModels() {
        try {
            carModelService.initializeCarModelsData();
            return ResponseEntity.ok("Car models data initialized successfully");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to initialize car models: " + e.getMessage());
        }
    }

    @GetMapping("/count")
    public ResponseEntity<Long> getCarModelCount() {
        try {
            long count = carModelService.getCarModelCount();
            return ResponseEntity.ok(count);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(0L);
        }
    }
}
