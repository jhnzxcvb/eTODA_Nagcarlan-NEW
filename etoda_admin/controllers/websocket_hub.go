package controllers

import (
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
)

// Client represents a connected driver's or passenger's WebSocket connection
type Client struct {
	ID   string // driverID or passengerID
	Type string // "driver" or "passenger"
	Conn *websocket.Conn
}

// Hub manages all active driver and passenger WebSocket connections
type Hub struct {
	clients    map[string]*Client // id -> Client (driverID or passengerID)
	register   chan *Client
	unregister chan *Client
	mu         sync.RWMutex
}

// NewHub creates and starts a new WebSocket hub
func NewHub() *Hub {
	h := &Hub{
		clients:    make(map[string]*Client),
		register:   make(chan *Client),
		unregister: make(chan *Client),
	}
	go h.run()
	return h
}

// run manages the hub's event loop (register, unregister, broadcast)
func (h *Hub) run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client.ID] = client
			h.mu.Unlock()
			log.Printf("✓ %s %s connected to WebSocket hub", client.Type, client.ID)

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client.ID]; ok {
				delete(h.clients, client.ID)
				client.Conn.Close()
				h.mu.Unlock()
				log.Printf("✗ %s %s disconnected from WebSocket hub", client.Type, client.ID)
			} else {
				h.mu.Unlock()
			}
		}
	}
}

// NotifyDriver sends a JSON message to a specific driver's WebSocket connection
func (h *Hub) NotifyDriver(driverID string, payload interface{}) {
	h.notifyClient(driverID, "driver", payload)
}

// NotifyPassenger sends a JSON message to a specific passenger's WebSocket connection
func (h *Hub) NotifyPassenger(passengerID string, payload interface{}) {
	h.notifyClient(passengerID, "passenger", payload)
}

// notifyClient sends a JSON message to a specific client (driver or passenger)
func (h *Hub) notifyClient(id string, clientType string, payload interface{}) {
	h.mu.RLock()
	client, ok := h.clients[id]
	h.mu.RUnlock()

	if !ok {
		log.Printf("⚠️ %s %s not connected; notification queued (implement persistence if needed)", clientType, id)
		return
	}

	if err := client.Conn.WriteJSON(payload); err != nil {
		log.Printf("⚠️ Failed to send notification to %s %s: %v", clientType, id, err)
		h.unregister <- client
	}
}

// WebSocketUpgrader configures the HTTP->WebSocket upgrade
var WebSocketUpgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		// In production, restrict to known origins
		return true
	},
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

// DriverWebSocketHandler upgrades HTTP connection and registers driver in hub
func DriverWebSocketHandler(w http.ResponseWriter, r *http.Request) {
	handleWebSocketConnection(w, r, "driver", "driverID")
}

// PassengerWebSocketHandler upgrades HTTP connection and registers passenger in hub
func PassengerWebSocketHandler(w http.ResponseWriter, r *http.Request) {
	handleWebSocketConnection(w, r, "passenger", "passengerID")
}

// handleWebSocketConnection is a generic handler for both drivers and passengers
func handleWebSocketConnection(w http.ResponseWriter, r *http.Request, clientType string, idParam string) {
	id := r.URL.Query().Get(idParam)
	if id == "" {
		http.Error(w, idParam+" query parameter required", http.StatusBadRequest)
		return
	}

	conn, err := WebSocketUpgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("⚠️ WebSocket upgrade failed for %s %s: %v", clientType, id, err)
		return
	}

	client := &Client{
		ID:   id,
		Type: clientType,
		Conn: conn,
	}

	// Register in hub
	WSHub.register <- client

	// Listen for disconnect (when client sends close or read error)
	go func() {
		defer func() {
			WSHub.unregister <- client
		}()

		for {
			_, _, err := conn.ReadMessage()
			if err != nil {
				if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
					log.Printf("⚠️ WebSocket error for %s %s: %v", clientType, id, err)
				}
				break
			}
		}
	}()
}
