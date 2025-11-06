package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.CarModel;

import java.util.List;

public interface CarModelService {
    
    List<CarModel> getAllCarModels();
    
    List<CarModel> searchCarModels(String query);
    
    List<String> getAllBrands();
    
    List<CarModel> getModelsByBrand(String brand);
    
    CarModel saveCarModel(CarModel carModel);
    
    void initializeCarModelsData();
    
    long getCarModelCount();
}
