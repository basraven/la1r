package middleware

import (
	"github.com/gin-gonic/gin"
)

// NoCache is the middleware function that checks if the user is authenticated
func NoCache() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Add headers to disable caching
		c.Header("Cache-Control", "no-store, no-cache, must-revalidate, private")
		c.Header("Pragma", "no-cache")
		c.Header("Expires", "0")

		// Continue to the next middleware or handler
		c.Next()
	}
}
