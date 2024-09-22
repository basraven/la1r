package models

import (
	"log"

	"github.com/stianeikeland/go-rpio/v4"
)

type DeviceState struct {
	Id         int
	Name       string
	State      int      // 2 = unsure, 1 = on, 0 = off
	GpioIn     rpio.Pin // GPIO Pin
	PwmChannel int      // PWM Channel
}

// Private method to set the value (unexported)
func (deviceState *DeviceState) setValue(value DeviceState) {
	*deviceState = value
}

type DeviceStates []DeviceState

// Constructor function to create a new instance of MyClass
func NewDeviceStates(deviceStateList []DeviceState) *DeviceStates {
	deviceStates := DeviceStates(deviceStateList)
	return &deviceStates
}

// Getter method to access the readonly value
func (deviceStates *DeviceStates) GetValue(Id int) *DeviceState {
	return &(*deviceStates)[Id]
}

func (deviceStates *DeviceStates) GetAll() *DeviceStates {
	return deviceStates
}

func (deviceStates *DeviceStates) HandleDeviceStateEvents(deviceStatesEvents <-chan DeviceState) {
	for event := range deviceStatesEvents {
		// Update server state based on the event
		for i := range *deviceStates {
			if (*deviceStates)[i].Id == event.Id {
				log.Printf("Device %d with state %+v to update to: %+v", i, (*deviceStates)[i], event)
				(*deviceStates)[i] = event
			}
		}
	}
}
