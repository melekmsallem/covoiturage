package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.CarModel;
import esprit.pfe.covoiturage_final.repositories.CarModelRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CarModelServiceImpl implements CarModelService {

    @Autowired
    private CarModelRepository carModelRepository;

    @Override
    public List<CarModel> getAllCarModels() {
        // First attempt
        List<CarModel> models = carModelRepository.findByIsActiveTrueOrderByBrandAscModelAsc();

        // If empty, try to initialize then re-query (covers cases where table has rows but none active)
        if (models.isEmpty()) {
            initializeCarModelsData();
            models = carModelRepository.findByIsActiveTrueOrderByBrandAscModelAsc();
        }

        return models;
    }

    @Override
    public List<CarModel> searchCarModels(String query) {
        if (query == null || query.trim().isEmpty()) {
            return getAllCarModels();
        }
        List<CarModel> results = carModelRepository.searchByBrandOrModel(query.trim());
        if (results.isEmpty()) {
            // Ensure data exists if search returns nothing on a fresh DB
            if (carModelRepository.count() == 0) {
                initializeCarModelsData();
                results = carModelRepository.searchByBrandOrModel(query.trim());
            }
        }
        return results;
    }

    @Override
    public List<String> getAllBrands() {
        return carModelRepository.findDistinctBrands();
    }

    @Override
    public List<CarModel> getModelsByBrand(String brand) {
        return carModelRepository.findByBrandAndIsActiveTrueOrderByModelAsc(brand);
    }

    @Override
    public CarModel saveCarModel(CarModel carModel) {
        return carModelRepository.save(carModel);
    }

    @Override
    public void initializeCarModelsData() {
        // Seed if there are no ACTIVE models (even if table has some inactive rows)
        if (carModelRepository.countByIsActiveTrue() > 0) {
            return;
        }

        // Popular car brands and models
        List<CarModel> carModels = List.of(
            // Renault
            new CarModel("Renault", "Clio", 2019, 2024, "HATCHBACK"),
            new CarModel("Renault", "Megane", 2016, 2024, "SEDAN"),
            new CarModel("Renault", "Captur", 2013, 2024, "SUV"),
            new CarModel("Renault", "Kadjar", 2015, 2022, "SUV"),
            new CarModel("Renault", "Talisman", 2015, 2022, "SEDAN"),
            new CarModel("Renault", "Koleos", 2016, 2024, "SUV"),
            new CarModel("Renault", "Twingo", 2014, 2024, "HATCHBACK"),
            new CarModel("Renault", "Sandero", 2012, 2024, "HATCHBACK"),
            new CarModel("Renault", "Duster", 2011, 2024, "SUV"),
            new CarModel("Renault", "Logan", 2004, 2024, "SEDAN"),

            // Mercedes-Benz
            new CarModel("Mercedes-Benz", "C-Class", 2014, 2024, "SEDAN"),
            new CarModel("Mercedes-Benz", "E-Class", 2016, 2024, "SEDAN"),
            new CarModel("Mercedes-Benz", "S-Class", 2013, 2024, "SEDAN"),
            new CarModel("Mercedes-Benz", "A-Class", 2018, 2024, "HATCHBACK"),
            new CarModel("Mercedes-Benz", "GLA", 2013, 2024, "SUV"),
            new CarModel("Mercedes-Benz", "GLC", 2015, 2024, "SUV"),
            new CarModel("Mercedes-Benz", "GLE", 2015, 2024, "SUV"),
            new CarModel("Mercedes-Benz", "GLS", 2016, 2024, "SUV"),
            new CarModel("Mercedes-Benz", "CLA", 2013, 2024, "COUPE"),
            new CarModel("Mercedes-Benz", "CLS", 2018, 2024, "COUPE"),

            // BMW
            new CarModel("BMW", "1 Series", 2019, 2024, "HATCHBACK"),
            new CarModel("BMW", "2 Series", 2014, 2024, "COUPE"),
            new CarModel("BMW", "3 Series", 2019, 2024, "SEDAN"),
            new CarModel("BMW", "4 Series", 2013, 2024, "COUPE"),
            new CarModel("BMW", "5 Series", 2017, 2024, "SEDAN"),
            new CarModel("BMW", "7 Series", 2015, 2024, "SEDAN"),
            new CarModel("BMW", "X1", 2015, 2024, "SUV"),
            new CarModel("BMW", "X3", 2017, 2024, "SUV"),
            new CarModel("BMW", "X5", 2018, 2024, "SUV"),
            new CarModel("BMW", "X7", 2019, 2024, "SUV"),

            // Audi
            new CarModel("Audi", "A1", 2018, 2024, "HATCHBACK"),
            new CarModel("Audi", "A3", 2013, 2024, "SEDAN"),
            new CarModel("Audi", "A4", 2016, 2024, "SEDAN"),
            new CarModel("Audi", "A6", 2018, 2024, "SEDAN"),
            new CarModel("Audi", "A8", 2017, 2024, "SEDAN"),
            new CarModel("Audi", "Q2", 2016, 2024, "SUV"),
            new CarModel("Audi", "Q3", 2018, 2024, "SUV"),
            new CarModel("Audi", "Q5", 2017, 2024, "SUV"),
            new CarModel("Audi", "Q7", 2015, 2024, "SUV"),
            new CarModel("Audi", "Q8", 2018, 2024, "SUV"),

            // Volkswagen
            new CarModel("Volkswagen", "Polo", 2017, 2024, "HATCHBACK"),
            new CarModel("Volkswagen", "Golf", 2019, 2024, "HATCHBACK"),
            new CarModel("Volkswagen", "Passat", 2014, 2024, "SEDAN"),
            new CarModel("Volkswagen", "Arteon", 2017, 2024, "SEDAN"),
            new CarModel("Volkswagen", "Tiguan", 2016, 2024, "SUV"),
            new CarModel("Volkswagen", "Touareg", 2018, 2024, "SUV"),
            new CarModel("Volkswagen", "T-Cross", 2018, 2024, "SUV"),
            new CarModel("Volkswagen", "T-Roc", 2017, 2024, "SUV"),
            new CarModel("Volkswagen", "ID.3", 2020, 2024, "HATCHBACK"),
            new CarModel("Volkswagen", "ID.4", 2020, 2024, "SUV"),

            // Peugeot
            new CarModel("Peugeot", "208", 2019, 2024, "HATCHBACK"),
            new CarModel("Peugeot", "308", 2014, 2024, "HATCHBACK"),
            new CarModel("Peugeot", "508", 2018, 2024, "SEDAN"),
            new CarModel("Peugeot", "2008", 2019, 2024, "SUV"),
            new CarModel("Peugeot", "3008", 2016, 2024, "SUV"),
            new CarModel("Peugeot", "5008", 2017, 2024, "SUV"),
            new CarModel("Peugeot", "Partner", 2018, 2024, "VAN"),
            new CarModel("Peugeot", "Expert", 2016, 2024, "VAN"),
            new CarModel("Peugeot", "Boxer", 2014, 2024, "VAN"),
            new CarModel("Peugeot", "Rifter", 2018, 2024, "VAN"),

            // Citroën
            new CarModel("Citroën", "C1", 2014, 2024, "HATCHBACK"),
            new CarModel("Citroën", "C3", 2016, 2024, "HATCHBACK"),
            new CarModel("Citroën", "C4", 2020, 2024, "HATCHBACK"),
            new CarModel("Citroën", "C5", 2017, 2024, "SEDAN"),
            new CarModel("Citroën", "C3 Aircross", 2017, 2024, "SUV"),
            new CarModel("Citroën", "C5 Aircross", 2017, 2024, "SUV"),
            new CarModel("Citroën", "Berlingo", 2018, 2024, "VAN"),
            new CarModel("Citroën", "Jumper", 2014, 2024, "VAN"),
            new CarModel("Citroën", "Spacetourer", 2016, 2024, "VAN"),
            new CarModel("Citroën", "Ami", 2020, 2024, "ELECTRIC"),

            // Toyota
            new CarModel("Toyota", "Yaris", 2020, 2024, "HATCHBACK"),
            new CarModel("Toyota", "Corolla", 2018, 2024, "SEDAN"),
            new CarModel("Toyota", "Camry", 2017, 2024, "SEDAN"),
            new CarModel("Toyota", "Prius", 2016, 2024, "HYBRID"),
            new CarModel("Toyota", "RAV4", 2018, 2024, "SUV"),
            new CarModel("Toyota", "Highlander", 2019, 2024, "SUV"),
            new CarModel("Toyota", "Land Cruiser", 2018, 2024, "SUV"),
            new CarModel("Toyota", "C-HR", 2016, 2024, "SUV"),
            new CarModel("Toyota", "Auris", 2012, 2018, "HATCHBACK"),
            new CarModel("Toyota", "Avensis", 2009, 2018, "SEDAN"),

            // Ford
            new CarModel("Ford", "Fiesta", 2017, 2024, "HATCHBACK"),
            new CarModel("Ford", "Focus", 2018, 2024, "HATCHBACK"),
            new CarModel("Ford", "Mondeo", 2014, 2022, "SEDAN"),
            new CarModel("Ford", "Mustang", 2015, 2024, "COUPE"),
            new CarModel("Ford", "EcoSport", 2017, 2024, "SUV"),
            new CarModel("Ford", "Kuga", 2019, 2024, "SUV"),
            new CarModel("Ford", "Explorer", 2020, 2024, "SUV"),
            new CarModel("Ford", "Transit", 2014, 2024, "VAN"),
            new CarModel("Ford", "Ranger", 2019, 2024, "PICKUP"),
            new CarModel("Ford", "F-150", 2021, 2024, "PICKUP"),

            // Nissan
            new CarModel("Nissan", "Micra", 2017, 2024, "HATCHBACK"),
            new CarModel("Nissan", "Sentra", 2019, 2024, "SEDAN"),
            new CarModel("Nissan", "Altima", 2018, 2024, "SEDAN"),
            new CarModel("Nissan", "Maxima", 2016, 2024, "SEDAN"),
            new CarModel("Nissan", "Juke", 2019, 2024, "SUV"),
            new CarModel("Nissan", "Qashqai", 2014, 2024, "SUV"),
            new CarModel("Nissan", "X-Trail", 2014, 2024, "SUV"),
            new CarModel("Nissan", "Pathfinder", 2021, 2024, "SUV"),
            new CarModel("Nissan", "Leaf", 2017, 2024, "ELECTRIC"),
            new CarModel("Nissan", "Ariya", 2021, 2024, "ELECTRIC"),

            // Hyundai
            new CarModel("Hyundai", "i10", 2019, 2024, "HATCHBACK"),
            new CarModel("Hyundai", "i20", 2020, 2024, "HATCHBACK"),
            new CarModel("Hyundai", "i30", 2017, 2024, "HATCHBACK"),
            new CarModel("Hyundai", "Elantra", 2020, 2024, "SEDAN"),
            new CarModel("Hyundai", "Sonata", 2019, 2024, "SEDAN"),
            new CarModel("Hyundai", "Kona", 2017, 2024, "SUV"),
            new CarModel("Hyundai", "Tucson", 2015, 2024, "SUV"),
            new CarModel("Hyundai", "Santa Fe", 2018, 2024, "SUV"),
            new CarModel("Hyundai", "Ioniq", 2016, 2024, "HYBRID"),
            new CarModel("Hyundai", "Nexo", 2018, 2024, "HYDROGEN"),

            // Kia
            new CarModel("Kia", "Picanto", 2017, 2024, "HATCHBACK"),
            new CarModel("Kia", "Rio", 2017, 2024, "HATCHBACK"),
            new CarModel("Kia", "Ceed", 2018, 2024, "HATCHBACK"),
            new CarModel("Kia", "Optima", 2015, 2020, "SEDAN"),
            new CarModel("Kia", "Stinger", 2017, 2024, "SEDAN"),
            new CarModel("Kia", "Stonic", 2017, 2024, "SUV"),
            new CarModel("Kia", "Sportage", 2016, 2024, "SUV"),
            new CarModel("Kia", "Sorento", 2020, 2024, "SUV"),
            new CarModel("Kia", "Niro", 2016, 2024, "HYBRID"),
            new CarModel("Kia", "EV6", 2021, 2024, "ELECTRIC"),

            // Opel
            new CarModel("Opel", "Corsa", 2019, 2024, "HATCHBACK"),
            new CarModel("Opel", "Astra", 2015, 2024, "HATCHBACK"),
            new CarModel("Opel", "Insignia", 2017, 2024, "SEDAN"),
            new CarModel("Opel", "Crossland", 2017, 2024, "SUV"),
            new CarModel("Opel", "Grandland", 2017, 2024, "SUV"),
            new CarModel("Opel", "Mokka", 2016, 2024, "SUV"),
            new CarModel("Opel", "Combo", 2018, 2024, "VAN"),
            new CarModel("Opel", "Vivaro", 2014, 2024, "VAN"),
            new CarModel("Opel", "Movano", 2010, 2024, "VAN"),
            new CarModel("Opel", "Zafira", 2011, 2019, "MPV"),

            // Fiat
            new CarModel("Fiat", "500", 2007, 2024, "HATCHBACK"),
            new CarModel("Fiat", "Panda", 2012, 2024, "HATCHBACK"),
            new CarModel("Fiat", "Punto", 2005, 2018, "HATCHBACK"),
            new CarModel("Fiat", "Tipo", 2015, 2024, "SEDAN"),
            new CarModel("Fiat", "500X", 2014, 2024, "SUV"),
            new CarModel("Fiat", "500L", 2012, 2024, "MPV"),
            new CarModel("Fiat", "Doblo", 2010, 2024, "VAN"),
            new CarModel("Fiat", "Ducato", 2006, 2024, "VAN"),
            new CarModel("Fiat", "Talento", 2016, 2024, "VAN"),
            new CarModel("Fiat", "Fullback", 2016, 2024, "PICKUP")
        );

        carModelRepository.saveAll(carModels);
    }

    @Override
    public long getCarModelCount() {
        return carModelRepository.count();
    }
}
