package handlers

import (
	"log"
	"switch-server/internal/models"
	"time"

	"github.com/stianeikeland/go-rpio/v4"
)

func ReadForSwitchToggle(inputPins *[]rpio.Pin, deviceStates *[]models.DeviceStates, deviceStatesEvents chan<- models.DeviceStateEvent) {
	for _, pin := range *inputPins {
		pin.Input()
		pin.PullUp()
	}
	for {
		for _, pin := range *inputPins {
			pinValue := int(pin.Read())

			deviceStates := findDeviceStates(deviceStates, int(pin))

			// log.Printf("Pin %d reads value: %d", pin, pinValue)
			// log.Printf("deviceStates for pin %d is %d", pin, deviceStates.State)

			if deviceStates.State != pinValue {
				log.Printf("deviceStates server %d for pin %d will update from %d to %d", deviceStates.Id, pin, deviceStates.State, pinValue)
				deviceStatesEvents <- models.DeviceStateEvent{Id: deviceStates.Id, State: pinValue}
				deviceStates.State = pinValue
			}
			// else {
			// 	log.Printf("deviceStates server %d for pin %d no update from %d to %d", deviceStates.Id, pin, deviceStates.State, pinValue)
			// }
		}
		time.Sleep(1000 * time.Millisecond)
	}
}

func findDeviceStates(deviceStates *[]models.DeviceStates, pinNumber int) *models.DeviceStates {
	for _, state := range *deviceStates {
		if state.GPIO == pinNumber {
			return &state
		}
	}
	return nil
}
