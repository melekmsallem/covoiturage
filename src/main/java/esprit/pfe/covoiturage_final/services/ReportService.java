package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Report;
import java.util.List;

public interface ReportService {
    Report createReport(Long reporterId, Long reportedUserId, Long bookingId, Long tripId,
                       Report.ReportType reportType, String reason, String description);
    List<Report> getReportsByReporter(Long reporterId);
    List<Report> getReportsByReportedUser(Long reportedUserId);
    List<Report> getAllReports();
    List<Report> getPendingReports();
    Report updateReportStatus(Long reportId, Report.ReportStatus status, String adminNotes);
    boolean hasReportedUser(Long reporterId, Long reportedUserId, Long bookingId);
}

