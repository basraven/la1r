package handlers

import (
	"log"
	"switch-server/internal/models"
)

func HandleDeviceStateEvents(deviceStates *[]models.DeviceStates, deviceStatesEvents <-chan models.DeviceStateEvent) {
	for event := range deviceStatesEvents {
		log.Printf("Received event: %+v", event)
		// Update server state based on the event
		for i, server := range *deviceStates {
			if server.Id == event.Id {
				(*deviceStates)[i].State = event.State
				// log.Printf("Updated server state: %+v", (*deviceStates)[i])
				log.Printf("Led for server %d: %s - Needs to be updated to : %d", server.Id, server.Name, server.State)
			}
		}
	}
}
