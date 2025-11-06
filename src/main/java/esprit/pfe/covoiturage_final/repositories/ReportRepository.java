package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.Report;
import esprit.pfe.covoiturage_final.entities.Report.ReportStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReportRepository extends JpaRepository<Report, Long> {
    List<Report> findByReporterId(Long reporterId);
    List<Report> findByReportedUserId(Long reportedUserId);
    List<Report> findByStatus(ReportStatus status);
    List<Report> findByBookingId(Long bookingId);
    List<Report> findByTripId(Long tripId);
    boolean existsByReporterIdAndReportedUserIdAndBookingId(Long reporterId, Long reportedUserId, Long bookingId);
}

