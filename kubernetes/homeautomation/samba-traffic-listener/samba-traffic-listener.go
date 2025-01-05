package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
)

// Simulated response handler for the server
func handleSambaRequest(w http.ResponseWriter, r *http.Request) {
	// Return a message, simulating a response akin to a Samba server.
	fmt.Fprintf(w, "The server is being started...")

	// Trigger the parallel API call
	go callAPI()
}

// Simulate a separate API call to another endpoint
func callAPI() {
	serverId := os.Getenv("SERVER_ID")
	if serverId == "" {
		serverId = "3"
	}

	leaseDuration := os.Getenv("LEASE_DURATION")
	if leaseDuration == "" {
		leaseDuration = "300"
	}

	// Make an HTTP request to the API endpoint
	apiURL := fmt.Sprintf("http://192.168.5.2:50505/api/v1/lease/%s/%s", serverId, leaseDuration)
	// Creating a new request
	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		log.Println("Failed to create request:", err)
		return
	}

	// Send the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Println("Failed to call the API:", err)
		return
	}
	defer resp.Body.Close()

	// Reading the response body
	body, err := io.ReadAll(resp.Body) // Using io.ReadAll instead of ioutil.ReadAll
	if err != nil {
		log.Println("Failed to read the API response:", err)
		return
	}

	log.Println("API call completed successfully, response:", string(body))
}

func main() {
	// Register the handler for the "Samba" ports
	http.HandleFunc("/", handleSambaRequest)

	// Launch the HTTP server for both Samba ports 139 and 445
	go func() {
		log.Println("Starting server on port (44)139...")
		if err := http.ListenAndServe(":44139", nil); err != nil {
			log.Fatal("Error starting server on port 139: ", err)
		}
	}()

	go func() {
		log.Println("Starting server on port (44)445...")
		if err := http.ListenAndServe(":44445", nil); err != nil {
			log.Fatal("Error starting server on port 445: ", err)
		}
	}()

	// Simulating the behavior of a Samba service
	select {} // Block forever, keeping the server running
}
