package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.entities.Point_GPS;
import esprit.pfe.covoiturage_final.services.PickupPointService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/pickup-points")
@CrossOrigin(origins = "*")
public class PickupPointController {

    @Autowired
    private PickupPointService pickupPointService;

    @PostMapping("/trip/{tripId}")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public ResponseEntity<List<Point_GPS>> createPickupPoints(
            @PathVariable Long tripId,
            @RequestBody List<Point_GPS> pickupPoints) {
        try {
            List<Point_GPS> createdPoints = pickupPointService.createPickupPoints(tripId, pickupPoints);
            return ResponseEntity.ok(createdPoints);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/trip/{tripId}")
    public ResponseEntity<List<Point_GPS>> getPickupPoints(@PathVariable Long tripId) {
        try {
            List<Point_GPS> points = pickupPointService.getPickupPointsByTrip(tripId);
            return ResponseEntity.ok(points);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PutMapping("/{pointId}")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public ResponseEntity<Point_GPS> updatePickupPoint(
            @PathVariable Long pointId,
            @RequestBody Point_GPS updatedPoint) {
        try {
            Point_GPS point = pickupPointService.updatePickupPoint(pointId, updatedPoint);
            return ResponseEntity.ok(point);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @DeleteMapping("/{pointId}")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public ResponseEntity<Void> deletePickupPoint(@PathVariable Long pointId) {
        try {
            pickupPointService.deletePickupPoint(pointId);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/trip/{tripId}/optimize")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public ResponseEntity<List<Point_GPS>> optimizePickupRoute(@PathVariable Long tripId) {
        try {
            List<Point_GPS> optimizedPoints = pickupPointService.optimizePickupRoute(tripId);
            return ResponseEntity.ok(optimizedPoints);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/geocode")
    public ResponseEntity<String> getAddressFromCoordinates(
            @RequestParam Double latitude,
            @RequestParam Double longitude) {
        try {
            String address = pickupPointService.getAddressFromCoordinates(latitude, longitude);
            return ResponseEntity.ok(address);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
