package com.example.animalservice.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.storage.BlobId;
import com.google.cloud.storage.BlobInfo;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.UUID;

@Service
public class StorageService {

    @Value("${gcp.bucket.name}")
    private String bucketName;

    @Value("${gcp.service.account.path}")
    private String serviceAccountPath;

    /**
     * Uploads a license file to Google Cloud Storage and returns the public URL.
     */
    public String uploadLicense(MultipartFile file, String email) throws IOException {
        // Build credentials from service account JSON
        GoogleCredentials credentials = GoogleCredentials
                .fromStream(new FileInputStream(serviceAccountPath))
                .createScoped("https://www.googleapis.com/auth/devstorage.full_control");

        // Build GCS client
        Storage storage = StorageOptions.newBuilder()
                .setCredentials(credentials)
                .build()
                .getService();

        // Generate unique file name: licenses/email_uuid.ext
        String ext = StringUtils.getFilenameExtension(file.getOriginalFilename());
        if (ext == null) ext = "pdf";
        String sanitizedEmail = email.replace("@", "_at_").replace(".", "_");
        String blobName = "licenses/" + sanitizedEmail + "_" + UUID.randomUUID() + "." + ext;

        // Upload to GCS
        BlobId blobId = BlobId.of(bucketName, blobName);
        BlobInfo blobInfo = BlobInfo.newBuilder(blobId)
                .setContentType(file.getContentType())
                .build();

        storage.create(blobInfo, file.getBytes());

        // Return public URL
        return "https://storage.googleapis.com/" + bucketName + "/" + blobName;
    }
}
