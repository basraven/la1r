package main

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/stianeikeland/go-rpio/v4"

	"switch-server/gist/gisthandlers"
	gpiohandlers "switch-server/gpio/gpiohandlers"
	v1 "switch-server/http/v1"
	hwpwm "switch-server/internal/hardware-pwm"
	"switch-server/internal/models"
)

func main() {
	// Initialize GPIO
	if err := rpio.Open(); err != nil {
		log.Fatal(err)
	}
	defer rpio.Close()

	// FIXME: This should be contained in the NewDeviceStates function
	pwm, err := hwpwm.NewHardwarePWM(0, 60, 0)
	if err != nil {
		log.Fatal(err)
		return
	}
	defer pwm.Stop()

	var deviceStates, deviceEvents = models.NewDeviceStates(
		[]models.DeviceState{
			{Id: 1, Name: "Linux-Wayne", State: 2, GpioOut: rpio.Pin(17), Ssh: "192.168.5.1"},
			{Id: 2, Name: "Stephanie", State: 2},
			{Id: 3, Name: "Jay-C", State: 2, GpioIn: rpio.Pin(26), GpioOut: rpio.Pin(22), StatusLed: rpio.Pin(16), Ssh: "192.168.5.3"},
			{Id: 4, Name: "Kirby", State: 2, Pwm: *pwm},
		},
	)
	// Set up logging
	log.SetFlags(log.Ldate | log.Ltime | log.Lmicroseconds | log.Lshortfile)
	log.SetPrefix("INFO: ")

	// Start parallel pin reading
	go gpiohandlers.ReadForGpioInputChangeAndBlink(deviceStates, deviceEvents)
	go gisthandlers.WatchGistChanges(deviceStates, deviceEvents)

	// Start output handlers
	go gpiohandlers.OutputPWMOnEvent(deviceStates, deviceEvents)
	go gpiohandlers.OutputDeviceOnEvent(deviceStates, deviceEvents)

	// Initialize Gin router
	r := gin.Default()
	if err := r.SetTrustedProxies([]string{"10.8.0.0/24", "192.168.0.0/16"}); err != nil {
		log.Fatal(err)
	}

	// API v1
	v1Group := r.Group("/api/v1")
	v1.SetupRoutes(v1Group, deviceStates, deviceEvents)
	// API v2
	// v2Group := r.Group("/api/v2")
	// v2.SetupRoutes(v2Group, &deviceStates, deviceStatesEvents)

	// Start server
	if err := r.Run(":50505"); err != nil {
		log.Fatal(err)
	}

}
