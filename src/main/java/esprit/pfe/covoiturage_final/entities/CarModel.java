package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "car_models")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CarModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "brand", nullable = false)
    private String brand;

    @Column(name = "model", nullable = false)
    private String model;

    @Column(name = "year_from")
    private Integer yearFrom;

    @Column(name = "year_to")
    private Integer yearTo;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "category")
    private String category; // SEDAN, SUV, HATCHBACK, COUPE, etc.

    public CarModel(String brand, String model) {
        this.brand = brand;
        this.model = model;
        this.isActive = true;
    }

    public CarModel(String brand, String model, Integer yearFrom, Integer yearTo, String category) {
        this.brand = brand;
        this.model = model;
        this.yearFrom = yearFrom;
        this.yearTo = yearTo;
        this.category = category;
        this.isActive = true;
    }

    public String getFullName() {
        return brand + " " + model;
    }
}
















