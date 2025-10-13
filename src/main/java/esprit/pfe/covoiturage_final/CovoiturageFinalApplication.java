package esprit.pfe.covoiturage_final;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class CovoiturageFinalApplication {

    public static void main(String[] args) {
        SpringApplication.run(CovoiturageFinalApplication.class, args);
    }

}
