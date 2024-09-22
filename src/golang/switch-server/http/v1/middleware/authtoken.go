package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Auth is the middleware function that checks if the user is authenticated
func Auth() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Extract the token from the request header (e.g., Authorization header)
		token := c.GetHeader("Authorization")

		if token == "" {
			// If no token is present, abort the request and return a 401 Unauthorized
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Unauthorized: No token provided",
			})
			c.Abort() // Stop further processing
			return
		}

		// Normally, you would validate the token here (e.g., check if it's a JWT)
		if token != "valid-token" { // Replace with real validation logic
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Unauthorized: Invalid token",
			})
			c.Abort()
			return
		}

		// If the token is valid, proceed to the next handler
		c.Next()
	}
}
