package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

var pushgatewayURL = os.Getenv("PUSHGATEWAY_URL")

func main() {
	if pushgatewayURL == "" {
		pushgatewayURL = "http://prometheus-push-gateway:80"
	}

	// Handle /push route
	http.HandleFunc("/push", func(w http.ResponseWriter, r *http.Request) {
		job := r.URL.Query().Get("job")
		metric := r.URL.Query().Get("metric")
		value := r.URL.Query().Get("value")

		if job == "" || metric == "" || value == "" {
			http.Error(w, "Missing job, metric, or value", 400)
			return
		}

		url := fmt.Sprintf("%s/metrics/job/%s", pushgatewayURL, job)
		payload := fmt.Sprintf("%s %s\n", metric, value)

		resp, err := http.Post(url, "text/plain", io.NopCloser(strings.NewReader(payload)))
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to push: %v", err), 500)
			return
		}
		defer resp.Body.Close()
		w.WriteHeader(resp.StatusCode)
		fmt.Fprintf(w, "Pushed %s=%s to job=%s\n", metric, value, job)
	})

	// Handle /lease route
	http.HandleFunc("/lease", func(w http.ResponseWriter, r *http.Request) {
		job := r.URL.Query().Get("job")
		metric := r.URL.Query().Get("metric")
		valueStr := r.URL.Query().Get("value")

		if job == "" {
			http.Error(w, "Missing job parameter", 400)
			return
		}
		if metric == "" {
			http.Error(w, "Missing metric parameter", 400)
			return
		}
		if valueStr == "" {
			http.Error(w, "Missing value parameter", 400)
			return
		}

		value, err := strconv.Atoi(valueStr)
		if err != nil {
			http.Error(w, "Value must be a valid integer", 400)
			return
		}

		// Calculate timestamp: current time + value (in seconds)
		timestamp := time.Now().Add(time.Duration(value) * time.Second).Unix()

		// Push to the push gateway
		url := fmt.Sprintf("%s/metrics/job/%s", pushgatewayURL, job)
		payload := fmt.Sprintf("%s %d\n", metric, timestamp)

		fmt.Printf("Pushing to %s: %s\n", url, payload)

		resp, err := http.Post(url, "text/plain", io.NopCloser(strings.NewReader(payload)))
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to push: %v", err), 500)
			return
		}
		defer resp.Body.Close()

		w.WriteHeader(resp.StatusCode)
		fmt.Fprintf(w, "Pushed %s=%d to job=%s at timestamp=%d (lease duration: %s)\n", metric, timestamp, job, timestamp, time.Duration(value)*time.Second)
	})

	log.Println("Listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
