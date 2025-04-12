package handlers

import (
	"fmt"
	"log"
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
	// Check if queryParam update=false was set, to lowercase
	toUpdateBoolean := strings.ToLower(c.Query("update")) != "false"

	// loop through deviceStates and get state.ssh, then use isHostAvailable to check if it's available
	actuals := make(map[string]string)
	if !toUpdateBoolean {
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
	}

	updatedDeviceStates := *deviceStates
	if toUpdateBoolean {
		// Loop all device status and check if it's available, otherwise update the state
		for _, state := range updatedDeviceStates {

			// updatedDeviceStates = make([]models.DeviceState, 0)

			available, err := handlers.IsHostAvailable(state.Ssh, (5 * time.Second))
			if err != nil {
				// Handle the error if needed
			} else {
				if available {
					state.State = 1
				} else {
					state.State = 0
				}
			}
			// updatedDeviceStates = append(updatedDeviceStates, state)
		}
	}

	c.JSON(200, gin.H{
		"actuals": actuals,
		"state":   updatedDeviceStates,
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

type AlertManagerRequest struct {
	Receiver string `json:"receiver"`
	Status   string `json:"status"`
	Alerts   []struct {
		Status string `json:"status"`
		Labels struct {
			AlertName string `json:"alertname"`
			Severity  string `json:"severity"`
		} `json:"labels"`
		Annotations struct {
			Description string `json:"description"`
			Summary     string `json:"summary"`
		} `json:"annotations"`
		StartsAt     string `json:"startsAt"`
		EndsAt       string `json:"endsAt"`
		GeneratorURL string `json:"generatorURL"`
		Fingerprint  string `json:"fingerprint"`
	} `json:"alerts"`
	GroupLabels struct {
		AlertName string `json:"alertname"`
	} `json:"groupLabels"`
	CommonLabels struct {
		AlertName string `json:"alertname"`
		Severity  string `json:"severity"`
	} `json:"commonLabels"`
	CommonAnnotations struct {
		Description string `json:"description"`
		Summary     string `json:"summary"`
	} `json:"commonAnnotations"`
	ExternalURL     string `json:"externalURL"`
	Version         string `json:"version"`
	GroupKey        string `json:"groupKey"`
	TruncatedAlerts int    `json:"truncatedAlerts"`
}

func HandleAlertManagerRequest(c *gin.Context, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	var alertManagerRequest AlertManagerRequest

	if err := c.ShouldBindJSON(&alertManagerRequest); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	log.Printf("alertManagerRequest.Status: %s", alertManagerRequest.Status)

	var newStateValue int
	var identifier string = "3"

	if alertManagerRequest.Status == "firing" { // Server should be turned on
		newStateValue = 1
	} else if alertManagerRequest.Status == "resolved" { // Server should be turned off
		newStateValue = 0
	} else {
		log.Printf("Invalid status: %s", alertManagerRequest.Status)
		c.JSON(400, gin.H{"error": "Invalid status"})
		return
	}

	state := findDeviceState(deviceStates, identifier)
	if state == nil {
		c.JSON(404, gin.H{"message": "Server not found"})
		return
	}

	performDeviceStateChangeWithCallback(c, *state, newStateValue, deviceEvents, []*chan models.DeviceStateChange{
		&deviceEvents.OutputDevice,
	})

	c.JSON(200, gin.H{"message": "Alert received successfully"})
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
