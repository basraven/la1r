package v1

import (
	"fmt"
	"net/http"
)

// HandleRequest is a basic HTTP handler for the API.
func HandleRequest(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello from API v1")
}
