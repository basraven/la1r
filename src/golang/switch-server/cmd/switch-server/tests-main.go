// package main

// import (
// 	"log"
// 	"sync"
// 	"time"

// 	"github.com/stianeikeland/go-rpio/v4"
// )

// var (
// 	// Config of Server Switches
// 	SWITCH_CONFIG = map[int]struct {
// 		Pin rpio.Pin
// 		IP  string
// 	}{
// 		1: {Pin: rpio.Pin(17), IP: "192.168.5.1"},
// 		3: {Pin: rpio.Pin(22), IP: "192.168.5.3"},
// 	}

// 	lastSwitchOnTime = map[int]time.Time{}
// 	COOLDOWN_PERIOD  = 2 * time.Minute

// 	LED_PIN       = rpio.Pin(13)
// 	SWITCH_16_PIN = rpio.Pin(16)
// 	FREQUENCY     = 60
// 	pwmDutyCycle  = 0.0

// 	executor = &sync.WaitGroup{}
// 	mu       = &sync.Mutex{}
// )

// func initializeGpio() {

// 	// Initialize GPIO
// 	if err := rpio.Open(); err != nil {
// 		log.Fatalf("Error initializing GPIO: %v", err)
// 	}
// 	defer rpio.Close()

// 	LED_PIN.Output()
// 	SWITCH_16_PIN.Input()

// 	for _, config := range SWITCH_CONFIG {
// 		config.Pin.Output()
// 		config.Pin.Low()
// 	}
// }

// func main() {

// 	// Using the SomeFunction from pkg/somepackage
// 	// message := somepackage.SomeFunction()
// 	// log.Println(message)

// 	initializeGpio()

// 	// hwPWM, err := hwpwm.NewHardwarePWM(0, 60, 0)
// 	// if err != nil {
// 	// 	fmt.Println("Error:", err)
// 	// 	return
// 	// }
// 	// defer hwPWM.Stop()

// 	// log.Println("starting with 100")
// 	// err = hwPWM.Start(100)
// 	// if err != nil {
// 	// 	fmt.Println("Error starting PWM:", err)
// 	// 	return
// 	// }

// 	// time.Sleep(20 * time.Second)

// 	// log.Println("starting with 50 duty")
// 	// err = hwPWM.ChangeDutyCycle(50)
// 	// if err != nil {
// 	// 	fmt.Println("Error changing duty cycle:", err)
// 	// 	return
// 	// }

// 	// time.Sleep(20 * time.Second)

// 	// log.Println("starting with 0 duty")
// 	// err = hwPWM.ChangeDutyCycle(0)
// 	// if err != nil {
// 	// 	fmt.Println("Error changing duty cycle:", err)
// 	// 	return
// 	// }

// 	// time.Sleep(20 * time.Second)

// 	// ledState := rpio.Low
// 	// for {
// 	if ledState == rpio.Low {
// 		ledState = rpio.High
// 	} else {
// 		ledState = rpio.Low
// 	}
// 	log.Println("Switching to ", ledState)
// 	LED_PIN.Write(ledState)
// 	// 	// Small sleep to avoid high CPU usage
// 	// 	time.Sleep(1000 * time.Millisecond)
// 	// }

// 	// // Setting up the HTTP server with a handler from the API package
// 	// http.HandleFunc("/", v1.HandleRequest)

// 	// // Start the server on port 8080
// 	// log.Println("Starting server on :9080")
// 	// log.Fatal(http.ListenAndServe(":9080", nil))
// 	// log.Println("Server started on :9080")

// 	// // Set up SWITCH_16_PIN as input
// 	// SWITCH_16_PIN := rpio.Pin(16)
// 	// SWITCH_16_PIN.Input()
// 	SWITCH_16_PIN.PullUp()

// 	// Continuously read SWITCH_16_PIN
// 	for {
// 		switchState := SWITCH_16_PIN.Read()
// 		log.Printf("SWITCH_16_PIN state: %v", switchState)

// 		// Small sleep to avoid high CPU usage
// 		time.Sleep(100 * time.Millisecond)
// 	}

// }
