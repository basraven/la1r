package v1

import (
	"github.com/gin-gonic/gin"

	httphandlers "switch-server/http/v1/handlers"
	"switch-server/internal/models"
	// "switch-server/http/v1/middleware"
)

func SetupRoutes(r *gin.RouterGroup, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	// r.Use(middleware.Auth())

	// Route handles & endpoints for deviceStates
	r.GET("/status", func(c *gin.Context) {
		httphandlers.HandleAllStatusRequest(c, deviceStates)
	})
	r.GET("/status/:identifier", func(c *gin.Context) {
		httphandlers.HandleSpecificStatusRequest(c, deviceStates)
	})
	r.GET("/start/:identifier", func(c *gin.Context) {
		httphandlers.HandleStartRequest(c, deviceStates, deviceEvents)
	})
	r.GET("/stop/:identifier", func(c *gin.Context) {
		httphandlers.HandleStopRequest(c, deviceStates, deviceEvents)
	})
	r.GET("/set/:identifier/:value", func(c *gin.Context) {
		httphandlers.HandleSetRequest(c, deviceStates, deviceEvents)
	})

}
