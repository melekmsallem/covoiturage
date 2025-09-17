package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "options")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Option {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "name", nullable = false)
    private String name;
    
    @Column(name = "description")
    private String description;
    
    @Column(name = "price", nullable = false)
    private Double price;
    
    @Column(name = "category", nullable = false)
    @Enumerated(EnumType.STRING)
    private OptionCategory category;
    
    @Column(name = "icon_name")
    private String iconName;
    
    @Column(name = "is_active")
    private Boolean isActive = true;
    
    @Column(name = "sort_order")
    private Integer sortOrder = 0;
    
    // Relationship will be managed by Voyage entity
    
    public enum OptionCategory {
        COMFORT("Comfort"),
        SAFETY("Safety"),
        PETS("Pets"),
        LUGGAGE("Luggage"),
        ENTERTAINMENT("Entertainment"),
        FOOD("Food & Drinks"),
        OTHER("Other");
        
        private final String displayName;
        
        OptionCategory(String displayName) {
            this.displayName = displayName;
        }
        
        public String getDisplayName() {
            return displayName;
        }
    }
}
