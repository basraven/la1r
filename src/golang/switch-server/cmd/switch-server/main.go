package main

import (
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stianeikeland/go-rpio/v4"
)

var (
	pin      rpio.Pin
	pinValue int
	mu       sync.Mutex
)

func main() {
	// Open and map memory to access GPIO, check for errors
	if err := rpio.Open(); err != nil {
		log.Fatal(err)
	}
	defer rpio.Close()

	// Set input pins
	inputPins := []rpio.Pin{
		rpio.Pin(16),
	}
	// Set output pins
	outputPins := []rpio.Pin{
		rpio.Pin(13),
	}

	// Start parallel pin reading
	go readPins(&inputPins)
	go writePins(&outputPins)

	// Initialize Gin router
	r := gin.Default()

	// Route handles & endpoints
	r.GET("/switch", getSwitchValue)

	// Start server
	log.Println("Server is running on port 8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatal(err)
	}
}

func writePins(pin *[]rpio.Pin) {
	for _, pin := range *pin {
		pin.Output()
		pin.Low()
	}
	for {
		for _, pin := range *pin {
			pin.High()
			time.Sleep(100 * time.Millisecond)
			pin.Low()
			time.Sleep(100 * time.Millisecond)
		}
	}
}

func readPins(inputPins *[]rpio.Pin) {
	for _, pin := range *inputPins {
		pin.Input()
		pin.PullUp()
	}
	for {
		for _, pin := range *inputPins {
			pinValue = int(pin.Read())
			log.Printf("Pin %d value: %d", pin, pinValue)
		}
		time.Sleep(100 * time.Millisecond)
	}
}

func getSwitchValue(c *gin.Context) {
	mu.Lock()
	value := pinValue
	mu.Unlock()

	c.JSON(http.StatusOK, gin.H{"value": value})
}
