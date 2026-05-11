From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Subject: [PATCH v2 0/5] hwmon: (pmbus/adm1266) blackbox, FW rev, rtc_class,
 GPIO label
Date: Sun, 10 May 2026 21:48:06 -0700
Message-Id: <20260510-adm1266-v2-0-3a22b903c2f1@nexthop.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIZfAWoC/z2NQQ6CMBBFr0JmbU0ZtKIr72FYlOnUjolAWiQYw
 t0FjC5f8v77EySOwgku2QSRB0nSNgvgLgMKtrmzErcwoEajj/qkrHvmaIwiX1h/QEeFQ1jsLrK
 XcSvdqi+nV/1g6tf5agRJfRvf29WQr96vWv6rQ660YtJl7fHMmvja8NiHtttbgWqe5w9DT6F8s
 QAAAA==
X-Change-ID: 20260507-adm1266-cf3af42dc3d2
To: Guenter Roeck <linux@roeck-us.net>, 
 Alexandru Tachici <alexandru.tachici@analog.com>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3349;
 i=abdurrahman@nexthop.ai; h=from:subject:message-id;
 bh=ge4OQCXy0fmwgEqR1w3vvbQqKhQjN1Vu7qZH9VrR5JI=;
 b=owJ4nJvAy8zAJbYltPXv6rsCXxhPqyUxZDHGL2Fk89+qyNzOx629o7F7Y2Z3iSSf6+W4CXxBa
 y6nZGftndNRysIgxsUgK6bIMueR/5u2jraIDTGH7GHmsDKBDGHg4hSAifhqM/zT+HzF493XuROu
 5uzzCy0462Hzy0pd4uzvA+UFk+d2FT/KZPifI74iwDeH59akOEGbR4w1Tw8VXKh6t2zJMRav1a9
 mdYjxAAArI0y1
X-Developer-Key: i=abdurrahman@nexthop.ai; a=openpgp;
 fpr=9CE24FEC86888658B05CC23FB45585FDABDD10F4
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/default with auth_id=756
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fills in some gaps in the adm1266 driver and removes a
probe-time RTC seed that was clobbering valid device state.

Patch 1 exposes the firmware revision (IC_DEVICE_REV, 0xAE) via
debugfs alongside the existing sequencer_state entry.

Patch 2 adds a write-only clear_blackbox debugfs file. Devices
configured for single-recording mode (BLACKBOX_CONFIG[0] = 0) need
an explicit clear once the 32-record buffer fills; the documented
sub-command ({0xFE, 0x00} block-write to 0xDE) wasn't reachable
from userspace.

Patch 3 exposes the non-volatile POWERUP_COUNTER (0xE4) via debugfs.
The same value is embedded in every blackbox record, so the live
value lets userspace match a captured record back to the boot it
came from when correlating logs.

Patch 4 replaces the probe-time SET_RTC seed with an rtc_class
device backed by SET_RTC. The existing seed used CLOCK_MONOTONIC
seconds, which is meaningless as a wall-clock time and clobbers
whatever the device retained across a warm reboot. The data sheet
(Rev. D, p. 22) explicitly recommends "frequently send the time
stamp to the ADM1266 to synchronize the UNIX time and reduce the
time from drifting" when running on the internal oscillator (no
external 32.768 kHz crystal). Letting userspace own the policy via
standard tooling (hwclock, chrony, systemd-timesyncd) against
/dev/rtcN is both more correct and avoids any driver-specific
sysfs ABI.

Patch 5 disambiguates GPIO line labels on platforms that fit two
ADM1266 devices on different I2C buses at the same slave address.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
Changes in v2:
- Drop the v1 "use wall-clock seconds for SET_RTC" and "write
  fractional-seconds field of SET_RTC" patches. v1 patch 6 already
  added an rtc_class device, so userspace now owns the time-set
  policy and the probe-time seed is no longer needed - removing it
  also fixes the cross-reboot blackbox-correlation regression the
  seed introduced.
- In the rtc_class patch, write the SET_RTC fractional-seconds
  bytes as zero rather than computing them from a timespec64. The
  rtc_class API is second-precision, so the divide that v1 patch 2
  was adding never produced a non-zero result anyway. This also
  drops the 64-bit divide that would have failed to link on 32-bit
  builds (Sashiko review).
- Use %d (decimal) for the I2C adapter number in GPIO line labels,
  matching the i2c-N convention used elsewhere in Linux. v1 used
  %x, which rendered bus numbers >= 10 in hexadecimal (Sashiko
  review).
- Link to v1: https://patch.msgid.link/20260508-adm1266-v1-0-ec08bf29e0ce@nexthop.ai

---
Abdurrahman Hussain (5):
      hwmon: (pmbus/adm1266) add firmware_revision debugfs entry
      hwmon: (pmbus/adm1266) add clear_blackbox debugfs entry
      hwmon: (pmbus/adm1266) add powerup_counter debugfs entry
      hwmon: (pmbus/adm1266) replace probe-time RTC seed with rtc_class device
      hwmon: (pmbus/adm1266) include adapter number in GPIO line label

 drivers/hwmon/pmbus/adm1266.c | 162 ++++++++++++++++++++++++++++++++++++++----
 1 file changed, 150 insertions(+), 12 deletions(-)
---
base-commit: 917719c412c48687d4a176965d1fa35320ec457c
change-id: 20260507-adm1266-cf3af42dc3d2

Best regards,
--  
Abdurrahman Hussain <abdurrahman@nexthop.ai>

