package models

type DeviceStates struct {
	Id    int
	Name  string
	State int // 2 = unsure, 1 = on, 0 = off
	GPIO  int // GPIO Pin
}

type DeviceStateEvent struct {
	Id    int
	State int // 2 = unsure, 1 = on, 0 = off
}
