package hwpwm

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
)

type HardwarePWMException struct {
	message string
}

func (e *HardwarePWMException) Error() string {
	return e.message
}

type HardwarePWM struct {
	dutyCycle  float64
	hz         float64
	chipPath   string
	pwmDir     string
	pwmChannel int
}

func NewHardwarePWM(pwmChannel int, hz float64, chip int) (*HardwarePWM, error) {
	if pwmChannel < 0 || pwmChannel > 3 {
		return nil, &HardwarePWMException{"Only channel 0, 1, 2, and 3 are available on the Rpi."}
	}

	h := &HardwarePWM{
		chipPath:   fmt.Sprintf("/sys/class/pwm/pwmchip%d", chip),
		pwmChannel: pwmChannel,
		hz:         hz,
	}
	h.pwmDir = filepath.Join(h.chipPath, fmt.Sprintf("pwm%d", pwmChannel))

	if !h.isOverlayLoaded() {
		return nil, &HardwarePWMException{"Need to add 'dtoverlay=pwm-2chan' to /boot/config.txt and reboot"}
	}
	if !h.isExportWritable() {
		return nil, &HardwarePWMException{fmt.Sprintf("Need write access to files in '%s'", h.chipPath)}
	}
	if !h.doesPWMExist() {
		err := h.createPWM()
		if err != nil {
			return nil, err
		}
	}

	for {
		err := h.changeFrequency(hz)
		if err == nil {
			break
		} else if os.IsPermission(err) {
			continue
		} else {
			return nil, err
		}
	}

	return h, nil
}

func (h *HardwarePWM) isOverlayLoaded() bool {
	_, err := os.Stat(h.chipPath)
	return !os.IsNotExist(err)
}

func (h *HardwarePWM) isExportWritable() bool {
	exportPath := filepath.Join(h.chipPath, "export")
	return isWritable(exportPath)
}

func (h *HardwarePWM) doesPWMExist() bool {
	_, err := os.Stat(h.pwmDir)
	return !os.IsNotExist(err)
}

func (h *HardwarePWM) echo(message int, filePath string) error {
	file, err := os.OpenFile(filePath, os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = file.WriteString(fmt.Sprintf("%d\n", message))
	return err
}

func (h *HardwarePWM) createPWM() error {
	return h.echo(h.pwmChannel, filepath.Join(h.chipPath, "export"))
}

func (h *HardwarePWM) Start(initialDutyCycle float64) error {
	err := h.ChangeDutyCycle(initialDutyCycle)
	if err != nil {
		return err
	}
	return h.echo(1, filepath.Join(h.pwmDir, "enable"))
}

func (h *HardwarePWM) Stop() error {
	err := h.ChangeDutyCycle(0)
	if err != nil {
		return err
	}
	return h.echo(0, filepath.Join(h.pwmDir, "enable"))
}

func (h *HardwarePWM) ChangeDutyCycle(dutyCycle float64) error {
	if dutyCycle < 0 || dutyCycle > 100 {
		return &HardwarePWMException{"Duty cycle must be between 0 and 100 (inclusive)."}
	}
	h.dutyCycle = dutyCycle

	period, err := h.getPeriod()
	if err != nil {
		return err
	}

	dc := int(float64(period) * dutyCycle / 100)
	return h.echo(dc, filepath.Join(h.pwmDir, "duty_cycle"))
}

func (h *HardwarePWM) changeFrequency(hz float64) error {
	if hz < 0.1 {
		return &HardwarePWMException{"Frequency can't be lower than 0.1 on the Rpi."}
	}
	h.hz = hz

	originalDutyCycle := h.dutyCycle
	if h.dutyCycle != 0 {
		err := h.ChangeDutyCycle(0)
		if err != nil {
			return err
		}
	}

	period := int(1.0 / hz * 1000000000)
	err := h.echo(period, filepath.Join(h.pwmDir, "period"))
	if err != nil {
		return err
	}

	return h.ChangeDutyCycle(originalDutyCycle)
}

func (h *HardwarePWM) getPeriod() (int, error) {
	periodFile := filepath.Join(h.pwmDir, "period")
	data, err := os.ReadFile(periodFile)
	if err != nil {
		return 0, err
	}

	// Trim any newline characters from the string
	trimmedData := string(data)
	trimmedData = trimmedData[:len(trimmedData)-1]

	return strconv.Atoi(trimmedData)
}

func isWritable(filePath string) bool {
	file, err := os.OpenFile(filePath, os.O_WRONLY, 0644)
	if err != nil {
		return false
	}
	file.Close()
	return true
}

// func main() {
// 	hwPWM, err := NewHardwarePWM(0, 60, 0)
// 	if err != nil {
// 		fmt.Println("Error:", err)
// 		return
// 	}

// 	log.Println("starting with 100")
// 	err = hwPWM.start(100)
// 	if err != nil {
// 		fmt.Println("Error starting PWM:", err)
// 		return
// 	}

// 	time.Sleep(20 * time.Second)

// 	log.Println("starting with 50 duty")
// 	err = hwPWM.changeDutyCycle(50)
// 	if err != nil {
// 		fmt.Println("Error changing duty cycle:", err)
// 		return
// 	}

// 	time.Sleep(20 * time.Second)

// 	// log.Println("starting with 50 frequency")
// 	// err = hwPWM.changeFrequency(50)
// 	// if err != nil {
// 	// 	fmt.Println("Error changing frequency:", err)
// 	// 	return
// 	// }

// 	// time.Sleep(10 * time.Second)

// 	err = hwPWM.stop()
// 	if err != nil {
// 		fmt.Println("Error stopping PWM:", err)
// 		return
// 	}
// }
