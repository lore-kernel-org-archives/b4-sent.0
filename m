From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH v4 0/3] rtc: Add Cortina Systems CS7542 calendar clock
 support
Date: Tue, 24 Nov 2026 01:50:00 +0300
Message-Id: <20261124-b4-cs7542-rtc-v4-0-bceefd844074@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ7CIBCF4asY1mJgoKW68h7GBVBoMbY1UImm6
 d2FutEmunzJfP9MKBjvTECHzYS8iS64oU+DbzdIt7JvDHZ12ggIlJQCw4pjHUTBAftRY0sqWtV
 C2FoCSubmjXWPpXc6v3e4q4vRY47ki9aFcfDP5WGk+e5XO1JMcKkLJkpqrSTs2HTSXXd66FBuR
 /irIWlGpeLMgtaVWWv2qflas6QLtiegrDJEful5nl9aBTsAOAEAAA==
X-Change-ID: 20261123-b4-cs7542-rtc-f0818d77fda2
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795474200; l=4972;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=VhVJSYB9z2on++tWgQG/oLKkQMYVIodUrNY/c6ejsUM=;
 b=UgqFz5j9dCKQcMU6Mp72l5OtxPODMl0u/rDrvgg3MdUedYWWKhjK7/vzQZ0EVy6q463KLWjDw
 viPub9HjbI9B1k6ki+4UeXcilKX6Qe7W+0DtvB3Q098EfQp0ALf3rlG
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

Describe the hardware's 0000-9999 calendar with RTC_TIMESTAMP_BEGIN_0000
and RTC_TIMESTAMP_END_9999. BCDYEAR assigns bits 15:0 to year data and
reserves bits 31:16. The range metadata models physical encoding and is
used by the core's offset handling. Ordinary core validation still
rejects dates before 1970; no public calendar-validation bypass is added.
Alarm interrupts and suspend wake are not implemented.

The three patches are the binding, driver/Kconfig/Makefile and a
MAINTAINERS entry, based on v7.4-rc4 without the pending CS75xx platform
or clock/pinctrl series.

Validation:
- strict source checkpatch: no errors, warnings or checks
- complete minimal ARM vmlinux and modules builds, RTC built in and
  modular, GCC 14.2, W=1, COMPILE_TEST=n, without the platform
- actual read/set/probe functions and core calendar validation helpers
  with mocked MMIO and UBSAN: 10000 BCD-year round trips from 0000 through
  9999, all 256 control-byte patterns, disabled/reset rejection, probe
  side effects, known-time enable, future boundaries and error paths;
  pre-1970 core rejection is checked separately from callback decoding

On Almond+, an additional Linux 7.4-rc4 RAM-only fixture called the actual
RTC callbacks under ops_lock to check the physical lower range. It
bypassed core calendar validation only inside the separate test module.
These six transitions passed, with raw BCDYEAR and decoded callback
fields recorded:
- 0000-01-01, 00:00:00 to 00:00:01, with raw year 0
- 0000-02-28 to February 29
- 0099-12-31 to 0100-01-01
- 0100-02-28 to March 1
- 0400-02-28 to February 29
- 1969-12-31 to 1970-01-01
The module recorded 219 checks, no failures, and verified current-UTC
restoration. The outer RAM supervisor independently verified restoration
before watchdog return, followed by fresh host-UTC restoration in
installed OpenWrt. Firmware was not flashed. Direct pre-1970 callback
reads succeeded while the unchanged core validator returned EINVAL;
the transition into 1970 became core-valid.

The v3 review run had already checked disabled/reset reprobe, invalid
reads, known-current-time set/enable and counting. Its separate range
fixture passed 1970 and 2038 ticks, year 2000 leap day, century carries into
2100/2200/2400, non-leap 2100/2200, leap 2400, and 9999-12-31 at 23:59:58 to
23:59:59. These are targeted hardware cases. The 10000-year round trips
above are software encoding checks, not a hardware sweep of every year.

---
Changes in v4:
- Describe the hardware's 0000-9999 range using RTC_TIMESTAMP_BEGIN_0000;
  keep the core's ordinary pre-1970 calendar validation unchanged.
- Check year 0000, early-century carry/leap transitions and 1969 to 1970
  through direct callbacks in a guarded RAM-only fixture.
- State the hardware calendar range explicitly in Kconfig help.
- Link to v3: https://patch.msgid.link/20261124-b4-cs7542-rtc-v3-0-53902bfbe0ae@gmail.com

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

