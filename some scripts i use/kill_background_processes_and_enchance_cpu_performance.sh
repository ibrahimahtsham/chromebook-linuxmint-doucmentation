#!/bin/bash

# ===============================
# 🧹 Kill unnecessary background daemons
# ===============================

# Tracker file indexers (used for desktop search in GNOME)
killall -q -9 tracker-miner-fs tracker-store

# Ubuntu update notifier
killall -q -9 update-notifier

# GNOME calendar/mail service
killall -q -9 evolution-calendar-factory

# Zeitgeist event logger
killall -q -9 zeitgeist-datahub

# GNOME Software Center
killall -q -9 gnome-software

# Snap store background service
killall -q -9 snap-store

# Mobile broadband manager
killall -q -9 modemmanager

# Sensor proxy (gyroscope, light sensor)
killall -q -9 iio-sensor-proxy

# Network printing browser
killall -q -9 cups-browsed

# Kernel crash reporter
killall -q -9 kerneloops

# GPU switching daemon
killall -q -9 switcheroo-control

# Power profile daemon (we'll override it anyway)
killall -q -9 power-profiles-daemon

# ===============================
# 🌿 Cinnamon-only daemons
# ===============================
killall -q -9 csd-housekeeping csd-wacom csd-clipboard csd-a11y-settings \
               csd-keyboard csd-print-notifications csd-media-keys csd-screensaver-proxy

# ===============================
# 🧠 KDE background services
# ===============================
killall -q -9 krunner discover

# ===============================
# 🚀 MAXIMIZE CPU PERFORMANCE
# ===============================

# Ensure performance governor is set (requires root or sudo)
if [[ $EUID -ne 0 ]]; then
  echo "⚠️ Please run this script with sudo to apply CPU performance settings."
else
  echo "⚙️  Setting CPU scaling governor to 'performance'..."
  for CPUFREQ_GOV in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance > "$CPUFREQ_GOV"
  done

  echo "📈 Setting power profile to performance (if supported)..."
  powerprofilesctl set performance 2>/dev/null || echo "⚠️  powerprofilesctl not available or not supported"

  echo "🔒 Disabling Intel P-state powersave mode (if available)..."
  echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
  echo 1 > /sys/devices/system/cpu/intel_pstate/performance 2>/dev/null || true

  echo "🧠 CPU now running at maximum performance settings."
fi

echo "✅ Unnecessary processes terminated. CPU is now set to peak performance mode."
