#!/bin/bash

# Raspberry Pi Power Monitoring Script
# Target: 192.168.0.193 with Penta SATA HAT

RPI_IP="192.168.0.193"
LOG_FILE="/home/arkantu/rpi_power_$(date +%Y%m%d).log"

echo "=== RPi Power Analysis Started $(date) ===" | tee -a $LOG_FILE

# Function to run command on RPi
run_on_rpi() {
    timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no pi@$RPI_IP "$1" 2>/dev/null
}

# Check if RPi is reachable
if ping -c 1 -W 2 $RPI_IP > /dev/null 2>&1; then
    echo "✅ RPi $RPI_IP is reachable" | tee -a $LOG_FILE
    
    # Get system info
    echo "📊 Hardware Info:" | tee -a $LOG_FILE
    run_on_rpi "cat /proc/cpuinfo | grep -E 'Model|Hardware|Revision'" | tee -a $LOG_FILE
    
    echo "⚡ Power Status:" | tee -a $LOG_FILE
    
    # Voltage measurement
    VOLTAGE=$(run_on_rpi "vcgencmd measure_volts" | grep -o '[0-9.]*V')
    echo "Voltage: $VOLTAGE" | tee -a $LOG_FILE
    
    # Throttling status
    THROTTLED=$(run_on_rpi "vcgencmd get_throttled")
    echo "Throttling: $THROTTLED" | tee -a $LOG_FILE
    
    # Temperature
    TEMP=$(run_on_rpi "vcgencmd measure_temp" | grep -o '[0-9.]*')
    echo "Temperature: ${TEMP}°C" | tee -a $LOG_FILE
    
    # USB power config
    USB_POWER=$(run_on_rpi "vcgencmd get_config usb_max_current_enable")
    echo "USB Max Current: $USB_POWER" | tee -a $LOG_FILE
    
    # Check for voltage warnings
    echo "🚨 System Warnings:" | tee -a $LOG_FILE
    run_on_rpi "dmesg | grep -i -E 'voltage|power|throttle' | tail -5" | tee -a $LOG_FILE
    
    # SATA drives status
    echo "💾 SATA Drives:" | tee -a $LOG_FILE
    run_on_rpi "lsblk | grep sd" | tee -a $LOG_FILE
    
    # Power analysis
    if [[ "$VOLTAGE" =~ ([0-9.]+) ]]; then
        VOLT_NUM=${BASH_REMATCH[1]}
        if (( $(echo "$VOLT_NUM < 5.0" | bc -l) )); then
            echo "⚠️  WARNING: Low voltage detected ($VOLTAGE)" | tee -a $LOG_FILE
        fi
    fi
    
    if [[ "$THROTTLED" != *"0x0"* ]] && [[ -n "$THROTTLED" ]]; then
        echo "⚠️  WARNING: Throttling detected ($THROTTLED)" | tee -a $LOG_FILE
    fi
    
else
    echo "❌ RPi $RPI_IP is not reachable - possibly powered off!" | tee -a $LOG_FILE
fi

echo "=== Analysis completed $(date) ===" | tee -a $LOG_FILE
echo
