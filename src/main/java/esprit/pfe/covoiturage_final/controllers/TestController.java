package esprit.pfe.covoiturage_final.controllers;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.CrossOrigin;

@RestController
@RequestMapping("/api/public")
@CrossOrigin(origins = "*", maxAge = 3600)
public class TestController {

    @GetMapping("/test")
    public String test() {
        return "Covoiturage API is working!";
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }
}
