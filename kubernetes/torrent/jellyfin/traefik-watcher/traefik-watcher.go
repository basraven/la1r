package main

import (
	"bufio"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

func fetchMetrics(metricURL string, targets []string) (map[string]float64, error) {
	resp, err := http.Get(metricURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	metrics := make(map[string]float64)
	scanner := bufio.NewScanner(resp.Body)

	for scanner.Scan() {
		line := scanner.Text()
		// Check if the line contains any of the targets
		for _, target := range targets {
			if strings.HasPrefix(line, target) {
				// log.Printf("Found target %s in line: %s", target, line)

				// Parse the metric line and extract values
				parts := strings.Split(line, "} ")
				if len(parts) == 2 {
					val, parseErr := parseFloat(parts[1])
					if parseErr == nil {
						// Sum to metrics[target] if already exists, otherwise create it
						if _, exists := metrics[target]; exists {
							metrics[target] += val
						} else {
							metrics[target] = val
						}
					}
				}
			}
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return metrics, nil
}

func parseFloat(s string) (float64, error) {
	var val float64
	_, err := fmt.Sscanf(s, "%f", &val)
	if err != nil {
		return 0, err
	}
	return val, nil
}

func main() {
	// Set up logging
	// log.SetOutput(os.Stdout) // Ensure logs are written to stdout
	log.SetFlags(log.Ldate | log.Ltime | log.Lmicroseconds)

	// Parse required environment variables
	metricTarget, exists := os.LookupEnv("METRIC_TARGET_STRING")
	if !exists {
		log.Panicf("METRIC_TARGET environment variable is not set")
		return
	}

	metricUrl, exists := os.LookupEnv("METRIC_URL")
	if !exists {
		log.Panicf("METRIC_TARGET environment variable is not set")
		return
	}

	requestUrl, exists := os.LookupEnv("REQUEST_URL")
	if !exists {
		log.Panicf("REQUEST_URL environment variable is not set")
		return
	}

	// Parse the lease duration from environment variable
	requestPauseString, exists := os.LookupEnv("METRIC_REQUEST_PAUSE")
	if !exists {
		log.Panicf("METRIC_REQUEST_PAUSE environment variable is not set")
		return
	}
	requestPause, err := time.ParseDuration(requestPauseString)
	if err != nil {
		log.Printf("Error parsing duration: %v\n", err)
		return
	}

	previousCumulative := 0.0

	for {
		// log.Println("Fetching metrics...")

		targets := []string{
			metricTarget,
		}

		metrics, err := fetchMetrics(metricUrl, targets)
		if err != nil {
			fmt.Println("Error fetching metrics:", err)
			// Sleep for requestPause duration before retrying
			time.Sleep(requestPause)
			continue
		}

		for _, target := range targets {
			metric, exists := metrics[target]
			if exists {
				if metric != previousCumulative {
					// log.Printf("Updated metric value for %s: %.0f\n", target, metric)

					// Send a GET request to the request URL
					resp, err := http.Get(requestUrl)
					if err != nil {
						log.Printf("Target found but error sending GET request: %v\n", err)
					} else {
						log.Printf("Target found and request successful, response status: %s\n", resp.Status)
						previousCumulative = metric
					}
				} else {
					log.Printf("Metric %s is the same as previous, skipping request\n", target)
				}

			} else {
				log.Printf("Metric %s not found\n", target)
			}
		}
		// Sleep for requestPause duration before retrying
		time.Sleep(requestPause)
	}
}
