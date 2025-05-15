# Converting My Chromebook to Linux Mint Cinnamon

This guide documents my journey converting a **Lenovo 300e Chromebook 2nd Gen** into a Linux Mint Cinnamon machine. It records all the steps I took, the commands I ran, and the challenges I encountered along the way. Notably, the entire process was performed using software—no screw removal or hardware modifications were required. A USB drive was used to boot the installer (and an external keyboard was only needed in early troubleshooting) before making Linux Mint the default OS.

---

## Hardware and System Specifications

- **Device:** Lenovo 300e Chromebook 2nd Gen
- **Disk Space:** 32 GB
- **RAM:** 4 GB
- **CPU:** Intel Celeron N4000 @ 1.10 GHz (2 threads, up to 2.60 GHz)

---

## Initial Setup

1. **Entering Developer Mode:**

   - Booted into Developer Mode (OS Verification OFF) by pressing `Ctrl+D` at startup.
   - Confirmed that OS Verification was disabled.

2. **Accessing the Developer Console:**
   - Rebooted into the recovery menu by pressing `Esc`, `Refresh`, then the `Power` button.
   - Noticed an option:  
     `"Press a numeric key to select an alternative boot loader" (2: TianoCore bootloader)`.
   - _Issue:_ Initially, pressing 2 and Enter did not work.

---

## Preparing the USB Drive

1. **Mounting and Identifying the USB:**

   - Inserted a USB drive. It originally showed as `/dev/sdb1`, but for writing the ISO the entire device `/dev/sdb` is used.
   - USB mount point: `/media/removeable/SANDISK 32`.

2. **Downloading the Linux Mint ISO:**

   ```bash
   curl -L -C - --progress-bar -o linuxmint.iso https://mirrors.layeronline.com/linuxmint/stable/22.1/linuxmint-22.1-cinnamon-64bit.iso
   ```

3. **Writing the ISO to the USB:**

   ```bash
   sudo dd if="/media/removeable/SANDISK 32/linuxmint.iso" of=/dev/sdb bs=4M status=progress && sync
   ```

4. **Disabling Screen Timeout:**

   ```bash
   sudo stop powerd
   sudo start powerd
   ```

5. **Checking Battery Status:**
   ```bash
   cat /sys/class/power_supply/BAT0/status
   cat /sys/class/power_supply/BAT0/capacity
   ```

---

## Firmware Update and Boot Troubleshooting

1. **Verifying Current Firmware Status:**

   - The device was running Stock ChromeOS with RW_LEGACY firmware.
   - Checked using `crossystem`:
     ```bash
     sudo bash
     crossystem | grep dev_boot
     ```
     - Outcome:  
       `dev_boot_altfw = 1`, `dev_boot_usb = 1`, and `dev_boot_signed_only = 0`.

2. **Using the MrChromebox Firmware Utility Script:**

   - Downloaded and executed the script:
     ```bash
     cd; curl -LO mrchromebox.tech/firmware-util.sh && sudo bash firmware-util.sh
     ```
   - **Script Screen Output:**

     ```
     ChromeOS Device Firmware Utility Script (2025-05-05) (c) Mr Chromebox <mrchromebox@gmail.com>

     ** Device: Lenovo 300e/500e Chromebook 2nd Gen
     ** Board Name: PHASER360
     ** Platform: Intel Gemini Lake

     Fu Type: Stock ChromeOS w/RW_LEGACY

     ** Fw Ver: Google_Phaser.11297.440.0 (01/24/2824)
     ** Fu WP: Enabled

     1) Install/Update RW_LEGACY Firmware
     2) Install/Update UEFI (Full ROM) Firmware
     3) Set Boot Options (GBB flags)
     4) Set Hardware ID (HWID)

     Select a numeric menu option or R to reboot, P to poweroff, Q to quit
     ```

   - **Decision:**  
     I chose **option 1** (Install/Update RW_LEGACY Firmware) to avoid disabling firmware write-protect.
   - Confirmed changes, then rebooted.
   - After reboot, pressed `Ctrl+L` then 1 then Enter. Initially saw a rabbit-looking coreboot logo on the screen.

### Boot Success & Troubleshooting

- At first, the coreboot (rabbit) logo seemed unresponsive. I eventually discovered that **pressing `ESC`** when the rabbit logo appeared allowed the boot sequence to proceed.
- After pressing `ESC`, the system booted from the USB drive and the **Linux Mint logo** appeared, indicating that the installer was loading.
- With the installer active, the next step was to follow the on-screen instructions to install Linux Mint Cinnamon.

---

## Installing Linux Mint

1. **Launching the Installer:**

   - From the Linux Mint live desktop, double-click the “Install Linux Mint” icon (usually a CD icon at the top left).

2. **Select Language and Keyboard Layout:**

   - **Language:** English (US)
   - **Keyboard Layout:** English (US)

3. **Internet Connection and Multimedia:**

   - Connected to Wi-Fi.
   - Installed multimedia codecs to support various media formats and website rendering.

4. **Installation Choices:**

   - Selected the option to erase the disk and install Linux Mint (which removes ChromeOS).
   - Encountered a warning prompt and clicked **Continue**.

5. **Time Zone and User Setup:**

   - Chose the appropriate time zone.
   - When prompted, entered:
     - **Your name** (full or display name)
     - **Your computer's name** (network/host name)
     - **A username** (login name)
     - **A password** (and confirmed it)
   - For login options, selected between:
     - **Login Automatically** or
     - **Require my password to login**
   - Chose whether or not to **encrypt my home folder** (this is optional).

6. **Installation Process:**

   - The installer showed a progress bar while copying files (approximately 10 minutes).
   - It then transitioned to installing applications, retrieving files, and downloading language packs (with a timer indicating around 1:44 remaining at one point).
   - After the process finished, the installer prompted me to reboot.

7. **Final Reboot and Boot Option:**
   - Removed the USB drive when prompted.
   - The system rebooted and initially returned to the OS Verification OFF screen.
   - I waited until it beeped twice, then the screen went black and displayed “Chrome OS is missing.”
   - I then rebooted, pressed `Ctrl+L` then 1 then Enter at the boot menu, and selected the default boot option.
   - The system then successfully booted into Linux Mint.

> **Note:**  
> I plan to later investigate how to make Linux Mint the default boot option (so I don't have to press `Ctrl+L`/`1` each time).

---

## Final Thoughts and Lessons Learned

- The entire conversion was performed entirely via software steps.
- I did not have to open up my Chromebook or remove any screws—everything was handled from within ChromeOS and using USB.
- Detailed logging of steps and troubleshooting was key, including adjustments at various stages (e.g., pressing `ESC` at the boot menu).
- This guide will be updated with additional notes and troubleshooting tips as I continue to refine the process and make Linux Mint the default boot OS.

---

Happy Linux hacking!
