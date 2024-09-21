package handlers

import (
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"switch-server/internal/models"
)

func HandleAllStatusRequest(c *gin.Context, deviceStates *[]models.DeviceStates) {
	c.JSON(200, deviceStates)
}

func HandleSpecificStatusRequest(c *gin.Context, deviceStates *[]models.DeviceStates) {
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

func HandleStartRequest(c *gin.Context, deviceStates *[]models.DeviceStates, deviceStatesEvents chan<- models.DeviceStateEvent) {
	identifier := c.Param("identifier")
	// Try to parse the identifier as an integer (ID)
	if id, err := strconv.Atoi(identifier); err == nil {
		for _, state := range *deviceStates {
			if state.Id == id {
				deviceStatesEvents <- models.DeviceStateEvent{Id: id, State: 1}
				c.JSON(200, gin.H{"message": "Server started"})
				return
			}
		}
	} else {
		// If not an integer, treat it as a name
		for _, state := range *deviceStates {
			if strings.EqualFold(state.Name, identifier) {
				deviceStatesEvents <- models.DeviceStateEvent{Id: state.Id, State: 1}
				c.JSON(200, gin.H{"message": "Server started"})
				return
			}
		}
	}
	c.JSON(404, gin.H{"message": "Server not found"})
}

func HandleStopRequest(c *gin.Context, deviceStates *[]models.DeviceStates, deviceStatesEvents chan<- models.DeviceStateEvent) {
	identifier := c.Param("identifier")
	// Try to parse the identifier as an integer (ID)
	if id, err := strconv.Atoi(identifier); err == nil {
		for _, state := range *deviceStates {
			if state.Id == id {
				deviceStatesEvents <- models.DeviceStateEvent{Id: id, State: 0}
				c.JSON(200, gin.H{"message": "Server stopped"})
				return
			}
		}
	} else {
		// If not an integer, treat it as a name
		for _, state := range *deviceStates {
			if strings.EqualFold(state.Name, identifier) {
				deviceStatesEvents <- models.DeviceStateEvent{Id: state.Id, State: 0}
				c.JSON(200, gin.H{"message": "Server stopped"})
				return
			}
		}
	}
	c.JSON(404, gin.H{"message": "Server not found"})
}
