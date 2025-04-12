package v1

import (
	"github.com/gin-gonic/gin"

	httphandlers "switch-server/http/v1/handlers"
	middlewares "switch-server/http/v1/middleware"
	"switch-server/internal/models"
)

func SetupRoutes(r *gin.RouterGroup, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	// r.Use(middleware.Auth())
	r.Use(middlewares.NoCache())

	// Route handles & endpoints for deviceStates
	r.GET("/status", func(c *gin.Context) {
		httphandlers.HandleAllStatusRequest(c, deviceStates)
	})
	r.GET("/status/:identifier", func(c *gin.Context) {
		httphandlers.HandleSpecificStatusRequest(c, deviceStates)
	})
	r.GET("/start/:identifier", func(c *gin.Context) {
		httphandlers.HandleDeviceToggleRequest(c, deviceStates, deviceEvents, 1, false)
	})
	r.GET("/stop/:identifier", func(c *gin.Context) {
		httphandlers.HandleDeviceToggleRequest(c, deviceStates, deviceEvents, 0, false)
	})
	r.GET("/start/:identifier/force", func(c *gin.Context) {
		httphandlers.HandleDeviceToggleRequest(c, deviceStates, deviceEvents, 1, true)
	})
	r.GET("/stop/:identifier/force", func(c *gin.Context) {
		httphandlers.HandleDeviceToggleRequest(c, deviceStates, deviceEvents, 0, true)
	})
	r.GET("/set/:identifier/:value", func(c *gin.Context) {
		httphandlers.HandleSetRequest(c, deviceStates, deviceEvents, false)
	})
	r.GET("/set/:identifier/:value/force", func(c *gin.Context) {
		httphandlers.HandleSetRequest(c, deviceStates, deviceEvents, true)
	})
	r.GET("/block/:identifier", func(c *gin.Context) {
		httphandlers.HandleBlockRequest(c, deviceStates, deviceEvents, true)
	})
	r.GET("/unblock/:identifier", func(c *gin.Context) {
		httphandlers.HandleBlockRequest(c, deviceStates, deviceEvents, false)
	})
	r.GET("/lease/:identifier/:secondsToAdd", func(c *gin.Context) {
		httphandlers.HandleLeaseRequest(c, deviceStates, deviceEvents)
	})
	r.POST("/prometheus/alertmanager", func(c *gin.Context) {
		httphandlers.HandleAlertManagerRequest(c, deviceStates, deviceEvents)
	})

}
