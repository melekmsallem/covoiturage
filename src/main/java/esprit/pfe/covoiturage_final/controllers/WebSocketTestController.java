package esprit.pfe.covoiturage_final.controllers;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/websocket")
@CrossOrigin(origins = "*", maxAge = 3600)
public class WebSocketTestController {

    @GetMapping("/test")
    public ResponseEntity<String> websocketTest() {
        String html = """
            <!DOCTYPE html>
            <html>
            <head>
                <title>WebSocket Test</title>
                <script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
                <script src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>
            </head>
            <body>
                <h1>WebSocket Test Page</h1>
                <div id="status">Connecting...</div>
                <button onclick="connect()">Connect</button>
                <button onclick="disconnect()">Disconnect</button>
                <br><br>
                <input type="text" id="messageInput" placeholder="Enter message">
                <button onclick="sendMessage()">Send Message</button>
                <br><br>
                <div id="messages"></div>
                
                <script>
                    let stompClient = null;
                    
                    function connect() {
                        const socket = new SockJS('/ws');
                        stompClient = Stomp.over(socket);
                        
                        stompClient.connect({}, function (frame) {
                            document.getElementById('status').innerHTML = 'Connected: ' + frame;
                            console.log('Connected: ' + frame);
                            
                            stompClient.subscribe('/topic/public', function (message) {
                                showMessage('Received: ' + message.body);
                            });
                        }, function(error) {
                            document.getElementById('status').innerHTML = 'Connection error: ' + error;
                            console.log('Connection error: ' + error);
                        });
                    }
                    
                    function disconnect() {
                        if (stompClient !== null) {
                            stompClient.disconnect();
                        }
                        document.getElementById('status').innerHTML = 'Disconnected';
                    }
                    
                    function sendMessage() {
                        const message = document.getElementById('messageInput').value;
                        if (message && stompClient) {
                            stompClient.send("/app/chat", {}, JSON.stringify({
                                sender: 'TestUser',
                                content: message,
                                type: 'CHAT'
                            }));
                            document.getElementById('messageInput').value = '';
                        }
                    }
                    
                    function showMessage(message) {
                        const messagesDiv = document.getElementById('messages');
                        const messageElement = document.createElement('div');
                        messageElement.textContent = new Date().toLocaleTimeString() + ' - ' + message;
                        messagesDiv.appendChild(messageElement);
                    }
                    
                    // Auto-connect on page load
                    window.onload = function() {
                        connect();
                    };
                </script>
            </body>
            </html>
            """;
        return ResponseEntity.ok()
                .header("Content-Type", "text/html")
                .body(html);
    }
    
    @GetMapping("/status")
    public ResponseEntity<String> websocketStatus() {
        return ResponseEntity.ok("WebSocket endpoints are available at /ws and /notifications");
    }
}


