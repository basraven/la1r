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

	// Initialize pin 16 as input
	pin = rpio.Pin(16)
	pin.Input()

	// Start parallel pin reading
	go readPin()

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

func readPin() {
	for {
		mu.Lock()
		pinValue = int(pin.Read())
		mu.Unlock()
		time.Sleep(100 * time.Millisecond)
	}
}

func getSwitchValue(c *gin.Context) {
	mu.Lock()
	value := pinValue
	mu.Unlock()

	c.JSON(http.StatusOK, gin.H{"value": value})
}
