package handlers

import (
	"log"
	"switch-server/internal/models"
	"time"
)

func ReadForGpioInChange(deviceStates *models.DeviceStates, deviceStatesEvents chan<- models.DeviceState) {
	for _, state := range *deviceStates {
		if state.GpioIn != 0 {
			state.GpioIn.Input()
			state.GpioIn.PullUp()
		}
	}
	for {
		for _, state := range *deviceStates {
			if state.GpioIn != 0 {
				pinValue := int(state.GpioIn.Read())

				// Check if deviceStates has changed
				if state.State != pinValue {
					log.Printf("deviceStates server %d for pin %d will update from %d to %d", state.Id, state.GpioIn, state.State, pinValue)
					state.State = pinValue
					deviceStatesEvents <- state
				}
				// else {
				// 	log.Printf("deviceStates server %d for pin %d no update from %d to %d", deviceStates.Id, pin, deviceStates.State, pinValue)
				// }
			}
		}
		time.Sleep(1000 * time.Millisecond)
	}
}
