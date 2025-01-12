// TODO:
// 1. check for "switch off of server": "backend samba_jayc_be has no server available!"
// 2. check for "switch on of server" : "Server samba_jayc_be/jay-c is UP, reason: Layer4 check passed"
// 3. check for "attempt to access" : ""

package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
	"time"
)

type LogEntry struct {
	Timestamp   string `json:"timestamp"`
	HAProxyHost string `json:"haproxy_host"`
	Frontend    string `json:"frontend"`
	ClientIP    string `json:"client_ip"`
	Backend     string `json:"backend"`
	ConStatus   string `json:"con_status"`
	Server      string `json:"server"`
}

// Variable for last lease request time for a device
var lastLeaseRequestTime time.Time

// GetEnv retrieves the value of an environment variable or returns a default value if not set.
func GetEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

func main() {
	// Set up logging
	log.SetFlags(log.Ldate | log.Ltime | log.Lmicroseconds)

	// Listen on UDP port 44414
	port := ":" + GetEnv("PORT", "44414")
	conn, err := net.ListenPacket("udp", port)
	if err != nil {
		log.Printf("Error starting UDP server: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close()

	log.Printf("Listening for logs on %s\n", port)

	// Buffer to hold incoming log messages
	buffer := make([]byte, 4096)

	// Parse the lease duration from environment variable
	leaseDuration, err := time.ParseDuration(GetEnv("LEASE_TIME", "5m"))
	if err != nil {
		log.Printf("Error parsing duration: %v\n", err)
		return
	}

	// Parse startup time from environment variable
	startupDuration, err := time.ParseDuration(GetEnv("STARTUP_DURATION", "2m"))
	if err != nil {
		log.Printf("Error parsing duration: %v\n", err)
		return
	}

	for {
		// Read log message
		n, _, err := conn.ReadFrom(buffer)
		if err != nil {
			log.Printf("Error reading log message: %v\n", err)
			continue
		}

		logMessage := strings.TrimSpace(string(buffer[:n]))
		// log.Printf("\nReceived log: %s\n", logMessage)

		// Find the JSON portion of the log message
		jsonStart := strings.Index(logMessage, "{")
		if jsonStart == -1 {
			if strings.Contains(logMessage, "Server samba_jayc_be/jay-c is UP") {
				log.Printf("Server samba_jayc_be/jay-c is UP, doing nothing\n")
			} else {
				log.Printf("\n\nNo JSON found and the server is not up. Log message: %s\n", logMessage)
			}
			continue
		}

		jsonLog := logMessage[jsonStart:]
		// log.Printf("\nExtracted JSON: %s\n", jsonLog)

		// Parse JSON log entry
		var entry LogEntry
		err = json.Unmarshal([]byte(jsonLog), &entry)
		if err != nil {
			log.Printf("Error parsing log entry: %v\n", err)
			continue
		}

		// If Server is down and last lease time is longer ago than half of leaseTime in seconds
		if entry.Backend == "samba_jayc_be" && entry.ConStatus == "SC" && time.Since(lastLeaseRequestTime) > startupDuration {
			// log.Printf("Condition met: Backend %s has connection status %s\n", entry.Backend, entry.ConStatus)

			// Send GET request and add lease time to server 3 (Jay-C)
			url := fmt.Sprintf("http://192.168.5.2:50505/api/v1/lease/3/%.0f", leaseDuration.Seconds())
			resp, err := http.Get(url)
			if err != nil {
				log.Printf("Error sending GET request: %v\n", err)
				continue
			}
			lastLeaseRequestTime = time.Now()
			log.Printf("##> Lease request sent to %s, response code: %d\n", url, resp.StatusCode)
			resp.Body.Close()
		} else {
			log.Printf("Half of the lease time did not expire yet, waiting until it expires")
		}

		// If Server is up

	}
}
