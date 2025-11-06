package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.ChatMessageRequest;
import esprit.pfe.covoiturage_final.dto.ChatMessageResponse;
import esprit.pfe.covoiturage_final.dto.GroupChatMessageRequest;
import esprit.pfe.covoiturage_final.dto.GroupChatMessageResponse;
import esprit.pfe.covoiturage_final.dto.TripChatInfo;
import esprit.pfe.covoiturage_final.entities.ChatMessage;
import esprit.pfe.covoiturage_final.entities.Reservation;
import esprit.pfe.covoiturage_final.entities.TripChat;
import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.entities.Voyage;
import esprit.pfe.covoiturage_final.repositories.ChatMessageRepository;
import esprit.pfe.covoiturage_final.repositories.ReservationRepository;
import esprit.pfe.covoiturage_final.repositories.TripChatRepository;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import esprit.pfe.covoiturage_final.repositories.VoyageRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ChatServiceImpl implements ChatService {
    
    @Autowired
    private ChatMessageRepository chatMessageRepository;
    
    @Autowired
    private ReservationRepository reservationRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private VoyageRepository voyageRepository;
    
    @Autowired
    private TripChatRepository tripChatRepository;
    
    @Override
    public ChatMessageResponse sendMessage(ChatMessageRequest request, Long senderId) {
        // Validate user can access this chat
        if (!canUserAccessChat(request.getBookingId(), senderId)) {
            throw new RuntimeException("You don't have permission to send messages for this booking");
        }
        
        // Create and save message
        ChatMessage message = new ChatMessage();
        message.setBookingId(request.getBookingId());
        message.setSenderId(senderId);
        message.setMessage(request.getMessage());
        message.setMessageType(ChatMessage.MessageType.valueOf(request.getMessageType()));
        
        message = chatMessageRepository.save(message);
        
        return convertToResponse(message);
    }
    
    @Override
    public List<ChatMessageResponse> getMessages(Long bookingId, Long userId) {
        // Validate user can access this chat
        if (!canUserAccessChat(bookingId, userId)) {
            throw new RuntimeException("You don't have permission to view messages for this booking");
        }
        
        List<ChatMessage> messages = chatMessageRepository.findByBookingIdOrderByTimestampAsc(bookingId);
        return messages.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }
    
    @Override
    public List<ChatMessageResponse> getMessagesSince(Long bookingId, Long userId, String since) {
        // Validate user can access this chat
        if (!canUserAccessChat(bookingId, userId)) {
            throw new RuntimeException("You don't have permission to view messages for this booking");
        }
        
        LocalDateTime sinceTime = LocalDateTime.parse(since, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        List<ChatMessage> messages = chatMessageRepository.findMessagesSince(bookingId, sinceTime);
        return messages.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }
    
    @Override
    public Long getUnreadCount(Long bookingId, Long userId) {
        if (!canUserAccessChat(bookingId, userId)) {
            return 0L;
        }
        
        return chatMessageRepository.countUnreadMessages(bookingId, userId);
    }
    
    @Override
    public void markMessagesAsRead(Long bookingId, Long userId) {
        if (canUserAccessChat(bookingId, userId)) {
            chatMessageRepository.markMessagesAsRead(bookingId, userId);
        }
    }
    
    @Override
    public boolean canUserAccessChat(Long bookingId, Long userId) {
        // Get the booking
        Reservation reservation = reservationRepository.findById(bookingId).orElse(null);
        if (reservation == null) {
            return false;
        }
        
        // Check if booking is confirmed
        if (reservation.getStatus() != Reservation.ReservationStatus.CONFIRMED) {
            return false;
        }
        
        // Get the trip
        Voyage trip = voyageRepository.findById(reservation.getVoyageId()).orElse(null);
        if (trip == null) {
            return false;
        }
        
        // Check if user is either the passenger or the driver
        return reservation.getPassagerId().equals(userId) || trip.getConducteurId().equals(userId);
    }
    
    private ChatMessageResponse convertToResponse(ChatMessage message) {
        ChatMessageResponse response = new ChatMessageResponse();
        response.setId(message.getId());
        response.setBookingId(message.getBookingId());
        response.setSenderId(message.getSenderId());
        response.setMessage(message.getMessage());
        response.setTimestamp(message.getTimestamp());
        response.setIsRead(message.getIsRead());
        response.setMessageType(message.getMessageType().name());
        
        // Get sender information
        User sender = userRepository.findById(message.getSenderId()).orElse(null);
        if (sender != null) {
            response.setSenderName(sender.getFirstName() + " " + sender.getLastName());
            response.setSenderFirstName(sender.getFirstName());
            response.setSenderLastName(sender.getLastName());
            response.setSenderUsername(sender.getUsername());
        }
        
        return response;
    }
    
    // Group chat methods implementation
    @Override
    public GroupChatMessageResponse sendGroupMessage(GroupChatMessageRequest request, Long senderId) {
        // Validate user can access this group chat
        if (!canUserAccessGroupChat(request.getTripId(), senderId)) {
            throw new RuntimeException("You don't have permission to send messages for this trip");
        }
        
        // Get or create trip chat
        TripChat tripChat = createOrGetTripChat(request.getTripId(), senderId).getId() != null ? 
            tripChatRepository.findById(createOrGetTripChat(request.getTripId(), senderId).getId()).orElse(null) : null;
        
        if (tripChat == null) {
            throw new RuntimeException("Failed to create or access trip chat");
        }
        
        // Create and save message
        ChatMessage message = new ChatMessage();
        message.setTripChatId(tripChat.getId());
        message.setBookingId(null); // Group chat doesn't use booking_id
        message.setSenderId(senderId);
        message.setReceiverId(null); // Group chat doesn't use receiver_id
        message.setMessage(request.getMessage());
        message.setMessageType(ChatMessage.MessageType.valueOf(request.getMessageType()));
        
        message = chatMessageRepository.save(message);
        
        return convertToGroupResponse(message);
    }
    
    @Override
    public List<GroupChatMessageResponse> getGroupMessages(Long tripId, Long userId) {
        // Validate user can access this group chat
        if (!canUserAccessGroupChat(tripId, userId)) {
            throw new RuntimeException("You don't have permission to view messages for this trip");
        }
        
        // Get trip chat
        TripChat tripChat = tripChatRepository.findByVoyageIdAndIsActiveTrue(tripId).orElse(null);
        if (tripChat == null) {
            return List.of(); // No chat exists yet
        }
        
        List<ChatMessage> messages = chatMessageRepository.findByTripChatIdOrderByTimestampAsc(tripChat.getId());
        return messages.stream()
                .map(this::convertToGroupResponse)
                .collect(Collectors.toList());
    }
    
    @Override
    public List<GroupChatMessageResponse> getGroupMessagesSince(Long tripId, Long userId, String since) {
        if (!canUserAccessGroupChat(tripId, userId)) {
            throw new RuntimeException("You don't have permission to view messages for this trip");
        }
        
        TripChat tripChat = tripChatRepository.findByVoyageIdAndIsActiveTrue(tripId).orElse(null);
        if (tripChat == null) {
            return List.of();
        }
        
        LocalDateTime sinceTime = LocalDateTime.parse(since, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        List<ChatMessage> messages = chatMessageRepository.findGroupMessagesSince(tripChat.getId(), sinceTime);
        return messages.stream()
                .map(this::convertToGroupResponse)
                .collect(Collectors.toList());
    }
    
    @Override
    public Long getGroupUnreadCount(Long tripId, Long userId) {
        if (!canUserAccessGroupChat(tripId, userId)) {
            return 0L;
        }
        
        TripChat tripChat = tripChatRepository.findByVoyageIdAndIsActiveTrue(tripId).orElse(null);
        if (tripChat == null) {
            return 0L;
        }
        
        return chatMessageRepository.countUnreadGroupMessages(tripChat.getId(), userId);
    }
    
    @Override
    public void markGroupMessagesAsRead(Long tripId, Long userId) {
        if (canUserAccessGroupChat(tripId, userId)) {
            TripChat tripChat = tripChatRepository.findByVoyageIdAndIsActiveTrue(tripId).orElse(null);
            if (tripChat != null) {
                chatMessageRepository.markGroupMessagesAsRead(tripChat.getId(), userId);
            }
        }
    }
    
    @Override
    public boolean canUserAccessGroupChat(Long tripId, Long userId) {
        // Get the trip
        Voyage trip = voyageRepository.findById(tripId).orElse(null);
        if (trip == null) {
            return false;
        }
        
        // Check if user is the driver
        if (trip.getConducteurId().equals(userId)) {
            return true;
        }
        
        // Check if user has a confirmed booking for this trip
        List<Reservation> userBookings = reservationRepository.findByVoyageIdAndPassagerId(tripId, userId);
        return userBookings.stream()
                .anyMatch(booking -> booking.getStatus() == Reservation.ReservationStatus.CONFIRMED);
    }
    
    @Override
    public TripChatInfo getTripChatInfo(Long tripId, Long userId) {
        if (!canUserAccessGroupChat(tripId, userId)) {
            throw new RuntimeException("You don't have permission to access this trip chat");
        }
        
        Voyage trip = voyageRepository.findById(tripId).orElse(null);
        if (trip == null) {
            throw new RuntimeException("Trip not found");
        }
        
        TripChat tripChat = tripChatRepository.findByVoyageIdAndIsActiveTrue(tripId).orElse(null);
        if (tripChat == null) {
            return null; // No chat exists yet
        }
        
        TripChatInfo info = new TripChatInfo();
        info.setId(tripChat.getId());
        info.setTripId(tripId);
        info.setTripRoute(
            (trip.getDepartureVille() != null ? trip.getDepartureVille().getName() : "Unknown") + 
            " → " + 
            (trip.getArrivalVille() != null ? trip.getArrivalVille().getName() : "Unknown")
        );
        info.setCreatedAt(tripChat.getCreatedAt());
        info.setIsActive(tripChat.getIsActive());
        info.setUnreadCount(getGroupUnreadCount(tripId, userId));
        
        // Get participants (driver + confirmed passengers)
        List<TripChatInfo.ParticipantInfo> participants = getTripParticipants(tripId);
        info.setParticipants(participants);
        
        return info;
    }
    
    @Override
    public TripChatInfo createOrGetTripChat(Long tripId, Long userId) {
        if (!canUserAccessGroupChat(tripId, userId)) {
            throw new RuntimeException("You don't have permission to create/access this trip chat");
        }
        
        // Check if chat already exists
        TripChat existingChat = tripChatRepository.findByVoyageIdAndIsActiveTrue(tripId).orElse(null);
        if (existingChat != null) {
            return getTripChatInfo(tripId, userId);
        }
        
        // Create new trip chat
        TripChat newChat = new TripChat();
        newChat.setVoyageId(tripId);
        newChat.setIsActive(true);
        newChat = tripChatRepository.save(newChat);
        
        return getTripChatInfo(tripId, userId);
    }
    
    private List<TripChatInfo.ParticipantInfo> getTripParticipants(Long tripId) {
        Voyage trip = voyageRepository.findById(tripId).orElse(null);
        if (trip == null) {
            return List.of();
        }
        
        // Add driver
        User driver = userRepository.findById(trip.getConducteurId()).orElse(null);
        List<TripChatInfo.ParticipantInfo> participants = new java.util.ArrayList<>();
        
        if (driver != null) {
            TripChatInfo.ParticipantInfo driverInfo = new TripChatInfo.ParticipantInfo();
            driverInfo.setUserId(driver.getId());
            driverInfo.setFirstName(driver.getFirstName());
            driverInfo.setLastName(driver.getLastName());
            driverInfo.setUserType("DRIVER");
            driverInfo.setIsOnline(false); // TODO: Implement online status
            participants.add(driverInfo);
        }
        
        // Add confirmed passengers
        List<Reservation> confirmedBookings = reservationRepository.findByVoyageIdAndStatus(tripId, Reservation.ReservationStatus.CONFIRMED);
        for (Reservation booking : confirmedBookings) {
            User passenger = userRepository.findById(booking.getPassagerId()).orElse(null);
            if (passenger != null) {
                TripChatInfo.ParticipantInfo passengerInfo = new TripChatInfo.ParticipantInfo();
                passengerInfo.setUserId(passenger.getId());
                passengerInfo.setFirstName(passenger.getFirstName());
                passengerInfo.setLastName(passenger.getLastName());
                passengerInfo.setUserType("PASSENGER");
                passengerInfo.setIsOnline(false); // TODO: Implement online status
                participants.add(passengerInfo);
            }
        }
        
        return participants;
    }
    
    private GroupChatMessageResponse convertToGroupResponse(ChatMessage message) {
        GroupChatMessageResponse response = new GroupChatMessageResponse();
        response.setId(message.getId());
        response.setTripChatId(message.getTripChatId());
        response.setSenderId(message.getSenderId());
        response.setMessage(message.getMessage());
        response.setTimestamp(message.getTimestamp());
        response.setIsRead(message.getIsRead());
        response.setMessageType(message.getMessageType().name());
        
        // Get sender info
        User sender = userRepository.findById(message.getSenderId()).orElse(null);
        if (sender != null) {
            response.setSenderName(sender.getFirstName() + " " + sender.getLastName());
            
            // Determine if sender is driver or passenger
            Voyage trip = voyageRepository.findById(
                tripChatRepository.findById(message.getTripChatId()).orElse(null).getVoyageId()
            ).orElse(null);
            
            if (trip != null && trip.getConducteurId().equals(sender.getId())) {
                response.setSenderType("DRIVER");
            } else {
                response.setSenderType("PASSENGER");
            }
        }
        
        return response;
    }
}



