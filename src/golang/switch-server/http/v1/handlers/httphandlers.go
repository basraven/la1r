package handlers

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	handlers "switch-server/gpio/gpiohandlers"
	"switch-server/internal/models"
)

var (
	requestSpamProtection = make(map[string]time.Time)
)

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

func HandleAllStatusRequest(c *gin.Context, deviceStates *models.DeviceStates) {
	// loop through deviceStates and get state.ssh, then use isHostAvailable to check if it's available
	actuals := make(map[string]string)
	for _, state := range *deviceStates {
		available, err := handlers.IsHostAvailable(state.Ssh, (5 * time.Second))
		if err != nil {
			// Handle the error if needed
			// actuals[state.Name] = "Error: " + err.Error()
			actuals[state.Name] = "Unavailable"
		} else {
			if available {
				actuals[state.Name] = "Available"
			} else {
				actuals[state.Name] = "Unavailable"
			}
		}
	}

	c.JSON(200, gin.H{
		"actuals": actuals,
		"state":   deviceStates,
		"spam":    requestSpamProtection,
	})
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

const cooldownPeriod = 60 * time.Second // 1 minute cooldown period

func isRequestSpam(c *gin.Context, force bool) bool {
	// Check if the request is a spam
	if lastActionTime, exists := requestSpamProtection[c.ClientIP()]; exists && !force {
		if time.Since(lastActionTime) < cooldownPeriod {
			c.JSON(429, gin.H{"message": fmt.Sprintf("Too many requests, please wait for %.2f seconds remaining", (cooldownPeriod - time.Since(lastActionTime)).Seconds())})
			return true
		}
	}
	requestSpamProtection[c.ClientIP()] = time.Now()
	return false
}

func HandleDeviceToggleRequest(c *gin.Context, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents, newStateValue int, force bool) {
	if isRequestSpam(c, force) {
		return
	}
	identifier := c.Param("identifier")
	state := findDeviceState(deviceStates, identifier)
	if state == nil {
		c.JSON(404, gin.H{"message": "Server not found"})
		return
	}

	performDeviceStateChangeWithCallback(c, *state, newStateValue, deviceEvents, []*chan models.DeviceStateChange{
		&deviceEvents.OutputDevice,
	})
}

func HandleSetRequest(c *gin.Context, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents, force bool) {
	if isRequestSpam(c, force) {
		return
	}
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

func HandleBlockRequest(c *gin.Context, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents, block bool) {
	identifier := c.Param("identifier")
	state := findDeviceState(deviceStates, identifier)
	if state != nil {
		performDeviceBlockChangeWithCallback(c, *state, block, deviceEvents)
		return
	}
	c.JSON(404, gin.H{"message": "Server not found"})
}

func HandleLeaseRequest(c *gin.Context, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	identifier := c.Param("identifier")
	state := findDeviceState(deviceStates, identifier)
	stringSecondsToAdd := c.Param("secondsToAdd")
	secondsToAdd, err := strconv.Atoi(stringSecondsToAdd)
	if state != nil && err == nil {
		performDeviceLeaseChangeWithCallback(c, *state, secondsToAdd, deviceEvents)
		return
	}
	c.JSON(404, gin.H{"message": "Server not found"})
}

func performDeviceStateChangeWithCallback(c *gin.Context, state models.DeviceState, newStateValue int, deviceEvents *models.DeviceEvents, OutputChannels []*chan models.DeviceStateChange) {

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

func performDeviceBlockChangeWithCallback(c *gin.Context, state models.DeviceState, newBlockValue bool, deviceEvents *models.DeviceEvents) {
	callback := make(chan string)
	changeEvent := models.DeviceBlockedChange{
		Timestamp: time.Now(),
		Id:        state.Id,
		Blocked:   &newBlockValue,
		Callback:  &callback,
	}
	deviceEvents.Blocked <- changeEvent
	callbackValue, ok := <-callback
	if ok {
		c.JSON(200, gin.H{"message": callbackValue})
	} else {
		c.JSON(500, gin.H{"message": "Process errored out"})
	}
	close(callback)
}

func performDeviceLeaseChangeWithCallback(c *gin.Context, state models.DeviceState, secondsToAdd int, deviceEvents *models.DeviceEvents) {
	callback := make(chan string)
	changeEvent := models.DeviceLeaseChange{
		Timestamp:    time.Now(),
		Id:           state.Id,
		SecondsToAdd: secondsToAdd,
		Callback:     &callback,
	}
	deviceEvents.Leased <- changeEvent
	callbackValue, ok := <-callback
	if ok {
		c.JSON(200, gin.H{"message": callbackValue})
	} else {
		c.JSON(500, gin.H{"message": "Process errored out"})
	}
	close(callback)
}
