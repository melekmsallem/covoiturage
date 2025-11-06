package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.services.LicenseVerificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/files")
@CrossOrigin(origins = "*", maxAge = 3600)
public class FileUploadController {

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;
    
    @Autowired
    private LicenseVerificationService licenseVerificationService;

    @PostMapping("/upload-license")
    public ResponseEntity<?> uploadLicenseImage(@RequestParam("file") MultipartFile file,
                                               @RequestParam("userId") Long userId) {
        try {
            // Validate file
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body("File is empty");
            }

            // Check file type
            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                return ResponseEntity.badRequest().body("File must be an image");
            }

            // Check file size (max 5MB)
            if (file.getSize() > 5 * 1024 * 1024) {
                return ResponseEntity.badRequest().body("File size must be less than 5MB");
            }

            // Create upload directory if it doesn't exist
            Path uploadPath = Paths.get(uploadDir, "licenses");
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            // Generate unique filename
            String originalFilename = file.getOriginalFilename();
            String extension = originalFilename != null && originalFilename.contains(".")
                ? originalFilename.substring(originalFilename.lastIndexOf("."))
                : ".jpg";
            String filename = "license_" + userId + "_" + UUID.randomUUID().toString() + extension;

            // Save file
            Path filePath = uploadPath.resolve(filename);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
            
            // Save the license image path to the driver's record
            try {
                licenseVerificationService.uploadLicenseImage(userId, filePath.toString());
            } catch (RuntimeException e) {
                // If driver not found, don't fail the upload, just log it
                System.err.println("Warning: Could not update driver license image path: " + e.getMessage());
            }

            // Return file info
            Map<String, Object> response = new HashMap<>();
            response.put("filename", filename);
            response.put("originalFilename", originalFilename);
            response.put("size", file.getSize());
            response.put("contentType", contentType);
            response.put("url", "/api/files/license/" + filename);
            response.put("path", filePath.toString());

            return ResponseEntity.ok(response);

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Failed to upload file: " + e.getMessage());
        }
    }

    @GetMapping("/license/{filename}")
    public ResponseEntity<?> getLicenseImage(@PathVariable String filename) {
        try {
            Path filePath = Paths.get(uploadDir, "licenses", filename);
            
            if (!Files.exists(filePath)) {
                return ResponseEntity.notFound().build();
            }

            byte[] fileBytes = Files.readAllBytes(filePath);
            String contentType = Files.probeContentType(filePath);
            
            return ResponseEntity.ok()
                .header("Content-Type", contentType != null ? contentType : "application/octet-stream")
                .body(fileBytes);

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Failed to read file: " + e.getMessage());
        }
    }

    @DeleteMapping("/license/{filename}")
    public ResponseEntity<?> deleteLicenseImage(@PathVariable String filename) {
        try {
            Path filePath = Paths.get(uploadDir, "licenses", filename);
            
            if (!Files.exists(filePath)) {
                return ResponseEntity.notFound().build();
            }

            Files.delete(filePath);
            return ResponseEntity.ok().body("File deleted successfully");

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Failed to delete file: " + e.getMessage());
        }
    }
}



