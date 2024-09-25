package models

import (
	hwpwm "switch-server/internal/hardware-pwm"
	"time"

	"github.com/stianeikeland/go-rpio/v4"
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
}

type DeviceStateChange struct {
	Timestamp      time.Time
	Id             int
	State          int
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

		state.State = event.State

		// Send event to the appropriate outputchannels
		for _, outputChannel := range event.OutputChannels {
			*outputChannel <- event
		}

	}
}
