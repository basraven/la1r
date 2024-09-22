// package handlers

// import (
// 	"log"
// 	"switch-server/internal/models"
// )

// func HandleDeviceStateEvents(deviceStates *models.DeviceStates, deviceStatesEvents <-chan models.DeviceState) {
// 	for event := range deviceStatesEvents {
// 		log.Printf("Received event: %+v", event)
// 		// Update server state based on the event
// 		for i, state := range *deviceStates {
// 			if state.Id == event.Id {
// 				(*deviceStates)[i].State = event.State
// 				log.Printf("DeviceId %d: %s - Needs state updated to : %d", state.Id, state.Name, state.State)
// 			}
// 		}
// 	}
// }
