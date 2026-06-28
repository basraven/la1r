package main

import (
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
	"time"
)

// K8sDeployment represents the fields we care about from a Kubernetes Deployment
type K8sDeployment struct {
	Metadata struct {
		Labels map[string]string `json:"labels"`
	} `json:"metadata"`
	Spec struct {
		Replicas int32 `json:"replicas"`
	} `json:"spec"`
	Status struct {
		Conditions []struct {
			Type   string `json:"type"`
			Status string `json:"status"`
			Reason string `json:"reason"`
		} `json:"conditions"`
	} `json:"status"`
}

// HealthResponse is returned by the /health endpoint
type HealthResponse struct {
	Status  string `json:"status"`
	Reason  string `json:"reason"`
	Details string `json:"details,omitempty"`
}

var (
	k8sAPIServer = "https://kubernetes.default.svc"
	k8sToken     string
	httpClient   *http.Client
)

func main() {
	// Read the service account token
	tokenBytes, err := os.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/token")
	if err != nil {
		log.Fatalf("Failed to read service account token: %v", err)
	}
	k8sToken = strings.TrimSpace(string(tokenBytes))

	// Read the CA cert for the K8s API server
	caCert, err := os.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
	if err != nil {
		log.Fatalf("Failed to read CA certificate: %v", err)
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	// HTTP client that trusts the K8s API CA and has a short timeout for health checks
	httpClient = &http.Client{
		Timeout: 10 * time.Second,
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{
				RootCAs: caCertPool,
			},
			DialContext: (&net.Dialer{
				Timeout: 5 * time.Second,
			}).DialContext,
		},
	}

	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
		w.Write([]byte("ok"))
	})

	log.Println("sablier-proxy listening on :9090")
	log.Fatal(http.ListenAndServe(":9090", nil))
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	deployment := r.URL.Query().Get("deployment")
	namespace := r.URL.Query().Get("namespace")
	checkURL := r.URL.Query().Get("check-url")

	if deployment == "" || namespace == "" || checkURL == "" {
		writeJSON(w, 400, HealthResponse{
			Status: "error",
			Reason: "missing-params",
			Details: "deployment, namespace, and check-url are required",
		})
		return
	}

	log.Printf("GET /health deployment=%s namespace=%s check-url=%s", deployment, namespace, checkURL)

	// Step 1: Try to reach the service directly
	if serviceReachable(checkURL) {
		writeJSON(w, 200, HealthResponse{
			Status: "healthy",
			Reason: "service-reachable",
		})
		return
	}

	log.Printf("service unreachable for %s/%s, checking deployment state", namespace, deployment)

	// Step 2: Service not reachable — check if deployment is intentionally at 0 replicas
	isSleeping, reason, details := checkIfIntentionallySleeping(namespace, deployment)
	if isSleeping {
		writeJSON(w, 200, HealthResponse{
			Status:  "healthy",
			Reason:  reason,
			Details: details,
		})
		return
	}

	// Step 3: Genuinely broken
	writeJSON(w, 503, HealthResponse{
		Status:  "unhealthy",
		Reason:  "service-unreachable",
		Details: details,
	})
}

// serviceReachable checks if a URL is reachable (HTTP or TCP)
func serviceReachable(rawURL string) bool {
	if strings.HasPrefix(rawURL, "tcp://") {
		return tcpReachable(strings.TrimPrefix(rawURL, "tcp://"))
	}

	// HTTP/HTTPS check
	req, err := http.NewRequest("GET", rawURL, nil)
	if err != nil {
		return false
	}
	resp, err := httpClient.Do(req)
	if err != nil {
		return false
	}
	defer resp.Body.Close()
	return resp.StatusCode >= 200 && resp.StatusCode < 400
}

// tcpReachable checks if a TCP connection can be established
func tcpReachable(address string) bool {
	conn, err := net.DialTimeout("tcp", address, 5*time.Second)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}

// checkIfIntentionallySleeping returns true if the deployment is expected to be down.
// A deployment at 0 replicas is considered "intentionally sleeping" if:
//   1. It has sablier.enable=true (Sablier scaled it to 0), OR
//   2. It is NOT crashing (no MinimumReplicasUnavailable condition)
// This covers both Sablier-managed AND manually-disabled deployments.
func checkIfIntentionallySleeping(namespace, deployment string) (bool, string, string) {
	url := fmt.Sprintf(
		"%s/apis/apps/v1/namespaces/%s/deployments/%s",
		k8sAPIServer, namespace, deployment,
	)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return false, "k8s-api-error", fmt.Sprintf("request failed: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+k8sToken)

	resp, err := httpClient.Do(req)
	if err != nil {
		return false, "k8s-api-error", fmt.Sprintf("API call failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return false, "k8s-api-error", fmt.Sprintf("API returned %d: %s", resp.StatusCode, string(body))
	}

	var dep K8sDeployment
	if err := json.NewDecoder(resp.Body).Decode(&dep); err != nil {
		return false, "k8s-api-error", fmt.Sprintf("decode failed: %v", err)
	}

	isSablier := dep.Metadata.Labels["sablier.enable"] == "true"
	replicas := dep.Spec.Replicas

	// If service would be reachable at >0 replicas, it's just sleeping
	if replicas > 0 {
		return false, "running-but-unreachable",
			fmt.Sprintf("deployment %s/%s has %d replicas but service is not reachable", namespace, deployment, replicas)
	}

	// Replicas is 0 — check if this is intentional or a crash
	isIntentionallySleeping, reason := isDeploymentIntentionallyAtZero(dep)
	if isIntentionallySleeping {
		label := "manually-disabled"
		if isSablier {
			label = "sablier-sleeping"
		}
		return true, label,
			fmt.Sprintf("deployment %s/%s: replicas=0, %s", namespace, deployment, reason)
	}

	return false, "deployment-crashing",
		fmt.Sprintf("deployment %s/%s: replicas=0, appears to be crashing (%s)", namespace, deployment, reason)
}

// isDeploymentIntentionallyAtZero checks deployment conditions to distinguish
// "intentionally scaled to 0" from "crashed/rolling out and failing".
func isDeploymentIntentionallyAtZero(dep K8sDeployment) (bool, string) {
	var availableStatus, availableReason string
	var progressingStatus, progressingReason string

	for _, c := range dep.Status.Conditions {
		switch c.Type {
		case "Available":
			availableStatus = c.Status
			availableReason = c.Reason
		case "Progressing":
			progressingStatus = c.Status
			progressingReason = c.Reason
		}
	}

	// If Available=True, deployment was intentionally scaled to 0 (K8s considers
	// 0 replicas with the right ReplicaSet as "available" when no minReplicas is set)
	if availableStatus == "True" {
		return true, fmt.Sprintf("Available=%s (%s)", availableStatus, availableReason)
	}

	// If Progressing=True with NewReplicaSetAvailable, the deployment settled at 0
	if progressingStatus == "True" && progressingReason == "NewReplicaSetAvailable" {
		return true, fmt.Sprintf("Progressing=%s (%s)", progressingStatus, progressingReason)
	}

	// If Available=False with MinimumReplicasUnavailable, the deployment crashed
	if availableStatus == "False" && availableReason == "MinimumReplicasUnavailable" {
		return false, fmt.Sprintf("Available=%s (%s)", availableStatus, availableReason)
	}

	// Fallback: if no crash indicators, assume intentional
	return true, "no-crash-conditions-detected"
}

func writeJSON(w http.ResponseWriter, status int, v interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}
