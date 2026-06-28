package handlers

import (
	"fmt"
	hwpwm "switch-server/internal/hardware-pwm"
	"switch-server/internal/models"
)

func OutputPWMOnEvent(deviceStates *models.DeviceStates, deviceEvents *models.DeviceEvents) {
	for event := range deviceEvents.OutputPwm {
		state := deviceStates.GetById(event.Id)
		// Set the PWM channel to the new state
		handlePwmChange(&state.Pwm, &event)

	}
}
func handlePwmChange(pwm *hwpwm.HardwarePWM, event *models.DeviceStateChange) {
	pwmValue := event.State
	if pwmValue > 100 {
		*event.Callback <- "Invalid pwm value"
	}
	if pwm.DutyCycle == float64(0) {
		pwm.Start(float64(pwmValue))
		*event.Callback <- fmt.Sprintf("PWM started with value %d", pwmValue)
	} else if pwm.DutyCycle > float64(0) && pwmValue == 0 {
		pwm.Stop()
		*event.Callback <- "PWM stopped"
	} else {
		pwm.ChangeDutyCycle(float64(pwmValue))
		*event.Callback <- fmt.Sprintf("PWM changed to %d", pwmValue)
	}
}
