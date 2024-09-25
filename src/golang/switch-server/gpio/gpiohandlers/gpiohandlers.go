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
	LastToggle             = make(map[int]time.Time)
)

func ReadForGpioInputChange(deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	pastToggleValue := make(map[int]int)
	for _, state := range *deviceStates {
		if state.GpioIn != 0 {
			state.GpioIn.Input()
			state.GpioIn.PullDown()
		}
	}
	for {
		for _, state := range *deviceStates {

			if state.GpioIn != 0 {
				var pinValue int
				// if has a LedGpioOut, toggle it
				if state.ReadMutex != nil { // IMPORTANT! This is a hack to make sure the pin is set to output before reading the value
					state.ReadMutex.Lock()
					state.GpioOut.High()
					time.Sleep(1000 * time.Millisecond)
					pinValue = int(state.GpioIn.Read())
					state.GpioOut.Low()
					state.ReadMutex.Unlock()
					log.Printf("pinValue with = %d", pinValue)
				} else {
					pinValue = int(state.GpioIn.Read())
					log.Printf("pinValue without = %d", pinValue)
				}

				if _, exists := pastToggleValue[state.Id]; !exists { // first time reading the pin value, no toggle
					pastToggleValue[state.Id] = pinValue
					continue
				} else if pastToggleValue[state.Id] != pinValue { // if the pin value has changed
					log.Printf("pastToggleValue[%d] = %d, pinValue = %d", state.Id, pastToggleValue[state.Id], pinValue)

					// If cooldown not active
					if time.Since(LastToggle[state.Id]) > GPIO_SWITCHON_COOLDOWN {
						LastToggle[state.Id] = time.Now()
						state.State = pinValue
						LastToggle[state.Id] = time.Now()
						changeEvent := models.DeviceStateChange{
							Timestamp: time.Now(),
							Id:        state.Id,
							State:     pinValue,
						}
						deviceEvents.State <- changeEvent
						pastToggleValue[state.Id] = pinValue
					} else {
						log.Printf("Cooldown of %d seconds active", GPIO_SWITCHON_COOLDOWN)
					}

				}
			}
		}
		time.Sleep(1000 * time.Millisecond)
	}
}

func OutputLedOnStateChange(deviceStates *models.DeviceStates) {
	for _, state := range *deviceStates {
		if state.StatusLed != 0 {
			state.StatusLed.Output()
			state.ReadMutex.Lock()
			state.StatusLed.Low()
			state.ReadMutex.Unlock()
		}
	}

	blinkStates := make(map[int]bool)
	for {
		for _, state := range *deviceStates {
			if state.StatusLed != 0 {

				if state.State == 2 {
					// log.Printf("State %d is unsure", state.Id)
					blink(&blinkStates, &state)
					time.Sleep(1000 * time.Millisecond)
					blink(&blinkStates, &state)
					time.Sleep(1000 * time.Millisecond)
					blink(&blinkStates, &state)
				} else if state.State == 1 {
					// log.Printf("State %d is turned on", state.Id)
					state.ReadMutex.Lock()
					state.StatusLed.High() // Turn on the LED
					state.ReadMutex.Unlock()
				} else if state.State == 0 {
					// log.Printf("State %d is turned off", state.Id)
					blink(&blinkStates, &state)
				}
			}
		}
		time.Sleep(1000 * time.Millisecond)
	}
}

func blink(blinkStates *map[int]bool, state *models.DeviceState) {
	// Initialize state.Id in blinkStates if it doesn't exist
	if _, exists := (*blinkStates)[state.Id]; !exists {
		(*blinkStates)[state.Id] = false // Initialize as low (off)
	}

	// Alternate the LED state based on current blink state
	if (*blinkStates)[state.Id] {
		state.ReadMutex.Lock()
		state.StatusLed.Low()
		state.ReadMutex.Unlock()
		(*blinkStates)[state.Id] = false // Update blink state to off
		// log.Printf("Blink Low %d", state.Id)
	} else {
		state.ReadMutex.Lock()
		state.StatusLed.High()
		state.ReadMutex.Unlock()
		(*blinkStates)[state.Id] = true // Update blink state to on
		// log.Printf("Blink High %d", state.Id)
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
	// log.Printf("In handleSwitchDevice with gpio %d", state.GpioOut)
	// log.Printf("event in SwitchDeviceOnChange %+v", event)

	available, err := isHostAvailable(state.Ssh, 22, (5 * time.Second))

	if event.State == 1 && err != nil { // Target: On, Host: unavailable
		state.GpioOut.Output()
		state.GpioOut.High()
		time.Sleep(700 * time.Millisecond)
		state.GpioOut.Low()
		*event.Callback <- fmt.Sprintf("Device is switched on %d", state.Id)
	} else if event.State == 0 && err != nil { // Target: Off, Host: unavailable
		*event.Callback <- "Device is already off"
	} else if event.State == 0 && err == nil && available { // Target: Off, Host: available
		// path := os.Getenv("HOME") + "/.ssh/id_rsa"
		path := "/home/basraven/.ssh/id_rsa"
		if err := softShutdownHost(state.Ssh, "basraven", path); err != nil {
			*event.Callback <- fmt.Sprintf("Error in soft shutdown: %v", err)
		} else {
			*event.Callback <- "Device is switched off softly"
		}
	} else if event.State == 1 && err == nil && available { // Target: On, Host: available
		*event.Callback <- "Device is already switched on"
	} else {
		*event.Callback <- fmt.Sprintf("Host %s is in limbo state.\n", state.Ssh)
	}

	// if state.State == 2 {
	// 	*event.Callback <- fmt.Sprintf("Not switching device %d because state was unsure", state.GpioOut)
	// } else if event.State == 1 && state.State == 0 {
	// 	state.GpioOut.Output()
	// 	state.GpioOut.High()
	// 	*event.Callback <- fmt.Sprintf("Switching on device %d", state.GpioOut)
	// } else if event.State == 0 && state.State == 1 {
	// 	state.GpioOut.Output()
	// 	state.GpioOut.Low()
	// 	*event.Callback <- fmt.Sprintf("Switching off device %d", state.GpioOut)
	// } else {
	// 	*event.Callback <- fmt.Sprintf("Can't switch device %d from %d to %d", state.GpioOut, state.State, event.State)
	// }
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
