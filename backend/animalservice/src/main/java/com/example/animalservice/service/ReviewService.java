package com.example.animalservice.service;

import com.example.animalservice.model.Review;
import com.example.animalservice.model.ServiceProvider;
import com.example.animalservice.repository.ReviewRepository;
import com.example.animalservice.repository.ServiceProviderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ReviewService {

    @Autowired
    private ReviewRepository reviewRepository;

    @Autowired
    private ServiceProviderRepository providerRepository;

    public Review createReview(Review review) {
        // Resolve providerId from email if missing
        if (review.getProviderId() == 0 && review.getProviderEmail() != null) {
            ServiceProvider p = providerRepository.findByEmail(review.getProviderEmail());
            if (p != null) review.setProviderId(p.getId());
        }
        
        // Resolve userId (farmer) from email if missing
        if (review.getUserId() == 0 && review.getOwnerEmail() != null) {
            ServiceProvider u = providerRepository.findByEmail(review.getOwnerEmail());
            if (u != null) review.setUserId(u.getId());
        }

        if (review.getProviderId() == 0) {
            throw new RuntimeException("Cannot save review: Provider not found for email: " + review.getProviderEmail());
        }

        Review saved = reviewRepository.save(review);

        // Recalculate average rating for the provider
        List<Review> allReviews = reviewRepository.findByProviderId(review.getProviderId());
        double avg = allReviews.stream()
                .mapToInt(Review::getRating)
                .average()
                .orElse(0.0);

        ServiceProvider provider = providerRepository.findById(review.getProviderId()).orElse(null);
        if (provider != null) {
            provider.setAvgRating(Math.round(avg * 10.0) / 10.0);
            provider.setTotalReviews(allReviews.size());
            providerRepository.save(provider);
        }

        return saved;
    }

    public List<Review> getReviewsByProvider(int providerId) {
        return reviewRepository.findByProviderIdOrderByCreatedAtDesc(providerId);
    }

    public double getAverageRating(int providerId) {
        List<Review> reviews = reviewRepository.findByProviderId(providerId);
        return reviews.stream()
                .mapToInt(Review::getRating)
                .average()
                .orElse(0.0);
    }
}
