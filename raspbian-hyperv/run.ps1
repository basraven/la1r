if (!(Test-Path .\VMs\base\raspbian.iso)) {
    Write-Warning "No base ISO found, downloading iso..."
    wget https://downloads.raspberrypi.org/rpd_x86_latest -OutFile .\VMs\base\raspbian.iso
}
Stop-VM -Force -Name raspi*
Remove-VM -Force -Name raspi*
New-VM -Name raspi1 -MemoryStartupBytes 1GB -BootDevice "VHD" -Generation 1 -SwitchName "Pi Switch"
New-VM -Name raspi2 -MemoryStartupBytes 1GB -BootDevice "VHD" -Generation 1 -SwitchName "Pi Switch"
Set-VMDvdDrive -VMName "raspi1" -Path 'VMs\base\raspbian.iso'
Set-VMDvdDrive -VMName "raspi2" -Path 'VMs\base\raspbian.iso'
start-vm raspi* 