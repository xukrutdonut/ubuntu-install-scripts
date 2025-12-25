# Raspberry Pi Power Consumption Analysis - Penta SATA HAT Setup

## 🔌 Current Setup Problem
- **Device**: Raspberry Pi con Penta SATA HAT en 192.168.0.193
- **Issue**: Se cae continuamente con nuevo hub USB-C
- **Hub**: Cargador USB-C múltiple 660W, 8 puertos, GAN PD 100W
- **Planned**: 3x RPi 5 + 4x RPi 3B con Penta SATA HATs

## 📊 Power Requirements Analysis

### **Raspberry Pi 5 (x3 units)**
| Component | Power Draw | Notes |
|-----------|------------|-------|
| RPi 5 Base | 5V @ 3A (15W) | Under full load |
| Penta SATA HAT | 12V @ 2A (24W) | 5 drives spinning |
| **Total per RPi 5** | **~39W** | Maximum consumption |
| **3x RPi 5 Total** | **117W** | Peak load |

### **Raspberry Pi 3B+ (x4 units)**
| Component | Power Draw | Notes |
|-----------|------------|-------|
| RPi 3B+ Base | 5V @ 2.5A (12.5W) | Under full load |
| Penta SATA HAT | 12V @ 2A (24W) | 5 drives spinning |
| **Total per RPi 3B+** | **~36.5W** | Maximum consumption |
| **4x RPi 3B+ Total** | **146W** | Peak load |

## ⚡ Total Power Requirements

### **Peak Consumption**
```
3x RPi 5 + Penta SATA:     117W
4x RPi 3B+ + Penta SATA:   146W
Overhead (10%):             26W
--------------------------------
TOTAL PEAK:                289W
```

### **Typical Operating Consumption (70% of peak)**
```
Typical Operating Load:    202W
Safety Margin (20%):        40W
--------------------------------
RECOMMENDED CAPACITY:      242W
```

## 🔍 Current Problem Diagnosis

### **Potential Issues with 192.168.0.193**

1. **Insufficient USB-C PD Negotiation**
   - Hub may not provide enough power to single port
   - USB-C PD negotiation failing
   - Power sharing between ports reducing available power

2. **Penta SATA HAT Power Issues**
   - Requires stable 12V power
   - High current draw during drive spin-up
   - Power spikes when multiple drives access simultaneously

3. **Hub Power Distribution**
   - 660W total ÷ 8 ports = 82.5W average per port
   - May not guarantee 100W to single port continuously
   - Power balancing algorithm may limit individual ports

## 🛠️ Recommended Solutions

### **Immediate Fixes**

1. **Check USB-C Cable Quality**
   ```bash
   # Use USB-C cable rated for 100W (5A)
   # Verify cable supports USB PD 3.0
   # Check for loose connections
   ```

2. **Power Supply Verification**
   ```bash
   # SSH to RPi and check:
   vcgencmd measure_volts     # Should show ~5.1V
   vcgencmd get_throttled     # Should show 0x0 (no throttling)
   dmesg | grep -i voltage    # Check for voltage warnings
   ```

3. **Hub Configuration**
   - Connect RPi to dedicated high-power port
   - Avoid using adjacent ports simultaneously
   - Check hub firmware updates

### **Long-term Setup Optimization**

#### **Power Port Assignment Strategy**
```
Port 1: RPi 5 #1 + Penta SATA (39W)
Port 2: RPi 5 #2 + Penta SATA (39W)  
Port 3: RPi 5 #3 + Penta SATA (39W)
Port 4: RPi 3B+ #1 + Penta SATA (36.5W)
Port 5: RPi 3B+ #2 + Penta SATA (36.5W)
Port 6: RPi 3B+ #3 + Penta SATA (36.5W)
Port 7: RPi 3B+ #4 + Penta SATA (36.5W)
Port 8: Spare/Low power devices
```

#### **Staggered Startup Sequence**
1. Power up RPi units one by one (30s intervals)
2. Prevent simultaneous drive spin-up
3. Monitor power consumption during startup

## 🔧 Troubleshooting Commands

### **Power Monitoring (run on each RPi)**
```bash
# Voltage monitoring
watch -n 1 'vcgencmd measure_volts'

# Throttling detection  
watch -n 1 'vcgencmd get_throttled'

# Temperature monitoring
watch -n 1 'vcgencmd measure_temp'

# USB power configuration
vcgencmd get_config usb_max_current_enable

# System power consumption
sudo cat /sys/class/thermal/thermal_zone0/temp
```

### **SATA Drive Power Analysis**
```bash
# Check connected drives
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Drive power states
sudo hdparm -C /dev/sd[a-e]

# Drive spin down (power saving)
sudo hdparm -S 60 /dev/sd[a-e]  # Spin down after 5 minutes
```

## 🚨 Critical Warnings

### **Hub Compatibility Issues**
- **Problem**: Multi-port USB-C hubs often can't deliver full 100W to all ports simultaneously
- **Reality**: 660W ÷ 8 = 82.5W average, but power balancing reduces individual port capability
- **Solution**: Verify hub actually delivers 100W per port under load

### **Penta SATA HAT Requirements**
- **Critical**: Requires very stable power during drive operations
- **Spin-up Current**: 5 drives can draw 50W+ during startup
- **Data Operations**: Sustained high current during simultaneous R/W

### **Cable Quality Critical**
- **USB-C Cable Rating**: Must support 5A (100W)
- **Length**: Shorter cables (< 1m) for high power
- **Connector Quality**: Poor connectors cause voltage drop

## 📈 Monitoring Setup

### **Power Monitoring Script**
```bash
#!/bin/bash
# Save as power_monitor.sh
while true; do
    echo "$(date): Voltage=$(vcgencmd measure_volts), Throttled=$(vcgencmd get_throttled), Temp=$(vcgencmd measure_temp)"
    sleep 10
done | tee power_monitor.log
```

### **Automated Alerts**
```bash
# Add to crontab for voltage monitoring
*/5 * * * * /usr/bin/vcgencmd measure_volts | awk '{if($1<5.0) system("echo Low voltage detected | mail admin@domain.com")}'
```

## 🎯 Success Metrics

### **Stable Operation Indicators**
- ✅ Voltage consistently above 5.0V
- ✅ get_throttled returns 0x0
- ✅ Temperature below 70°C
- ✅ No voltage warnings in dmesg
- ✅ All SATA drives accessible
- ✅ No random shutdowns/reboots

### **Performance Benchmarks**
```bash
# Test SATA performance
sudo hdparm -tT /dev/sd[a-e]

# CPU stress test with power monitoring
stress --cpu 4 --timeout 60s &
watch vcgencmd measure_volts
```

---
**Created**: December 16, 2024
**Target**: Raspberry Pi cluster with Penta SATA HATs
**Status**: Diagnostic and optimization guide