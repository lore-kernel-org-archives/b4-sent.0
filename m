From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH v3 0/3] rtc: Add Cortina Systems CS7542 calendar clock
 support
Date: Tue, 24 Nov 2026 01:00:12 +0300
Message-Id: <20261124-b4-cs7542-rtc-v3-0-53902bfbe0ae@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NwQ6CMBAFf4X0bE13C5R48j+Mh7K0UCNiWmw0h
 H+3xYsXPU7yZt7CgvHOBHYoFuZNdMFNtwRyVzAa9K033HWJGQqsAVDytuQUVFUi9zNxKxpoOqV
 sp5El5+6Ndc+tdzp/ODzai6E5R/JicGGe/Gs7jJB3v9oRuOA1VVLVYK0W8tiP2l33NI0styP+t
 THZEnRbSotEjfm213V9AwyMikr6AAAA
X-Change-ID: 20261123-b4-cs7542-rtc-f0818d77fda2
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795471212; l=3972;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=Sj4YCV8Y8oxQ28BgyN0TnodyFRFNZWfHAe8RuVb9Ha4=;
 b=hZkqQdDvSTSzOy3Ge48RCYLbklX0Q+STk6tS8El0cDwtXsqEWg+iqPMEOPLLS1pR5hv3aluNT
 jmL/ASdhuXHBNWARdJ/JIYyEuoQz+FDXdRc6XbntLAVpNvmR0rjrTpT
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the memory-mapped calendar clock of the CS7542, based on the GPL
vendor and OpenWrt implementation. Use an independent OF/HAS_IOMEM
Kconfig option so the driver can be reviewed without the pending
platform series.

Decode the four-digit BCD year, bound retries across second changes and
retain RTCEN after programming. Leave a disabled or reset RTC alone at
probe and report its time as invalid until a known time is set. The RTC
core validates the decoded calendar and handles absent alarm callbacks.

The vendor-generated BCDYEAR register definition assigns all bits 15:0
to year data and reserves bits 31:16. With the century and leap transitions
below verified, advertise the representable 1970-9999 range. Alarm
interrupts and suspend wake are not implemented; an earlier alarm
prototype did not produce the expected IRQ and is not included.

The three patches are the binding, driver/Kconfig/Makefile and a
MAINTAINERS entry, based on v7.4-rc4 without the pending CS75xx platform
or clock/pinctrl series.

Validation:
- strict source checkpatch: no errors, warnings or checks
- complete minimal ARM vmlinux and modules builds, RTC built in and
  modular, GCC 14.2, W=1, COMPILE_TEST=n, without the platform
- actual read/set/probe functions with mocked MMIO and UBSAN: all 256
  control-byte patterns, disabled/reset rejection, no probe MMIO writes,
  known-time enable, 8030 BCD-year round trips from 1970 through 9999,
  future boundary values, core calendar validation and retry/error paths

On Almond+, an exact driver RAM integration run on Linux 7.4-rc4 first
verified no control changes on reprobe, EINVAL with RTCEN clear or CLKRST
set, then setting known current UTC, enable/reset handling and counting.
A second RAM fixture used the same operations with a widened range and
raw calendar tracing to check these ten cases:
- 1970 first-second tick; 2000 leap day; 2038 boundary tick
- 2099 to 2100; 2100 February 28 to March 1
- 2199 to 2200; 2200 February 28 to March 1
- 2399 to 2400; 2400 February 28 to February 29
- 9999 December 31, 23:59:58 to 23:59:59
All passed. This is hardware evidence for those cases, not a hardware
sweep of every encoded year. Each run restored current UTC before its
watchdog return to installed OpenWrt; a fresh host UTC restoration was
verified again afterwards. Firmware was not flashed. Earlier v1/v2
RAM evidence is not counted as these v3 review and range tests.

---
Changes in v3:
- Preserve RTC enable/reset state at probe; report disabled/reset time
  as invalid and initialise it only when setting a known time.
- Let the core validate calendar fields and remove redundant ALARM
  feature clearing and the two noisy probe messages.
- Advertise 1970-9999 after checking the 16-bit BCD field, critical century
  carries, Gregorian century leap rules and the 9999 endpoint on hardware.
- Link to v2: https://patch.msgid.link/20261123-b4-cs7542-rtc-v2-0-31ab43f2cc8e@gmail.com

Changes in v2:
- Place RTC_DRV_CS75XX in the on-CPU RTC section, outside the HID section.
- Keep the Makefile entry alphabetical. Driver C code is unchanged.
- Link to v1: https://patch.msgid.link/20261123-b4-cs7542-rtc-v1-0-6c53761ffa03@gmail.com

---
Fil Dunsky (3):
      dt-bindings: rtc: Add Cortina Systems CS7542 RTC
      rtc: Add Cortina Systems CS7542 RTC driver
      MAINTAINERS: Add Cortina Systems CS7542 RTC support

 .../bindings/rtc/cortina,cs7542-rtc.yaml           |  48 +++++++
 MAINTAINERS                                        |   7 +
 drivers/rtc/Kconfig                                |   9 ++
 drivers/rtc/Makefile                               |   1 +
 drivers/rtc/rtc-cs75xx.c                           | 159 +++++++++++++++++++++
 5 files changed, 224 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-rtc-f0818d77fda2

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

