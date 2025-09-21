import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart' hide MessageType, MessageStatus;
import '../core/services/local_storage.dart';

// Use MessageType and MessageStatus from chat_message_model
import '../models/chat_message_model.dart' show MessageType, MessageStatus;

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Chat conversations
  List<ChatModel> _conversations = [];
  ChatModel? _currentConversation;
  
  // Messages for current conversation
  List<ChatMessageModel> _messages = [];
  
  // Typing indicators
  Map<String, List<TypingIndicator>> _typingIndicators = {};
  
  // Real-time listeners
  StreamSubscription<QuerySnapshot>? _conversationsListener;
  StreamSubscription<QuerySnapshot>? _messagesListener;
  StreamSubscription<QuerySnapshot>? _typingListener;
  
  // State management
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserRole;
  
  // Getters
  List<ChatModel> get conversations => List.unmodifiable(_conversations);
  ChatModel? get currentConversation => _currentConversation;
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  Map<String, List<TypingIndicator>> get typingIndicators => Map.unmodifiable(_typingIndicators);
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Initialize the chat provider
  Future<void> initialize(String userId, String userName, {String? userRole}) async {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserRole = userRole ?? 'user';
    
    await _loadConversations();
    _listenToConversations();
  }

  // Create a new conversation with ASHA worker
  Future<String> createConversation(String ashaId, String ashaName, {String? ashaImageUrl}) async {
    if (_currentUserId == null) throw Exception('User not initialized');
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Check if conversation already exists
      final existingConversation = _conversations.firstWhere(
        (conv) => conv.participants.contains(ashaId) && conv.participants.contains(_currentUserId),
        orElse: () => ChatModel(
          id: '',
          participants: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      if (existingConversation.id.isNotEmpty) {
        return existingConversation.id;
      }
      
      // Create new conversation
      final now = DateTime.now();
      final conversationData = {
        'participants': [_currentUserId!, ashaId],
        'participantNames': {
          _currentUserId!: _currentUserName,
          ashaId: ashaName,
        },
        'participantRoles': {
          _currentUserId!: _currentUserRole,
          ashaId: 'asha',
        },
        'participantImages': {
          if (ashaImageUrl != null) ashaId: ashaImageUrl,
        },
        'type': ChatType.individual.toString(),
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'unreadCount': {
          _currentUserId!: 0,
          ashaId: 0,
        },
      };
      
      final docRef = await _firestore.collection('chats').add(conversationData);
      
      // Send initial system message
      await _sendSystemMessage(
        docRef.id,
        '\${_currentUserName} started a conversation with \$ashaName',
      );
      
      return docRef.id;
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating conversation: \$e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load conversations for current user
  Future<void> _loadConversations() async {
    if (_currentUserId == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: _currentUserId)
          .where('isActive', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .get();
      
      _conversations = snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
      notifyListeners();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading conversations: \$e');
    }
  }
  
  // Listen to real-time conversation updates
  void _listenToConversations() {
    if (_currentUserId == null) return;
    
    _conversationsListener?.cancel();
    _conversationsListener = _firestore
        .collection('chats')
        .where('participants', arrayContains: _currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _conversations = snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        debugPrint('Error listening to conversations: \$error');
        notifyListeners();
      },
    );
  }
  
  // Set current conversation and load messages
  Future<void> setCurrentConversation(String conversationId) async {
    try {
      final conversation = _conversations.firstWhere((conv) => conv.id == conversationId);
      _currentConversation = conversation;
      
      await _loadMessages(conversationId);
      _listenToMessages(conversationId);
      _listenToTypingIndicators(conversationId);
      
      // Mark messages as read
      await _markMessagesAsRead(conversationId);
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error setting current conversation: \$e');
    }
    notifyListeners();
  }
  
  // Load messages for a conversation
  Future<void> _loadMessages(String conversationId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50) // Load last 50 messages initially
          .get();
      
      _messages = snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList()
          .reversed
          .toList();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading messages: \$e');
    }
  }
  
  // Listen to real-time message updates
  void _listenToMessages(String conversationId) {
    _messagesListener?.cancel();
    _messagesListener = _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen(
      (snapshot) {
        final newMessages = <ChatMessageModel>[];
        for (final docChange in snapshot.docChanges) {
          final message = ChatMessageModel.fromFirestore(docChange.doc);
          
          switch (docChange.type) {
            case DocumentChangeType.added:
              newMessages.add(message);
              break;
            case DocumentChangeType.modified:
              final index = _messages.indexWhere((m) => m.id == message.id);
              if (index != -1) {
                _messages[index] = message;
              }
              break;
            case DocumentChangeType.removed:
              _messages.removeWhere((m) => m.id == message.id);
              break;
          }
        }
        
        // Add new messages to the list
        if (newMessages.isNotEmpty) {
          _messages.addAll(newMessages);
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }
        
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        debugPrint('Error listening to messages: \$error');
        notifyListeners();
      },
    );
  }
  
  // Send a text message
  Future<void> sendMessage(String content, {String? replyToMessageId}) async {
    if (_currentConversation == null || _currentUserId == null) return;
    
    try {
      final now = DateTime.now();
      final messageData = {
        'chatId': _currentConversation!.id,
        'senderId': _currentUserId!,
        'senderName': _currentUserName,
        'senderRole': _currentUserRole,
        'type': MessageType.text.toString(),
        'content': content,
        'timestamp': Timestamp.fromDate(now),
        'readBy': [_currentUserId!],
        'status': MessageStatus.sent.toString(),
        'isEdited': false,
        'isDeleted': false,
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      };
      
      await _firestore
          .collection('chats')
          .doc(_currentConversation!.id)
          .collection('messages')
          .add(messageData);
      
      // Update conversation's last message
      await _updateConversationLastMessage(
        _currentConversation!.id,
        content,
        now,
        _currentUserId!,
      );
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending message: \$e');
      rethrow;
    }
  }
  
  // Send an image message
  Future<void> sendImageMessage(String imageUrl, {String? caption}) async {
    if (_currentConversation == null || _currentUserId == null) return;
    
    try {
      final now = DateTime.now();
      final messageData = {
        'chatId': _currentConversation!.id,
        'senderId': _currentUserId!,
        'senderName': _currentUserName,
        'senderRole': _currentUserRole,
        'type': MessageType.image.toString(),
        'content': caption ?? '',
        'imageUrl': imageUrl,
        'timestamp': Timestamp.fromDate(now),
        'readBy': [_currentUserId!],
        'status': MessageStatus.sent.toString(),
        'isEdited': false,
        'isDeleted': false,
      };
      
      await _firestore
          .collection('chats')
          .doc(_currentConversation!.id)
          .collection('messages')
          .add(messageData);
      
      await _updateConversationLastMessage(
        _currentConversation!.id,
        '📷 Image',
        now,
        _currentUserId!,
      );
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending image: \$e');
      rethrow;
    }
  }
  
  // Send system message
  Future<void> _sendSystemMessage(String conversationId, String content) async {
    try {
      final messageData = {
        'chatId': conversationId,
        'senderId': 'system',
        'senderName': 'System',
        'senderRole': 'system',
        'type': MessageType.system.toString(),
        'content': content,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'readBy': [],
        'status': MessageStatus.sent.toString(),
        'isEdited': false,
        'isDeleted': false,
      };
      
      await _firestore
          .collection('chats')
          .doc(conversationId)
          .collection('messages')
          .add(messageData);
      
    } catch (e) {
      debugPrint('Error sending system message: \$e');
    }
  }
  
  // Update conversation's last message info
  Future<void> _updateConversationLastMessage(
    String conversationId,
    String lastMessage,
    DateTime timestamp,
    String senderId,
  ) async {
    try {
      await _firestore.collection('chats').doc(conversationId).update({
        'lastMessage': lastMessage,
        'lastMessageTime': Timestamp.fromDate(timestamp),
        'lastMessageSenderId': senderId,
        'updatedAt': Timestamp.fromDate(timestamp),
      });
    } catch (e) {
      debugPrint('Error updating last message: \$e');
    }
  }
  
  // Mark messages as read
  Future<void> _markMessagesAsRead(String conversationId) async {
    if (_currentUserId == null) return;
    
    try {
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: _currentUserId)
          .where('readBy', whereNotIn: [_currentUserId])
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in unreadMessages.docs) {
        final currentReadBy = List<String>.from(doc.data()['readBy'] ?? []);
        if (!currentReadBy.contains(_currentUserId)) {
          currentReadBy.add(_currentUserId!);
          batch.update(doc.reference, {'readBy': currentReadBy});
        }
      }
      
      if (unreadMessages.docs.isNotEmpty) {
        await batch.commit();
        
        // Update conversation unread count
        await _firestore.collection('chats').doc(conversationId).update({
          'unreadCount.\$_currentUserId': 0,
        });
      }
      
    } catch (e) {
      debugPrint('Error marking messages as read: \$e');
    }
  }
  
  // Show typing indicator
  Future<void> showTyping(String conversationId) async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore
          .collection('chats')
          .doc(conversationId)
          .collection('typing')
          .doc(_currentUserId)
          .set({
        'userId': _currentUserId,
        'userName': _currentUserName,
        'chatId': conversationId,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error showing typing: \$e');
    }
  }
  
  // Hide typing indicator
  Future<void> hideTyping(String conversationId) async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore
          .collection('chats')
          .doc(conversationId)
          .collection('typing')
          .doc(_currentUserId)
          .delete();
    } catch (e) {
      debugPrint('Error hiding typing: \$e');
    }
  }
  
  // Listen to typing indicators
  void _listenToTypingIndicators(String conversationId) {
    _typingListener?.cancel();
    _typingListener = _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('typing')
        .snapshots()
        .listen(
      (snapshot) {
        final indicators = snapshot.docs
            .map((doc) => TypingIndicator.fromFirestore(doc))
            .where((indicator) => 
                indicator.userId != _currentUserId && 
                !indicator.isExpired)
            .toList();
        
        _typingIndicators[conversationId] = indicators;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to typing indicators: \$error');
      },
    );
  }
  
  // Get typing users for a conversation
  List<String> getTypingUsers(String conversationId) {
    final indicators = _typingIndicators[conversationId] ?? [];
    return indicators.map((indicator) => indicator.userName).toList();
  }
  
  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    if (_currentConversation == null) return;
    
    try {
      await _firestore
          .collection('chats')
          .doc(_currentConversation!.id)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'content': 'This message was deleted',
      });
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting message: \$e');
      rethrow;
    }
  }
  
  // Edit a message
  Future<void> editMessage(String messageId, String newContent) async {
    if (_currentConversation == null) return;
    
    try {
      await _firestore
          .collection('chats')
          .doc(_currentConversation!.id)
          .collection('messages')
          .doc(messageId)
          .update({
        'content': newContent,
        'isEdited': true,
        'editedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      _error = e.toString();
      debugPrint('Error editing message: \$e');
      rethrow;
    }
  }
  
  // Get unread count for a conversation
  int getUnreadCount(String conversationId) {
    final conversation = _conversations.firstWhere(
      (conv) => conv.id == conversationId,
      orElse: () => ChatModel(
        id: '',
        participants: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    if (conversation.id.isEmpty || _currentUserId == null) return 0;
    return conversation.getUnreadCountForUser(_currentUserId!);
  }
  
  // Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (_currentConversation == null || _messages.isEmpty) return;
    
    try {
      final oldestMessage = _messages.first;
      final snapshot = await _firestore
          .collection('chats')
          .doc(_currentConversation!.id)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .startAfter([Timestamp.fromDate(oldestMessage.timestamp)])
          .limit(20)
          .get();
      
      final olderMessages = snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList()
          .reversed
          .toList();
      
      _messages.insertAll(0, olderMessages);
      notifyListeners();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading more messages: \$e');
    }
  }
  
  // Clear current conversation
  void clearCurrentConversation() {
    _currentConversation = null;
    _messages.clear();
    _messagesListener?.cancel();
    _typingListener?.cancel();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _conversationsListener?.cancel();
    _messagesListener?.cancel();
    _typingListener?.cancel();
    super.dispose();
  }
}
