package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Report;
import esprit.pfe.covoiturage_final.repositories.ReportRepository;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ReportServiceImpl implements ReportService {
    
    @Autowired
    private ReportRepository reportRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Override
    public Report createReport(Long reporterId, Long reportedUserId, Long bookingId, Long tripId,
                              Report.ReportType reportType, String reason, String description) {
        // Validate users exist
        if (!userRepository.findById(reporterId).isPresent()) {
            throw new RuntimeException("Reporter user not found");
        }
        if (!userRepository.findById(reportedUserId).isPresent()) {
            throw new RuntimeException("Reported user not found");
        }
        
        // Prevent duplicate reports for the same booking
        if (bookingId != null && reportRepository.existsByReporterIdAndReportedUserIdAndBookingId(
                reporterId, reportedUserId, bookingId)) {
            throw new RuntimeException("You have already reported this user for this booking");
        }
        
        Report report = new Report();
        report.setReporterId(reporterId);
        report.setReportedUserId(reportedUserId);
        report.setBookingId(bookingId);
        report.setTripId(tripId);
        report.setReportType(reportType);
        report.setReason(reason);
        report.setDescription(description);
        report.setStatus(Report.ReportStatus.PENDING);
        
        return reportRepository.save(report);
    }
    
    @Override
    public List<Report> getReportsByReporter(Long reporterId) {
        return reportRepository.findByReporterId(reporterId);
    }
    
    @Override
    public List<Report> getReportsByReportedUser(Long reportedUserId) {
        return reportRepository.findByReportedUserId(reportedUserId);
    }
    
    @Override
    public List<Report> getAllReports() {
        return reportRepository.findAll();
    }
    
    @Override
    public List<Report> getPendingReports() {
        return reportRepository.findByStatus(Report.ReportStatus.PENDING);
    }
    
    @Override
    public Report updateReportStatus(Long reportId, Report.ReportStatus status, String adminNotes) {
        Report report = reportRepository.findById(reportId)
            .orElseThrow(() -> new RuntimeException("Report not found"));
        
        report.setStatus(status);
        report.setAdminNotes(adminNotes);
        
        if (status == Report.ReportStatus.RESOLVED || status == Report.ReportStatus.DISMISSED) {
            report.setResolvedAt(LocalDateTime.now());
        }
        
        return reportRepository.save(report);
    }
    
    @Override
    public boolean hasReportedUser(Long reporterId, Long reportedUserId, Long bookingId) {
        if (bookingId == null) {
            return false;
        }
        return reportRepository.existsByReporterIdAndReportedUserIdAndBookingId(
            reporterId, reportedUserId, bookingId);
    }
}

