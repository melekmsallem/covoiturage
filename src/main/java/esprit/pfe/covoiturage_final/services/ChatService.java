package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.ChatMessageRequest;
import esprit.pfe.covoiturage_final.dto.ChatMessageResponse;
import esprit.pfe.covoiturage_final.dto.GroupChatMessageRequest;
import esprit.pfe.covoiturage_final.dto.GroupChatMessageResponse;
import esprit.pfe.covoiturage_final.dto.TripChatInfo;

import java.util.List;

public interface ChatService {
    
    // Individual chat methods
    ChatMessageResponse sendMessage(ChatMessageRequest request, Long senderId);
    
    List<ChatMessageResponse> getMessages(Long bookingId, Long userId);
    
    List<ChatMessageResponse> getMessagesSince(Long bookingId, Long userId, String since);
    
    Long getUnreadCount(Long bookingId, Long userId);
    
    void markMessagesAsRead(Long bookingId, Long userId);
    
    boolean canUserAccessChat(Long bookingId, Long userId);
    
    // Group chat methods
    GroupChatMessageResponse sendGroupMessage(GroupChatMessageRequest request, Long senderId);
    
    List<GroupChatMessageResponse> getGroupMessages(Long tripId, Long userId);
    
    List<GroupChatMessageResponse> getGroupMessagesSince(Long tripId, Long userId, String since);
    
    Long getGroupUnreadCount(Long tripId, Long userId);
    
    void markGroupMessagesAsRead(Long tripId, Long userId);
    
    boolean canUserAccessGroupChat(Long tripId, Long userId);
    
    TripChatInfo getTripChatInfo(Long tripId, Long userId);
    
    TripChatInfo createOrGetTripChat(Long tripId, Long userId);
}



