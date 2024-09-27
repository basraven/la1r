package handlers

import (
	"fmt"
	"log"
	"net"
	"os"
	"switch-server/internal/models"
	"time"

	"golang.org/x/crypto/ssh"
)

var (
	GPIO_SWITCHON_COOLDOWN = time.Second * 10
)

func ReadForGpioInputChangeAndBlink(deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	lastToggleValue := make(map[int]int)
	lastToggleTime := make(map[int]time.Time)
	for _, state := range *deviceStates {
		if state.GpioIn != 0 {
			state.GpioIn.Input()
			state.GpioIn.PullDown()
		}
		if state.StatusLed != 0 {
			state.StatusLed.Output()
		}

		// Start with cooldown time to not switch servers from the getgo
		lastToggleTime[state.Id] = time.Now()
	}
	blinkStates := make(map[int]bool)
	for {
		for _, state := range *deviceStates {

			// Read part
			if state.GpioIn != 0 {
				var pinValue int

				state.StatusLed.High()
				time.Sleep(500 * time.Millisecond)
				pinValue = int(state.GpioIn.Read())
				// log.Printf("pinValue with = %d with state.Id %d", pinValue, state.Id)
				if lastToggleValue[state.Id] != pinValue { // if the pin value has changed
					// log.Printf("pastToggleValue[%d] = %d, pinValue = %d", state.Id, lastToggleValue[state.Id], pinValue)

					var targetState int
					switch state.State {
					case 2: // System state unsure
						targetState = 1
					case 1: // System is on, should be off now
						targetState = 0
					case 0: // System is off, should be on now
						targetState = 1
					}
					// If cooldown not active
					if time.Since(lastToggleTime[state.Id]) > GPIO_SWITCHON_COOLDOWN {
						// log.Printf("switching server to %d", pinValue)
						callback := make(chan string)
						changeEvent := models.DeviceStateChange{
							Timestamp: time.Now(),
							Id:        state.Id,
							State:     targetState,
							OutputChannels: []*chan models.DeviceStateChange{
								&deviceEvents.OutputDevice,
							},
							Callback: &callback,
						}
						deviceEvents.State <- changeEvent

						callbackValue, ok := <-callback
						if ok {
							log.Printf("Hardware switch changed device with %s", callbackValue)
							lastToggleTime[state.Id] = time.Now()
							lastToggleValue[state.Id] = pinValue
						} else {
							log.Printf("Hardware switch ERROR, did not change device state")
						}
						close(callback)

					} else {
						remainingCooldown := GPIO_SWITCHON_COOLDOWN - time.Since(lastToggleTime[state.Id])
						log.Printf("Cooldown of %.2f seconds remaining", remainingCooldown.Seconds())
						lastToggleValue[state.Id] = pinValue
					}
				}
				// state.StatusLed.Low()
			}

			// Blink part
			if state.StatusLed != 0 {
				if state.State == 2 {
					// log.Printf("State %d is unsure", state.Id)
					// time.Sleep(200 * time.Millisecond)
					blink(&blinkStates, &state)
					time.Sleep(300 * time.Millisecond)
					blink(&blinkStates, &state)
					time.Sleep(300 * time.Millisecond)
					blink(&blinkStates, &state)
				} else if state.State == 1 {
					// log.Printf("State %d is turned on", state.Id)
					time.Sleep(500 * time.Millisecond)
					state.StatusLed.High() // Turn on the LED
				} else if state.State == 0 {
					// log.Printf("State %d is turned off", state.Id)
					time.Sleep(500 * time.Millisecond)
					blink(&blinkStates, &state)
				}
			}
		}
		time.Sleep(600 * time.Millisecond)
	}
}

func blink(blinkStates *map[int]bool, state *models.DeviceState) {
	// Initialize state.Id in blinkStates if it doesn't exist
	if _, exists := (*blinkStates)[state.Id]; !exists {
		(*blinkStates)[state.Id] = false // Initialize as low (off)
	}

	// Alternate the LED state based on current blink state
	if (*blinkStates)[state.Id] {
		state.StatusLed.Low()
		(*blinkStates)[state.Id] = false // Update blink state to off
	} else {
		state.StatusLed.High()
		(*blinkStates)[state.Id] = true // Update blink state to on
	}
}

func OutputDeviceOnEvent(deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	for event := range deviceEvents.OutputDevice {
		// log.Printf("event in SwitchDeviceOnChange %+v", event)
		state := deviceStates.GetById(event.Id)
		if state.GpioOut == 0 { // If no gpio out put is set, skip
			continue
		}
		handleSwitchDevice(state, &event)

	}
}

func handleSwitchDevice(state *models.DeviceState, event *models.DeviceStateChange) {
	// log.Printf("event in SwitchDeviceOnChange %+v", event)

	available, err := isHostAvailable(state.Ssh, 22, (5 * time.Second))

	if event.State == 1 && err != nil { // Target: On, Host: unavailable
		state.GpioOut.Output()
		state.GpioOut.High()
		time.Sleep(700 * time.Millisecond)
		state.GpioOut.Low()
		if *event.Callback != nil {
			*event.Callback <- fmt.Sprintf("Device is switched on %d", state.Id)
		}
	} else if event.State == 0 && err != nil { // Target: Off, Host: unavailable
		if *event.Callback != nil {
			*event.Callback <- "Device is already off"
		}
	} else if event.State == 0 && err == nil && available { // Target: Off, Host: available
		// path := os.Getenv("HOME") + "/.ssh/id_rsa"
		path := "/home/basraven/.ssh/id_rsa"
		if err := softShutdownHost(state.Ssh, "basraven", path); err != nil {
			if *event.Callback != nil {
				*event.Callback <- fmt.Sprintf("Error in soft shutdown: %v", err)
			}
		} else {
			if *event.Callback != nil {
				*event.Callback <- "Device is switched off softly"
			}
		}
	} else if event.State == 1 && err == nil && available { // Target: On, Host: available
		if *event.Callback != nil {
			*event.Callback <- "Device is already switched on"
		}
	} else {
		if *event.Callback != nil {
			*event.Callback <- fmt.Sprintf("Host %s is in limbo state.\n", state.Ssh)
		}
	}
}

func isHostAvailable(host string, port int, timeout time.Duration) (bool, error) {
	address := fmt.Sprintf("%s:%d", host, port)
	conn, err := net.DialTimeout("tcp", address, timeout)
	if err != nil {
		return false, err // Connection failed
	}
	defer conn.Close() // Ensure the connection is closed
	return true, nil   // Connection successful
}

func softShutdownHost(host, user, privateKeyPath string) error {
	// Load the private key
	privateKey, err := os.ReadFile(privateKeyPath)
	if err != nil {
		return fmt.Errorf("unable to read private key: %w", err)
	}

	// Create the signer for the private key
	signer, err := ssh.ParsePrivateKey(privateKey)
	if err != nil {
		return fmt.Errorf("unable to parse private key: %w", err)
	}

	// Create SSH client configuration
	config := &ssh.ClientConfig{
		User: user,
		Auth: []ssh.AuthMethod{
			ssh.PublicKeys(signer),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(), // Use a secure method in production
	}

	address := fmt.Sprintf("%s:%d", host, 22)
	conn, err := ssh.Dial("tcp", address, config)
	if err != nil {
		return err // Connection failed
	}
	defer conn.Close() // Ensure the connection is closed

	// Create a new session
	session, err := conn.NewSession()
	if err != nil {
		return err // Session creation failed
	}
	defer session.Close() // Ensure the session is closed

	// Execute the shutdown command
	cmd := "sudo shutdown now" // Use 'poweroff' or 'halt' as needed
	if err := session.Run(cmd); err != nil {
		return err // Command execution failed
	}

	return nil // Command executed successfully
}
