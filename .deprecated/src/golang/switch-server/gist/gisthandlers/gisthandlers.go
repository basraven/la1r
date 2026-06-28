package gisthandlers

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"switch-server/internal/models"
	"time"

	"golang.org/x/exp/rand"
)

const gistURL = "https://gist.githubusercontent.com/basraven/c15ceea3944b19448506650346b25dff/raw/forcecontrol"
const metadataFile = "last-forcecontrol-state.json"

// ForceStateData structure to hold the last modified time
type ForceStateData struct {
	LastContent map[string]interface{} `json:"last_content"`
}

func fetchGist() (map[string]interface{}, error) {
	randomParam := rand.Int63() // Use a random int
	urlWithQuery := fmt.Sprintf("%s?q=%d", gistURL, randomParam)

	req, err := http.NewRequest("GET", urlWithQuery, nil)
	if err != nil {
		return nil, err
	}

	// Log the request URL
	log.Printf("Requesting URL: %s\n", urlWithQuery)

	// Set headers to prevent caching
	req.Header.Set("Cache-Control", "no-cache")
	req.Header.Set("Pragma", "no-cache")

	resp, err := http.DefaultClient.Do(req) // Use the request with the headers
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var data map[string]interface{}
	if err := json.Unmarshal(body, &data); err != nil {
		return nil, err
	}

	// log.Printf("ETag was %s\n", resp.Header.Get("ETag"))

	return data, nil
}

func checkValues(data map[string]interface{}, deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	for key, value := range data {

		if strings.EqualFold(key, "salt") {
			continue // skipping salt
		}

		if shouldBeActive, ok := value.(bool); ok {
			state := getStateOnName(deviceStates, key)

			if state == nil {
				log.Printf("State %s not found\n", key)
				continue
			}
			if shouldBeActive && (state.State == 0 || state.State == 2) {
				// log.Printf("%s should be started\n", key)
				targetState := 1
				performWithCallback(state.Id, deviceEvents, targetState)
			} else if !shouldBeActive && state.State == 1 {
				// log.Printf("%s should be stopped\n", key)
				targetState := 0
				performWithCallback(state.Id, deviceEvents, targetState)
				// } else {
				// 	log.Printf("%s has state %d and shouldBeActive %t, no action needed \n", key, state.State, shouldBeActive)
			}
		} else {
			log.Printf("%s not found in states\n", key)
		}
	}
}

func getStateOnName(deviceStates *models.DeviceStates, name string) *models.DeviceState {
	for _, state := range *deviceStates {
		if strings.EqualFold(state.Name, name) {
			return &state
		}
	}
	return nil
}

func loadStatedata() (ForceStateData, error) {
	var metadata ForceStateData
	file, err := os.Open(metadataFile)
	if err != nil {
		if os.IsNotExist(err) {
			return ForceStateData{}, nil // If file does not exist, return zero value
		}
		return ForceStateData{}, err
	}
	defer file.Close()

	if err := json.NewDecoder(file).Decode(&metadata); err != nil {
		return ForceStateData{}, err
	}

	return metadata, nil
}

func saveStatedata(metadata ForceStateData) error {
	file, err := os.Create(metadataFile)
	if err != nil {
		return err
	}
	defer file.Close()

	return json.NewEncoder(file).Encode(metadata)
}

// compareJSON compares two JSON maps and returns true if they are the same, false otherwise
func compareJSON(a, b map[string]interface{}) bool {
	aJSON, err := json.Marshal(a)
	if err != nil {
		return false
	}

	bJSON, err := json.Marshal(b)
	if err != nil {
		return false
	}
	// printing the JSON strings for debugging
	// log.Println("aJSON:", string(aJSON))
	// log.Println("bJSON:", string(bJSON))

	return string(aJSON) == string(bJSON)
}

func performWithCallback(stateId int, deviceEvents *models.DeviceEvents, targetStateInt int) {
	callback := make(chan string)
	changeEvent := models.DeviceStateChange{
		Timestamp: time.Now(),
		Id:        stateId,
		State:     targetStateInt,
		OutputChannels: []*chan models.DeviceStateChange{
			&deviceEvents.OutputDevice,
		},
		Callback: &callback,
	}
	deviceEvents.State <- changeEvent

	callbackValue, ok := <-callback
	if ok {
		log.Printf("Gist switch changed device with %s", callbackValue)
	} else {
		log.Printf("Gist switch ERROR, did not change device state")
	}
	close(callback)
}

func WatchGistChanges(deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	stateData, err := loadStatedata()
	if err != nil {
		log.Println("Error loading metadata:", err)
		return
	}
	ticker := time.NewTicker(2 * time.Minute)
	defer ticker.Stop()

	for {
		// Fetch the gist content
		gistContent, err := fetchGist()
		if err != nil {
			log.Println("Error fetching Gist:", err)
			continue
		}

		if stateData.LastContent == nil || !compareJSON(stateData.LastContent, gistContent) {
			// log.Println("Gist has changed, checking values...")

			// Check the boolean values in the new content
			checkValues(gistContent, deviceStates, deviceEvents)

			// Update the metadata with the latest information
			stateData = ForceStateData{
				LastContent: gistContent,
			}
			if err := saveStatedata(stateData); err != nil {
				log.Println("Error saving metadata:", err)
			}
			// } else {
			// 	log.Println("No changes detected.")
		}

		// Wait for the next tick
		<-ticker.C
	}
}
