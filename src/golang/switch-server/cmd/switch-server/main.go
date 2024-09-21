package main

import (
	"log"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stianeikeland/go-rpio/v4"
)

var (
	pin        rpio.Pin
	pinValue   int
	mu         sync.Mutex
	outputPins []rpio.Pin
)

type ServerStates struct {
	Id    int
	Name  string
	State int // 2 = unsure, 1 = on, 0 = off
}

type serverStateEvent struct {
	Id    int
	State int // 2 = unsure, 1 = on, 0 = off
}

var serverStates = []ServerStates{
	{Id: 1, Name: "Linux-Wayne", State: 2},
	{Id: 2, Name: "Stephanie", State: 2},
	{Id: 3, Name: "Jay-C", State: 2},
}

func main() {
	// Create an event channel
	serverStateEvents := make(chan serverStateEvent)

	// Start the server state event handler
	go handleServerStateEvents(serverStateEvents)

	// Output the server states
	go outputServerStates(&serverStates)

	// Open and map memory to access GPIO, check for errors
	if err := rpio.Open(); err != nil {
		log.Fatal(err)
	}
	defer rpio.Close()

	// Set input pins
	inputPins := []rpio.Pin{
		rpio.Pin(16),
		// rpio.Pin(20),
		// rpio.Pin(21),
	}
	// Set output pins

	outputPins = []rpio.Pin{
		rpio.Pin(13),
		// rpio.Pin(19),
		// rpio.Pin(26),
	}

	// Start parallel pin reading and writing
	go readForSwitchToggle(&inputPins, serverStateEvents)
	// go writePins(&outputPins)

	// Initialize Gin router
	r := gin.Default()

	// Route handles & endpoints for serverStates
	r.GET("/status", handleAllStatusRequest)
	r.GET("/status/:identifier", handleSpecificStatusRequest)
	r.GET("/start/:identifier", handleStartRequest)
	// r.GET("/stop/:identifier", handleStopRequest)

	// Start server
	log.Println("Server is running on port 8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatal(err)
	}
}
func outputServerStates(serverStates *[]ServerStates) {
	for {
		for _, server := range *serverStates {
			log.Printf("Server %d: %s - State: %d", server.Id, server.Name, server.State)
		}
		time.Sleep(5 * time.Second)
	}
}

func handleServerStateEvents(serverStateEvents chan serverStateEvent) {
	for event := range serverStateEvents {
		log.Printf("Received event: %+v", event)
		// Update server state based on the event
		for i, server := range serverStates {
			if server.Id == event.Id {
				serverStates[i].State = event.State
				log.Printf("Updated server state: %+v", serverStates[i])
			}
		}
	}
}

func readForSwitchToggle(inputPins *[]rpio.Pin, serverStateEvents chan<- serverStateEvent) {
	for _, pin := range *inputPins {
		pin.Input()
		pin.PullUp()
	}
	for {
		for _, pin := range *inputPins {
			pinValue := int(pin.Read())
			log.Printf("Pin %d value: %d", pin, pinValue)
			if pinValue == 1 {
				serverStateEvents <- serverStateEvent{Id: int(pin), State: 1}
			} else {
				serverStateEvents <- serverStateEvent{Id: int(pin), State: 0}
			}
		}
		time.Sleep(100 * time.Millisecond)
	}
}

func handleAllStatusRequest(c *gin.Context) {
	c.JSON(200, serverStates)
}

func handleSpecificStatusRequest(c *gin.Context) {
	identifier := c.Param("identifier")

	// Try to parse the identifier as an integer (ID)
	if id, err := strconv.Atoi(identifier); err == nil {
		for _, state := range serverStates {
			if state.Id == id {
				c.JSON(200, state)
				return
			}
		}
	} else {
		// If not an integer, treat it as a name
		for _, state := range serverStates {
			if strings.EqualFold(state.Name, identifier) {
				c.JSON(200, state)
				return
			}
		}
	}

	c.JSON(404, gin.H{"error": "Server state not found"})
}

func handleStartRequest(c *gin.Context, serverStateEvents chan<- ServerStateEvent) {
	identifier := c.Param("identifier")
	// Try to parse the identifier as an integer (ID)
	if id, err := strconv.Atoi(identifier); err == nil {
		for _, state := range serverStates {
			if state.Id == id {
				serverStateEvents <- ServerStateEvent{Id: id, State: 1}
				c.JSON(200, gin.H{"message": "Server started"})
				return
			}
		}
	} else {
		// If not an integer, treat it as a name
		for _, state := range serverStates {
			if strings.EqualFold(state.Name, identifier) {
				serverStateEvents <- ServerStateEvent{Id: state.Id, State: 1}
				c.JSON(200, gin.H{"message": "Server started"})
				return
			}
		}
	}
	c.JSON(404, gin.H{"message": "Server not found"})
}
