package main

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/stianeikeland/go-rpio/v4"

	// "switch-server/cmd/switch-server/handlers"
	// "switch-server/cmd/switch-server/models"

	gpiohandlers "switch-server/gpio/handlers"
	v1 "switch-server/http/v1"
	"switch-server/internal/models"
	statehandlers "switch-server/state/handlers"
)

// var (
// 	pin        rpio.Pin
// 	pinValue   int
// 	mu         sync.Mutex
// 	outputPins []rpio.Pin
// )

var deviceStates = []models.DeviceStates{
	{Id: 1, Name: "Linux-Wayne", State: 2, GPIO: 16},
	{Id: 2, Name: "Stephanie", State: 2},
	{Id: 3, Name: "Jay-C", State: 2, GPIO: 17},
	{Id: 4, Name: "Kirby", State: 2, GPIO: 18},
}

func main() {
	// Set up logging
	log.SetFlags(log.Ltime)

	// Create an event channel
	DeviceStateEvents := make(chan models.DeviceStateEvent)

	// Start the server state event handler
	go statehandlers.HandleDeviceStateEvents(&deviceStates, DeviceStateEvents)

	// Open and map memory to access GPIO, check for errors
	if err := rpio.Open(); err != nil {
		log.Fatal(err)
	}
	defer rpio.Close()

	// Set input pins
	var inputPins []rpio.Pin
	for _, server := range deviceStates {
		if server.GPIO != 0 {
			inputPins = append(inputPins, rpio.Pin(server.GPIO))
		}
	}
	// Set output pins

	// outputPins := []rpio.Pin{
	// 	rpio.Pin(13),
	// 	// rpio.Pin(19),
	// 	// rpio.Pin(26),
	// }

	// Start parallel pin reading and writing
	go gpiohandlers.ReadForSwitchToggle(&inputPins, &deviceStates, DeviceStateEvents)

	// Initialize Gin router
	r := gin.Default()
	// API v1
	v1Group := r.Group("/api/v1")
	v1.SetupRoutes(v1Group, &deviceStates, DeviceStateEvents)
	// API v2
	// v2Group := r.Group("/api/v2")
	// v2.SetupRoutes(v2Group, &deviceStates, deviceStatesEvents)

	// Start server
	log.Println("Server is running on port 50505")
	if err := r.Run(":50505"); err != nil {
		log.Fatal(err)
	}
}
