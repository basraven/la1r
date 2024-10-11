package models

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	hwpwm "switch-server/internal/hardware-pwm"
	"time"

	"github.com/stianeikeland/go-rpio/v4"
	"golang.org/x/crypto/ssh"
)

var (
	PRIVATE_KEY_PATH = "/home/basraven/.ssh/id_rsa"
	MINIMAL_UPTIME   = time.Minute * 5
)

type DeviceState struct {
	Id        int
	Name      string
	State     int               // 2 = unsure, 1 = on, 0 = off
	GpioIn    rpio.Pin          // GPIO Pin
	GpioOut   rpio.Pin          // GPIO Pin
	StatusLed rpio.Pin          // Status LED
	Pwm       hwpwm.HardwarePWM // PWM Object
	Ssh       string            // ssh server address
	Blocked   *bool             // Pointer to bool to support Nil state
}

type DeviceStateChange struct {
	Timestamp      time.Time
	Id             int
	State          int
	Blocked        *bool
	OutputChannels []*chan DeviceStateChange
	Callback       *chan string
}

type DeviceStates []DeviceState

type DeviceEvents struct {
	State        chan DeviceStateChange
	OutputDevice chan DeviceStateChange
	OutputPwm    chan DeviceStateChange
}

// Constructor function to create a new instance of MyClass
func NewDeviceStates(deviceStateList []DeviceState) (*DeviceStates, *DeviceEvents) {
	deviceStates := DeviceStates(deviceStateList)
	deviceEvents := DeviceEvents{
		State:        make(chan DeviceStateChange),
		OutputDevice: make(chan DeviceStateChange),
		OutputPwm:    make(chan DeviceStateChange),
	}

	go deviceStates.handleDeviceStateEvents(&deviceEvents)
	return &deviceStates, &deviceEvents
}

// Getter method to access the readonly value
func (deviceStates *DeviceStates) GetValue(Id int) *DeviceState {
	return &(*deviceStates)[Id]
}

func (deviceStates *DeviceStates) GetAll() *DeviceStates {
	return deviceStates
}

func (deviceStates *DeviceStates) GetById(Id int) *DeviceState {
	for i := range *deviceStates {
		if (*deviceStates)[i].Id == Id {
			return &(*deviceStates)[i] // Return the address of the element in the slice
		}
	}
	return nil
}

func (deviceStates *DeviceStates) handleDeviceStateEvents(deviceEvents *DeviceEvents) {
	for event := range deviceEvents.State {
		state := deviceStates.GetById(event.Id)

		// log.Printf("\n\t#> %+v \n\t\tupdated:\n\t#> %+v \n", state, event)

		// check if event has blocked update
		if event.Blocked != nil {

			// Update state.Blocked
			state.Blocked = event.Blocked

			*event.Callback <- fmt.Sprintf("Device %d blocked state updated to %t", event.Id, *event.Blocked)
		} else {

			// Check if we're trying to switch off a device
			if event.State != 1 {
				// Check if we're trying to switch off a device that is blocked
				if event.State == 0 && state.Blocked != nil && *state.Blocked {
					*event.Callback <- fmt.Sprintf("Device %d is blocked", state.Id)
					continue
				}

				reachedMinimalUpdate, errUptime := reachedMinimalUptime(state.Ssh, "basraven")
				if errUptime != nil {
					*event.Callback <- fmt.Sprintf("Error checking uptime for device %d: %v", state.Id, errUptime)
					continue
				}
				if !reachedMinimalUpdate {
					*event.Callback <- fmt.Sprintf("Device %d is still starting up", state.Id)
					continue
				}

			}

			state.State = event.State

			// Send event to the appropriate outputchannels
			for _, outputChannel := range event.OutputChannels {
				*outputChannel <- event
			}
		}
	}
}

func reachedMinimalUptime(host string, user string) (bool, error) {
	// Load the private key
	privateKey, err := os.ReadFile(PRIVATE_KEY_PATH)
	if err != nil {
		return false, fmt.Errorf("unable to read private key: %w", err)
	}

	// Create the signer for the private key
	signer, err := ssh.ParsePrivateKey(privateKey)
	if err != nil {
		return false, fmt.Errorf("unable to parse private key: %w", err)
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
		return false, err // Connection failed
	}
	defer conn.Close()

	// Create a new session
	session, err := conn.NewSession()
	if err != nil {
		return false, err // Session creation failed
	}
	defer session.Close()

	// Get uptime from the remote machine
	cmd := "awk '{print $1}' /proc/uptime"
	output, err := session.Output(cmd)
	if err != nil {
		return false, err
	}

	// Parse the uptime
	uptimeSeconds, err := strconv.ParseFloat(strings.TrimSpace(string(output)), 64)
	if err != nil {
		return false, fmt.Errorf("unable to parse uptime: %w", err)
	}

	uptime := time.Duration(uptimeSeconds) * time.Second

	// log.Printf("Uptime: %v, MINIMAL_UPTIME: %v", uptime, MINIMAL_UPTIME)

	// Check if uptime meets the minimal requirement
	if uptime >= MINIMAL_UPTIME {
		return true, nil
	} else {
		remainingTime := MINIMAL_UPTIME - uptime
		return false, fmt.Errorf("need to wait for %s before switching off", remainingTime.Round(time.Second))
	}
}
