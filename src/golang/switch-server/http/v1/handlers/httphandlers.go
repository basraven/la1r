package handlers

import (
	"fmt"
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
	state := findDeviceState(deviceStates, identifier)
	if state == nil {
		c.JSON(404, gin.H{"message": "Server not found"})
		return
	}

	performDeviceStateChangeWithCallback(c, *state, 1, deviceEvents, []*chan models.DeviceStateChange{
		&deviceEvents.OutputDevice,
	})
}

func HandleStopRequest(c *gin.Context, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	identifier := c.Param("identifier")
	state := findDeviceState(deviceStates, identifier)
	if state == nil {
		c.JSON(404, gin.H{"message": "Server not found"})
		return
	}

	performDeviceStateChangeWithCallback(c, *state, 0, deviceEvents, []*chan models.DeviceStateChange{
		&deviceEvents.OutputDevice,
	})
}

func HandleSetRequest(c *gin.Context, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	identifier := c.Param("identifier")
	value := c.Param("value")
	state := findDeviceState(deviceStates, identifier)
	if state == nil {
		c.JSON(404, gin.H{"message": "Server not found"})
		return
	}

	if newStateValue, err := strconv.Atoi(value); err == nil {
		performDeviceStateChangeWithCallback(c, *state, newStateValue, deviceEvents, []*chan models.DeviceStateChange{
			&deviceEvents.OutputPwm,
		})
	} else {
		c.JSON(400, gin.H{"message": "Invalid value of " + value})
	}
}

// Helper function to find a device state by identifier (ID or name)
func findDeviceState(deviceStates *models.DeviceStates, identifier string) *models.DeviceState {
	if id, err := strconv.Atoi(identifier); err == nil {
		for _, state := range *deviceStates {
			if state.Id == id {
				return &state
			}
		}
	} else {
		for _, state := range *deviceStates {
			if strings.EqualFold(state.Name, identifier) {
				return &state
			}
		}
	}
	return nil
}
func HandleBlockRequest(c *gin.Context, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	identifier := c.Param("identifier")
	// Try to parse the identifier as an integer (ID)
	if id, err := strconv.Atoi(identifier); err == nil {
		for _, state := range *deviceStates {
			if state.Id == id {
				performDeviceBlockChangeWithCallback(c, state, true, deviceEvents, []*chan models.DeviceStateChange{
					&deviceEvents.OutputDevice,
				})
				return
			}
		}
	} else {
		// If not an integer, treat it as a name
		for _, state := range *deviceStates {
			if strings.EqualFold(state.Name, identifier) {
				performDeviceBlockChangeWithCallback(c, state, true, deviceEvents, []*chan models.DeviceStateChange{
					&deviceEvents.OutputDevice,
				})
				return
			}
		}
	}
	c.JSON(404, gin.H{"message": "Server not found"})
}

func HandleUnblockRequest(c *gin.Context, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	identifier := c.Param("identifier")
	// Try to parse the identifier as an integer (ID)
	if id, err := strconv.Atoi(identifier); err == nil {
		for _, state := range *deviceStates {
			if state.Id == id {
				performDeviceBlockChangeWithCallback(c, state, false, deviceEvents, []*chan models.DeviceStateChange{
					&deviceEvents.OutputDevice,
				})
				return
			}
		}
	} else {
		// If not an integer, treat it as a name
		for _, state := range *deviceStates {
			if strings.EqualFold(state.Name, identifier) {
				performDeviceBlockChangeWithCallback(c, state, false, deviceEvents, []*chan models.DeviceStateChange{
					&deviceEvents.OutputDevice,
				})
				return
			}
		}
	}
	c.JSON(404, gin.H{"message": "Server not found"})
}

const cooldownPeriod = 60 * time.Second

func performDeviceStateChangeWithCallback(c *gin.Context, state models.DeviceState, newStateValue int, deviceEvents *models.DeviceEvents, OutputChannels []*chan models.DeviceStateChange) {
	if time.Since(state.LastActionTime) < cooldownPeriod {
		remainingTime := cooldownPeriod - time.Since(state.LastActionTime)
		c.JSON(429, gin.H{"message": fmt.Sprintf("Too many requests, please wait for %.2f seconds remaining", remainingTime.Seconds())})
		return
	}

	callback := make(chan string)
	changeEvent := models.DeviceStateChange{
		Timestamp:      time.Now(),
		Id:             state.Id,
		State:          newStateValue,
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
func performDeviceBlockChangeWithCallback(c *gin.Context, state models.DeviceState, newBlockValue bool, deviceEvents *models.DeviceEvents, OutputChannels []*chan models.DeviceStateChange) {
	callback := make(chan string)
	changeEvent := models.DeviceStateChange{
		Timestamp:      time.Now(),
		Id:             state.Id,
		Blocked:        &newBlockValue,
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
