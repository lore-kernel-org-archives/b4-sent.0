From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH v2 0/3] rtc: Add Cortina Systems CS7542 calendar clock
 support
Date: Mon, 23 Nov 2026 23:27:00 +0300
Message-Id: <20261123-b4-cs7542-rtc-v2-0-31ab43f2cc8e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6CMBBFf4XM2jFteZS48j8Mi1JaGCPUtEg0p
 P9ui2uXJzn33B2C8WQCXIodvNkokFsSiFMBelLLaJCGxCCYaDgXJfYV6iDrSqBfNVrW8naQ0g5
 KQNo8vbH0Pnq37sfh1d+NXnMkGxOF1fnPcbjx7P1rbxwZNrouZcOtVay8jrOix1m7GboY4xd1s
 cxLvAAAAA==
X-Change-ID: 20261123-b4-cs7542-rtc-f0818d77fda2
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795465620; l=3354;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=a/wF/4Ko9QK5xjn99mr5dhgpXbagDzvGTbxdN83EbHE=;
 b=eVgG7vvgPOYVRQRbCsR6+fGr8b55K7cZH1A8wAc2e3YBgRxv4yVem/vYZdfXAGS5buIBucuoD
 oip0g87xUHrDuwDAUj4LMx+hw3ugDmLUOo5c5zay35MTosk7tqnzXuq
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the memory-mapped calendar clock of the CS7542, based on the GPL
vendor and OpenWrt implementation. Use an independent OF/HAS_IOMEM
Kconfig option so the driver can be reviewed without the pending
platform series.

The initial driver supports calendar reads and setting the clock in
the 2000-2099 range. It decodes the four-digit BCD year, bounds retries
across second changes and retains RTCEN after programming. The alarm
and suspend-wakeup features are deliberately not advertised.

An alarm prototype was investigated on the board, but the expected
alarm IRQ did not arrive. Time-of-day and calendar comparisons and
interrupt-mode experiments have not yet established the missing
hardware behaviour. Those experiments are retained locally and are not
included as working functionality in this series. This is a calendar
support submission, not a claim that alarms have been fixed.

The three patches are the binding, the driver/Kconfig/Makefile and a
MAINTAINERS entry. They apply to Linux v7.4-rc4 without the pending
CS75xx platform or clock/pinctrl series. 

Validation:
- binding schema, example compilation and style checks passed
- strict source checkpatch with --no-signoff: no errors/warnings/checks
- complete minimal ARM vmlinux and modules builds with both new
  drivers built in and modular, COMPILE_TEST=n, without the platform
- actual driver functions tested with mocked MMIO/regmap and UBSAN
- exact sources booted in a Linux 7.4-rc4 RAM integration kernel on
  Almond+, with platform v9, clock/pinctrl and the accepted watchdog

RTC opened, read a valid date, advanced over two seconds, accepted
setting the current time and kept counting afterwards. The alarm ioctl
was rejected, matching the advertised support scope.
The final combined RAM test recorded 16 checks with no failures and
returned to installed OpenWrt 6.18.64 through the watchdog. Both CPUs
were online. The firmware was not flashed. Earlier incomplete or
experimental alarm runs are not counted as this successful test.

---
Changes in v2:
- Place RTC_DRV_CS75XX in the on-CPU RTC section, outside the HID section.
- Keep the Makefile entry alphabetical. Driver C code is unchanged.
- Link to v1: https://patch.msgid.link/20261123-b4-cs7542-rtc-v1-0-6c53761ffa03@gmail.com

To: Fil Dunsky <filipp.dunsky@gmail.com>
To: Alexandre Belloni <alexandre.belloni@bootlin.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: linux-rtc@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Fil Dunsky (3):
      dt-bindings: rtc: Add Cortina Systems CS7542 RTC
      rtc: Add Cortina Systems CS7542 RTC driver
      MAINTAINERS: Add Cortina Systems CS7542 RTC support

 .../bindings/rtc/cortina,cs7542-rtc.yaml           |  48 ++++++
 MAINTAINERS                                        |   7 +
 drivers/rtc/Kconfig                                |   9 ++
 drivers/rtc/Makefile                               |   1 +
 drivers/rtc/rtc-cs75xx.c                           | 174 +++++++++++++++++++++
 5 files changed, 239 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-rtc-f0818d77fda2

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

