package v1

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"

	httphandlers "switch-server/http/v1/handlers"
	"switch-server/internal/models"
	// "switch-server/http/v1/middleware"
)

// HandleRequest is a basic HTTP handler for the API.
func HandleRequest(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello from API v1")
}

func SetupRoutes(r *gin.RouterGroup, deviceStates *models.DeviceStates, deviceStatesEvents chan models.DeviceState) {
	// r.Use(middleware.Auth())

	// Route handles & endpoints for deviceStates
	r.GET("/status", func(c *gin.Context) {
		httphandlers.HandleAllStatusRequest(c, deviceStates)
	})
	r.GET("/status/:identifier", func(c *gin.Context) {
		httphandlers.HandleSpecificStatusRequest(c, deviceStates)
	})
	r.GET("/start/:identifier", func(c *gin.Context) {
		httphandlers.HandleStartRequest(c, deviceStates, deviceStatesEvents)
	})
	r.GET("/stop/:identifier", func(c *gin.Context) {
		httphandlers.HandleStopRequest(c, deviceStates, deviceStatesEvents)
	})
	// Add more routes as needed
}
