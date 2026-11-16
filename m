From: Igor Velkov <iav@iav.lv>
Subject: [PATCH v2 0/8] alarmtimer: Pick the wakeup RTC per suspend state
Date: Mon, 16 Nov 2026 00:24:59 +0000
Message-Id: <20261116-b4-alarmtimer-rtc-priority-v2-0-b2c69721e489@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFxN+moC/43NTQ6CMBCG4auQWTumU7GCK+9hWBQcZRL+Mm0aC
 eHuVk/g8vkW77dBYBUOcC02UE4SZJ4y7KGArvfTi1Ee2WCNdUSmxLZEP3gdo4ysqLHDRWVWiSt
 atmc6kbc1XSAHFuWnvH/xe5PdS4izrr+vRN/1r2wiNMh17VxFbWUqdxOfjkOCZt/3D0k86ybBA
 AAA
To: John Stultz <jstultz@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>
Cc: Stephen Boyd <sboyd@kernel.org>, Miroslav Lichvar <mlichvar@redhat.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3970; i=iav@iav.lv;
 h=from:subject:message-id; bh=k9wmTILcWLHAdWH9pEL5KIITiwGEzZ7A8xsajYITXGs=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFm/fONda/jifC9dNHd7uuFW/OXqtxosHxuq10Z0PrspE
 ut7vnJrRykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZiIwzOGvyJhGqXz0y5GRxW1
 hK34/lHhjbiR95SkH0fuPSp1NdVxm8rwi7nrdS1z+Hf+e3k+dikf7ZmZ12yQWdrms2HO4n0bT2X
 O5AcA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

alarmtimer takes the first RTC with an alarm and a wakeup capable parent
and programs it on every suspend. Which RTC wakes the system can depend
on the suspend state. On ODROID-HC4, meson-vrtc is a register the SoC
firmware reads when the application processors suspend: it wakes the
board from deep sleep only, and only with a BL301 that handles it, while
the pcf8563 wakes it from s2idle. meson-vrtc registers first, so an
alarm does not wake the board from s2idle.

The series keeps an RTC per suspend state, taken from a new
linux,wakeup-states property of the RTC's parent, structured as Thomas
suggested:

  1-2  alarmtimer_has_rtcdev(), the state in struct rtc_wakeup
  3    the freezer delta replaced with per type expiry times
  4    a platform device without a parent, linked to the RTC, with
       sysfs links per suspend state
  5    an RTC per suspend state; suspend is rejected when an alarm is
       pending and no RTC wakes the system from the target state
  6-7  the binding and its parser
  8    ODROID-HC4

Without the property every RTC is taken for every state, so the first
one is used as before.

The user space found to look the platform device up (omarchy-mobile,
hostmobility, z13ctl) matches it by name under
/sys/bus/platform/devices or by a glob over /sys, and still finds it
under /sys/devices/platform.

Patch 8 needs the pcf8563 interrupt [1] for s2idle. Without it the
pcf8563 takes s2idle but cannot wake the board, which is no worse than
today.

Tested on ODROID-HC4 on top of timers/core with [1]:
- s2idle: the pcf8563 alarm wakes the board
- deep: meson-vrtc wakes it, the pcf8563 is not programmed
- a CLOCK_BOOTTIME_ALARM clock_nanosleep() interrupted by the freezer
  wakes the board from deep sleep
- with the pcf8563 limited to "deep", s2idle with an alarm pending
  fails with -EOPNOTSUPP
The PCIe root port was removed for s2idle: pci-meson has no PM
callbacks and the board does not resume otherwise. The same tests
passed on v7.3.4 with the five alarmtimer commits from timers/core and
lockdep enabled. sparse reports nothing new.

[1] https://lore.kernel.org/r/20261019-hc4-rtc-alarm-irq-v1-1-078fc79e596f@iav.lv

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Changes in v2:
- restructured as suggested, no priority property, no list of RTCs
- one platform device for all RTCs, ordered by a device link to each
- sysfs links per suspend state
- the freezer delta replaced
- suspend rejected when no RTC covers the target state
- binding: s2idle, shallow, deep or none; hibernate and off dropped
- based on tip timers/core
- Link to v1: https://lore.kernel.org/r/20261104-b4-alarmtimer-rtc-priority-v1-0-e996681b8086@iav.lv

---
Igor Velkov (8):
      alarmtimer: Replace alarmtimer_get_rtcdev() with alarmtimer_has_rtcdev()
      alarmtimer: Move the wakeup state into struct rtc_wakeup
      alarmtimer: Replace the freezer delta with per type expiry times
      alarmtimer: Register the platform device without a parent
      alarmtimer: Keep an RTC per suspend state
      dt-bindings: rtc: Add linux,wakeup-states
      alarmtimer: Read the wakeup states of an RTC from linux,wakeup-states
      arm64: dts: amlogic: meson-sm1-odroid-hc4: Describe which RTC wakes the board

 .../bindings/rtc/amlogic,meson-vrtc.yaml           |   2 +
 .../devicetree/bindings/rtc/nxp,pcf8563.yaml       |   2 +
 Documentation/devicetree/bindings/rtc/rtc.yaml     |  17 ++
 .../boot/dts/amlogic/meson-sm1-odroid-hc4.dts      |   5 +
 drivers/power/supply/charger-manager.c             |   2 +-
 include/linux/alarmtimer.h                         |   7 +-
 kernel/time/alarmtimer.c                           | 228 +++++++++++++--------
 7 files changed, 174 insertions(+), 89 deletions(-)
---
base-commit: 0359ecff58853a491dd0f09792fea8e87235ae06
change-id: 20261104-b4-alarmtimer-rtc-priority-2e25131a2917

Best regards,
-- 
Igor Velkov <iav@iav.lv>

