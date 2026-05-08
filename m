From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Subject: [PATCH 0/7] hwmon: (pmbus/adm1266) RTC fix, blackbox, FW rev,
 rtc_class
Date: Fri, 08 May 2026 16:33:12 -0700
Message-Id: <20260508-adm1266-v1-0-ec08bf29e0ce@nexthop.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALhy/mkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDUwNz3cSUXEMjMzPd5DTjxDQTo5Rk4xQjJaDqgqLUtMwKsEnRsRB+cWl
 SVmpyCUi7Um0tAH79X4hrAAAA
X-Change-ID: 20260507-adm1266-cf3af42dc3d2
To: Guenter Roeck <linux@roeck-us.net>, 
 Alexandru Tachici <alexandru.tachici@analog.com>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2581;
 i=abdurrahman@nexthop.ai; h=from:subject:message-id;
 bh=jt0U3NVrVS1sKLM6aSFaTtJhs6yLPAuUJNrXgqbkitg=;
 b=owJ4nJvAy8zAJbYltPXv6rsCXxhPqyUxZP4r2p+ZsuDQpJOV5jeuBCUtnlPwfeOFcx4+Vxl57
 vT5WM55NKOyo5SFQYyLQVZMkWXOI/83bR1tERtiDtnDzGFlAhnCwMUpABN5OpHhf6Dufk1G0+Jj
 64NuXj7Es3fOnOBSJfO7m26onDkp4+rmGMDwP+J7ncqVmOnRZ9+s6ZibfMNgg1OZ6s+Vshb7Ij6
 c/iktxA8A3JdTJg==
X-Developer-Key: i=abdurrahman@nexthop.ai; a=openpgp;
 fpr=9CE24FEC86888658B05CC23FB45585FDABDD10F4
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/default with auth_id=756
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes a few issues in the adm1266 driver and fills in
some gaps, as listed below.

Patch 1 is a wall-clock RTC bug fix: the driver currently seeds the
device's timestamp counter with CLOCK_MONOTONIC seconds, which makes
blackbox record timestamps non-comparable across reboots. It carries
a Fixes: tag.

Patch 2 writes the 16-bit fractional-seconds field of SET_RTC that
the driver was zeroing, restoring sub-second resolution on records.

Patch 3 exposes the firmware revision (IC_DEVICE_REV, 0xAE) via
debugfs alongside the existing sequencer_state entry.

Patch 4 adds a write-only clear_blackbox debugfs file. Devices
configured for single-recording mode (BLACKBOX_CONFIG[0] = 0) need
an explicit clear once the 32-record buffer fills; the documented
sub-command ({0xFE, 0x00} block-write to 0xDE) wasn't reachable
from userspace.

Patch 5 exposes the non-volatile POWERUP_COUNTER (0xE4) via debugfs.
The same value is embedded in every blackbox record, so the live
value lets userspace match a captured record back to the boot it
came from when correlating logs.

Patch 6 registers an rtc_class device backed by SET_RTC. The data
sheet (Rev. D, p. 22) explicitly recommends "frequently send the
time stamp to the ADM1266 to synchronize the UNIX time and reduce
the time from drifting" when running on the internal oscillator
(no external 32.768 kHz crystal). With this patch userspace can
drive the re-sync via standard tooling (hwclock, chrony,
systemd-timesyncd) against /dev/rtcN, with no driver-specific
sysfs ABI.

Patch 7 disambiguates GPIO line labels on platforms that fit two
ADM1266 devices on different I2C buses at the same slave address.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
Abdurrahman Hussain (7):
      hwmon: (pmbus/adm1266) use wall-clock seconds for SET_RTC
      hwmon: (pmbus/adm1266) write fractional-seconds field of SET_RTC
      hwmon: (pmbus/adm1266) add firmware_revision debugfs entry
      hwmon: (pmbus/adm1266) add clear_blackbox debugfs entry
      hwmon: (pmbus/adm1266) add powerup_counter debugfs entry
      hwmon: (pmbus/adm1266) register rtc_class device backed by SET_RTC
      hwmon: (pmbus/adm1266) include adapter number in GPIO line label

 drivers/hwmon/pmbus/adm1266.c | 177 +++++++++++++++++++++++++++++++++++++++---
 1 file changed, 167 insertions(+), 10 deletions(-)
---
base-commit: 917719c412c48687d4a176965d1fa35320ec457c
change-id: 20260507-adm1266-cf3af42dc3d2

Best regards,
--  
Abdurrahman Hussain <abdurrahman@nexthop.ai>

