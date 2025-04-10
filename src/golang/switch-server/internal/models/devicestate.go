package models

import (
	"context"
	"fmt"
	"log"
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
	MINIMAL_UPTIME   = time.Minute * 1 // Minimum of 1 minute uptime
)

type Gpio struct {
	In        rpio.Pin // GPIO Pin
	Out       rpio.Pin // GPIO Pin
	StatusLed rpio.Pin // Status LED
}
type DeviceState struct {
	Id      int
	Name    string
	State   int // 2 = unsure, 1 = on, 0 = off TODO: remove state 2
	Gpio    Gpio
	Pwm     hwpwm.HardwarePWM // PWM Object
	Ssh     string            // ssh server address
	Blocked *bool             // Pointer to bool to support Nil state
	Lease   struct {
		CloseTime  time.Time // Time when the lease is closed
		CancelFunc *func()   `json:"-"` // Function to call when to cancel lease close. Fiels is ignored in serrialization
	}
}
type DeviceStateChange struct {
	Timestamp      time.Time
	Id             int
	State          int
	OutputChannels []*chan DeviceStateChange
	Callback       *chan string
}
type DeviceBlockedChange struct {
	Timestamp      time.Time
	Id             int
	Blocked        *bool
	OutputChannels []*chan DeviceStateChange
	Callback       *chan string
}

type DeviceLeaseChange struct {
	Timestamp      time.Time
	Id             int
	SecondsToAdd   int // The amount of seconds to add or subtract to the lease time
	OutputChannels []*chan DeviceStateChange
	Callback       *chan string
}

type DeviceStates []DeviceState

type DeviceEvents struct {
	State        chan DeviceStateChange
	Blocked      chan DeviceBlockedChange
	Leased       chan DeviceLeaseChange
	OutputDevice chan DeviceStateChange
	OutputPwm    chan DeviceStateChange
}

// Constructor function to create a new instance of MyClass
func NewDeviceStates(deviceStateList []DeviceState) (*DeviceStates, *DeviceEvents) {
	deviceStates := DeviceStates(deviceStateList)
	deviceEvents := DeviceEvents{
		State:        make(chan DeviceStateChange),
		Blocked:      make(chan DeviceBlockedChange),
		Leased:       make(chan DeviceLeaseChange),
		OutputDevice: make(chan DeviceStateChange),
		OutputPwm:    make(chan DeviceStateChange),
	}

	go deviceStates.handleDeviceStateEvents(&deviceEvents)
	go deviceStates.handleDeviceBlockedEvents(&deviceEvents)
	go deviceStates.handleDeviceLeasedEvents(&deviceEvents)
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

		// Check if we're trying to switch off a device
		if event.State == 0 {
			// Check if we're trying to switch off a device that is blocked
			if state.Blocked != nil && *state.Blocked {
				*event.Callback <- fmt.Sprintf("Device %d is blocked", state.Id)
				continue
			}

			// Check if lease time is not zero
			if !state.Lease.CloseTime.IsZero() {
				// Check if we're trying to switch off a device that still has a lease that is before the current time
				if state.Lease.CloseTime.After(time.Now()) {
					*event.Callback <- fmt.Sprintf("Device %d is still leased for %.0f seconds and cannot be switched off", state.Id, time.Until(state.Lease.CloseTime).Seconds())
					continue
				} else {
					// Lease time is expired, so we can set it to zero
					state.Lease.CloseTime = time.Time{}
				}

			}

			reachedMinimalUpdate, errUptime := reachedMinimalUptime(state.Ssh)
			if errUptime != nil {
				*event.Callback <- fmt.Sprintf("Device down, error checking uptime for device %d: %v", state.Id, errUptime)
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

func (deviceStates *DeviceStates) handleDeviceBlockedEvents(deviceEvents *DeviceEvents) {
	for event := range deviceEvents.Blocked {
		state := deviceStates.GetById(event.Id)

		// Update state.Blocked
		state.Blocked = event.Blocked
		*event.Callback <- fmt.Sprintf("Device %d blocked state updated to %t", event.Id, *event.Blocked)
	}
}

func (deviceStates *DeviceStates) handleDeviceLeasedEvents(deviceEvents *DeviceEvents) {
	for event := range deviceEvents.Leased {
		state := deviceStates.GetById(event.Id)

		oldLeaseCloseTime := state.Lease.CloseTime
		if state.Lease.CloseTime.IsZero() {
			state.Lease.CloseTime = time.Now().Add(time.Second * time.Duration(event.SecondsToAdd))
		} else {
			log.Printf("Canceling the last lease stopper")
			if state.Lease.CancelFunc != nil {
				(*state.Lease.CancelFunc)()
			} else {
				log.Printf("No cancel function found for device %d", state.Id)
			}
			state.Lease.CloseTime = state.Lease.CloseTime.Add(time.Second * time.Duration(event.SecondsToAdd))
		}

		callback := make(chan string)
		// run a goroutine to close the device after the lease time has passed
		ctx, cancel := context.WithCancel(context.Background())
		go handleDeviceLeaseExpired(ctx, state.Lease.CloseTime, func() {
			log.Printf("Lease expired for device state, switching off device %d", state.Id)
			changeEvent := DeviceStateChange{
				Timestamp: time.Now(),
				Id:        state.Id,
				State:     0,
				OutputChannels: []*chan DeviceStateChange{
					&deviceEvents.OutputDevice,
				},
				Callback: &callback,
			}
			deviceEvents.State <- changeEvent
			callbackValue, ok := <-callback
			if ok {
				log.Printf("ACK Switch off because of expired lease %s ", callbackValue)
			} else {
				log.Printf("ERROR in Switch off because of expired lease %s ", callbackValue)
			}
			close(callback)

		})
		cancelFunc := func() { cancel() }
		state.Lease.CancelFunc = &cancelFunc

		// If the device is off, we need to send a state change event to turn the device on
		if state.State == 0 {
			changeEvent := DeviceStateChange{
				Timestamp: time.Now(),
				Id:        state.Id,
				State:     1,
				OutputChannels: []*chan DeviceStateChange{
					&deviceEvents.OutputDevice,
				},
			}
			deviceEvents.State <- changeEvent

			*event.Callback <- fmt.Sprintf("Device started and %d lease updated from %s to %s, adding %d seconds", event.Id, oldLeaseCloseTime.Format(time.RFC3339), state.Lease.CloseTime.Format(time.RFC3339), event.SecondsToAdd)
		} else { // Device is already on
			*event.Callback <- fmt.Sprintf("Device %d lease updated from %s to %s, adding %d seconds", event.Id, oldLeaseCloseTime.Format(time.RFC3339), state.Lease.CloseTime.Format(time.RFC3339), event.SecondsToAdd)
		}
	}
}
func handleDeviceLeaseExpired(ctx context.Context, startTime time.Time, task func()) {
	// Calculate the delay until the start time
	delay := time.Until(startTime)
	if delay <= 0 {
		task() // Start time is in the past, starting immediately
		return
	}

	// Create a timer for the delay
	timer := time.NewTimer(delay)

	select {
	case <-ctx.Done():
		// If the context is canceled, stop the timer and return
		log.Printf("Lease planned stop refreshed")
		timer.Stop()
	case <-timer.C:
		// Timer triggered, execute the task
		task()
	}
}

// TODO: Relocate to GPIO function
func reachedMinimalUptime(host string) (bool, error) {
	user := "basraven"

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
