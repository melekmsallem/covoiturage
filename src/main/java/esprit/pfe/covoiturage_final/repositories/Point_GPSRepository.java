package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.Point_GPS;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface Point_GPSRepository extends JpaRepository<Point_GPS, Long> {
    
    List<Point_GPS> findByVoyageId(Long voyageId);
    
    List<Point_GPS> findByPointType(Point_GPS.PointType pointType);
    
    List<Point_GPS> findByVoyageIdAndPointType(Long voyageId, Point_GPS.PointType pointType);
}
