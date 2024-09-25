package handlers

import (
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"switch-server/internal/models"
)

func HandleAllStatusRequest(c *gin.Context, deviceStates *models.DeviceStates) {
	c.JSON(200, deviceStates)
}

func HandleSpecificStatusRequest(c *gin.Context, deviceStates *models.DeviceStates) {
	identifier := c.Param("identifier")

	// Try to parse the identifier as an integer (ID)
	if id, err := strconv.Atoi(identifier); err == nil {
		for _, state := range *deviceStates {
			if state.Id == id {
				c.JSON(200, state)
				return
			}
		}
	} else {
		// If not an integer, treat it as a name
		for _, state := range *deviceStates {
			if strings.EqualFold(state.Name, identifier) {
				c.JSON(200, state)
				return
			}
		}
	}

	c.JSON(404, gin.H{"error": "Server state not found"})
}

func HandleStartRequest(c *gin.Context, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	identifier := c.Param("identifier")
	// Try to parse the identifier as an integer (ID)
	if id, err := strconv.Atoi(identifier); err == nil {
		for _, state := range *deviceStates {
			if state.Id == id {
				performWithCallback(c, state, 1, deviceEvents, []*chan models.DeviceStateChange{
					&deviceEvents.OutputDevice,
				})
				return
			}
		}
	} else {
		// If not an integer, treat it as a name
		for _, state := range *deviceStates {
			if strings.EqualFold(state.Name, identifier) {
				performWithCallback(c, state, 1, deviceEvents, []*chan models.DeviceStateChange{
					&deviceEvents.OutputDevice,
				})
				return
			}
		}
	}
	c.JSON(404, gin.H{"message": "Server not found"})
}

func HandleStopRequest(c *gin.Context, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	identifier := c.Param("identifier")
	// Try to parse the identifier as an integer (ID)
	if id, err := strconv.Atoi(identifier); err == nil {
		for _, state := range *deviceStates {
			if state.Id == id {
				performWithCallback(c, state, 0, deviceEvents, []*chan models.DeviceStateChange{
					&deviceEvents.OutputDevice,
				})
				return
			}
		}
	} else {
		// If not an integer, treat it as a name
		for _, state := range *deviceStates {
			if strings.EqualFold(state.Name, identifier) {
				performWithCallback(c, state, 0, deviceEvents, []*chan models.DeviceStateChange{
					&deviceEvents.OutputDevice,
				})
				return
			}
		}
	}
	c.JSON(404, gin.H{"message": "Server not found"})
}

func HandleSetRequest(c *gin.Context, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	identifier := c.Param("identifier")
	value := c.Param("value")
	// Try to parse the identifier as an integer (ID)
	if id, err := strconv.Atoi(identifier); err == nil {
		for _, state := range *deviceStates {
			if state.Id == id {
				if setValue, err := strconv.Atoi(value); err == nil {
					performWithCallback(c, state, setValue, deviceEvents, []*chan models.DeviceStateChange{
						&deviceEvents.OutputPwm,
					})
					return
				} else {
					c.JSON(400, gin.H{"message": "Invalid value of " + value})
					return
				}
			}
		}
	} else {
		// If not an integer, treat it as a name
		for _, state := range *deviceStates {
			if strings.EqualFold(state.Name, identifier) {
				if setValue, err := strconv.Atoi(value); err == nil {
					performWithCallback(c, state, setValue, deviceEvents, []*chan models.DeviceStateChange{
						&deviceEvents.OutputPwm,
					})
					return
				} else {
					c.JSON(400, gin.H{"message": "Invalid value of " + value})
					return
				}
			}
		}
	}
}

func performWithCallback(c *gin.Context, state models.DeviceState, setValue int, deviceEvents *models.DeviceEvents, OutputChannels []*chan models.DeviceStateChange) {
	callback := make(chan string)
	changeEvent := models.DeviceStateChange{
		Timestamp:      time.Now(),
		Id:             state.Id,
		State:          setValue,
		OutputChannels: OutputChannels,
		Callback:       &callback,
	}
	deviceEvents.State <- changeEvent
	callbackValue, ok := <-callback
	if ok {
		c.JSON(200, gin.H{"message": callbackValue})
	} else {
		c.JSON(500, gin.H{"message": "Process errored out"})
	}
	close(callback)
}
