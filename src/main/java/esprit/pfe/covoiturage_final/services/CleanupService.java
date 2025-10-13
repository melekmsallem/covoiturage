package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Voyage;
import esprit.pfe.covoiturage_final.repositories.PaiementRepository;
import esprit.pfe.covoiturage_final.repositories.Point_GPSRepository;
import esprit.pfe.covoiturage_final.repositories.ReservationRepository;
import esprit.pfe.covoiturage_final.repositories.VoyageRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.stream.Collectors;
import java.util.Map;

@Service
public class CleanupService {

    private static final Logger log = LoggerFactory.getLogger(CleanupService.class);

    private LocalDateTime lastRunTime;
    private Map<String, Object> lastRunStats = new HashMap<>();

    private final VoyageRepository voyageRepository;
    private final ReservationRepository reservationRepository;
    private final PaiementRepository paiementRepository;
    private final Point_GPSRepository pointGpsRepository;

    @Value("${cleanup.retention.days:1}")
    private int retentionDays;

    public CleanupService(VoyageRepository voyageRepository,
                          ReservationRepository reservationRepository,
                          PaiementRepository paiementRepository,
                          Point_GPSRepository pointGpsRepository) {
        this.voyageRepository = voyageRepository;
        this.reservationRepository = reservationRepository;
        this.paiementRepository = paiementRepository;
        this.pointGpsRepository = pointGpsRepository;
    }

    // Run every day at 02:15 server time
    @Scheduled(cron = "0 15 2 * * *")
    @Transactional
    public void cleanupExpiredTrips() {
        runCleanup(false);
    }

    @Transactional
    public Map<String, Object> runCleanup(boolean dryRun) {
        LocalDate cutoffDate = LocalDate.now().minusDays(retentionDays);
        LocalDateTime cutoffDateTime = cutoffDate.atStartOfDay();

        List<Voyage> expired = voyageRepository.findByDepartureTimeAfter(LocalDateTime.MIN)
                .stream()
                .filter(v -> v.getDepartureTime() != null && v.getDepartureTime().isBefore(cutoffDateTime))
                .collect(Collectors.toList());

        List<Long> voyageIds = expired.stream().map(Voyage::getId).toList();
        List<Long> reservationIds = voyageIds.stream()
                .flatMap(vId -> reservationRepository.findByVoyageId(vId).stream())
                .map(r -> r.getId())
                .collect(Collectors.toList());

        if (dryRun) {
            return Map.of(
                    "cutoff", cutoffDateTime.toString(),
                    "voyages", voyageIds.size(),
                    "reservations", reservationIds.size()
            );
        }

        if (!reservationIds.isEmpty()) {
            paiementRepository.deleteByReservationIdIn(reservationIds);
            reservationRepository.deleteByVoyageIdIn(voyageIds);
        }
        if (!voyageIds.isEmpty()) {
            pointGpsRepository.deleteByVoyageIdIn(voyageIds);
            voyageRepository.deleteByIdIn(voyageIds);
        }

        lastRunTime = LocalDateTime.now();
        lastRunStats = Map.of(
                "cutoff", cutoffDateTime.toString(),
                "deletedVoyages", voyageIds.size(),
                "deletedReservations", reservationIds.size(),
                "runTime", lastRunTime.toString()
        );
        
        return lastRunStats;
    }

    public Map<String, Object> getCleanupStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("lastRunTime", lastRunTime != null ? lastRunTime.toString() : null);
        stats.put("lastRunStats", lastRunStats);
        stats.put("retentionDays", retentionDays);
        stats.put("nextScheduledRun", "Daily at 02:15");
        return stats;
    }
}


