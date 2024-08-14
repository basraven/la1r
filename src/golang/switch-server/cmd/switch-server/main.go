package main

import (
	"fmt"
	"log"
	"sync"
	"time"

	hwpwm "switch-server/internal/hardware-pwm"

	"github.com/stianeikeland/go-rpio/v4"
)

var (
	// Config of Server Switches
	SWITCH_CONFIG = map[int]struct {
		Pin rpio.Pin
		IP  string
	}{
		1: {Pin: rpio.Pin(17), IP: "192.168.5.1"},
		3: {Pin: rpio.Pin(22), IP: "192.168.5.3"},
	}

	lastSwitchOnTime = map[int]time.Time{}
	COOLDOWN_PERIOD  = 2 * time.Minute

	LED_PIN       = rpio.Pin(19)
	SWITCH_16_PIN = rpio.Pin(16)
	FREQUENCY     = 60
	pwmDutyCycle  = 0.0

	executor = &sync.WaitGroup{}
	mu       = &sync.Mutex{}
)

func initializeGpio() {

	// Initialize GPIO
	if err := rpio.Open(); err != nil {
		log.Fatalf("Error initializing GPIO: %v", err)
	}

	LED_PIN.Output()
	SWITCH_16_PIN.Input()

	for _, config := range SWITCH_CONFIG {
		config.Pin.Output()
		config.Pin.Low()
	}
}

func main() {

	// Using the SomeFunction from pkg/somepackage
	// message := somepackage.SomeFunction()
	// log.Println(message)

	// initializeGpio()

	hwPWM, err := hwpwm.NewHardwarePWM(0, 60, 0)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	log.Println("starting with 100")
	err = hwPWM.start(100)
	if err != nil {
		fmt.Println("Error starting PWM:", err)
		return
	}

	time.Sleep(20 * time.Second)

	log.Println("starting with 50 duty")
	err = hwPWM.changeDutyCycle(50)
	if err != nil {
		fmt.Println("Error changing duty cycle:", err)
		return
	}

	time.Sleep(20 * time.Second)

	// ledState := rpio.Low
	// for {
	// 	if ledState == rpio.Low {
	// 		ledState = rpio.High
	// 	} else {
	// 		ledState = rpio.Low
	// 	}
	// 	log.Println("Switching to ", ledState)
	// 	LED_PIN.Write(ledState)
	// 	// Small sleep to avoid high CPU usage
	// 	time.Sleep(1000 * time.Millisecond)
	// }

	// // Setting up the HTTP server with a handler from the API package
	// http.HandleFunc("/", v1.HandleRequest)

	// // Start the server on port 8080
	// log.Println("Starting server on :9080")
	// log.Fatal(http.ListenAndServe(":9080", nil))
	// log.Println("Server started on :9080")

	pwm, err := hwpwm.NewHardwarePWM(0, 60, 0)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}
	// defer pwm.Stop()
	pwm.Start(100)
}
