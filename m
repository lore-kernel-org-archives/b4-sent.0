From: Rajan Yadav <rajanyadav0307@gmail.com>
Subject: [PATCH 0/4] arm64: dts: allwinner: Add KickPi K5C
Date: Fri, 20 Nov 2026 01:22:12 -0600
Message-Id: <20261120-k5c-dt-v1-v1-0-d9681df67bc0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACT1/2oC/yXM3QpAQBBA4VfRXJsy6zevIheswVBod0nJu1tcf
 nU6F1g2whbK4ALDh1hZFw8KA9BjswyM0nmDilRGpCKcU42dw4MwLnLO0qZISCfg+81wL+f3qur
 fdm8n1u4dwH0/nClLCG0AAAA=
X-Change-ID: 20261120-k5c-dt-v1-387e65a841c4
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 Andre Przywara <andre.przywara@arm.com>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Rajan Yadav <rajanyadav0307@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795159332; l=5556;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=PNC3qCIwbbDam5Yu7LK4Iz66FU/xwdUVpki3A9YlmrM=;
 b=jzPCYr6zsXU3C0Ttm80LxId1a1QLk8L+fERlK0JT+zYRmqO/7+vlOiilo3obWjLIwAjLrL4yx
 eESescRv2oXAYiui4Y8G/pqM6hpfl9tLRjkO9lyAWftwq9ADSH7kbcB
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Andre asked [1] to get the device tree for the KickPi K5C upstream and
to work with Paul on it. Paul, I have not heard back from you yet [2], so
here is my version; I am happy to rework it with your input, and a review
or a test on your board would be very welcome.

The KickPi K5C is a single board computer with an Allwinner A133. This
series adds a vendor prefix for KickPi (patch 1), the board compatible
(patch 2), a pin group for I2C3 on PH12/PH13, where the board's RTC sits
(patch 3), and the board device tree (patch 4). It is based on
sunxi/for-next, which has the A100 CPU thermal trips.

A correction to my mail of 18 November [2]: I wrote that I do not have
the board schematic. That was wrong. KickPi publishes the V1.3 schematic
on its documentation site; the regulators and pins in patch 4 follow it
and were checked against the vendor's device tree and on the board.

The vendor prefix uses the company name that KickPi gives on its own
documentation site and as the registered owner of the KICKPI trademark
(Shenzhen Kickpi Digital Technology Co., Ltd., US registration
7747802 [4]). KickPi confirmed this name and the "kickpi" prefix by
e-mail, and their engineers would like to follow the review; I will send
them the link to this thread.

Patch 4 describes only what I could verify on the board. Left out for
now, with the reason in the commit message: Ethernet (the PHY driver is
not in mainline yet), the Wi-Fi/BT module (no mainline driver, and its
SDIO card did not come up after a cold boot in my tests), USB data on
the USB-C port (not tested) and the RTC alarm interrupt (on PB8; it will
follow once fully tested). The CPU uses the A100 OPP table, like the
other A133 boards; once the A133 speed grade series [3] is merged, I
will send a one-line patch to switch the K5C to the A133 table.

Testing (KickPi K5C, PCB V1.3, powered from a PC's USB port through the
USB-C connector; sunxi/for-next plus "cpufreq: sun50i: Handle boards
with the allwinner,sun50i-a133 compatible" [5], which is applied to the
cpufreq tree and in linux-next; without it cpufreq does not start on
this board, but there is no build dependency):
- dtbs_check W=1 adds no warning (only the existing /soc one from
  sun50i-a100.dtsi), also on linux-next; dt_binding_check, checkpatch
  --strict and dt-check-style (relaxed: clean; strict: only property
  names defined by existing bindings); each patch builds on its own
- PMIC: every enabled rail read back from the AXP registers matches the
  device tree; unused rails are off; DCDC2/3 dual phase confirmed
- eMMC: HS200, 8-bit, 150 MHz; two full reads of the 15.6 GB device give
  the same checksum
- SD card: 256 MB written, read back after dropping caches, identical
- USB-A: the on-board GL852G hub enumerates; a USB stick reads back
  identically at high speed
- RTC: time set and read back, kept across reboots (no backup battery
  is fitted on my board, so it is lost on power-off)
- status LED: lights up when switched on and blinks with the heartbeat
  trigger
- cpufreq: every OPP runs at the expected clock and PMIC voltage; the
  90 C passive and 110 C critical trips are in place
- 30 warm reboots and 3 cold boots of this version, each checked (eMMC
  HS200, SD, USB hub, RTC, LED, cpufreq, thermal trips)
- 10034 random cpufreq transitions under load: every OPP ran at the
  expected clock and PMIC voltage
- soaks of 1 and 3 hours with full load on all four cores and, in
  parallel, repeated eMMC reads, SD card write/read-back and USB stick
  reads (477 passes each): no mismatch, no I/O error, no new kernel
  warning; without a heatsink the CPU sits at the 90 C passive trip
  and is throttled by one step, never near the 110 C critical trip
- the RTC kept time to within 1 s over 3 hours

How this was made (Documentation/process/generated-content.rst): I used
Claude Code (Anthropic, Claude Opus 5.5) throughout. It used the board
schematic, KickPi's documentation and the vendor device tree as sources
of hardware facts, compared the existing A133 board files for style,
drafted the device tree, the binding changes and all commit messages,
and wrote the test scripts. No text or code was copied from vendor
sources. I reviewed every patch and ran the tests on my board myself,
and I take responsibility for the series.

[1] https://lore.kernel.org/all/d4d89cf9-884d-424b-927d-5b6692f50327@arm.com/
[2] https://lore.kernel.org/all/CANxy8yTA7Nqmggk=qn7tCnXn50vS2ceHdZYZC0_OancmZhnKcg@mail.gmail.com/
[3] https://lore.kernel.org/all/20261118-a133-series-v2-0-8bcec9c9aadf@gmail.com/
[4] https://tsdr.uspto.gov/statusview/sn98032871
[5] https://lore.kernel.org/all/20261104-a133-fix-v1-1-d0b5ad3d4c5d@gmail.com/

---
Rajan Yadav (4):
      dt-bindings: vendor-prefixes: Add Shenzhen Kickpi Digital Technology
      dt-bindings: arm: sunxi: Add KickPi K5C
      arm64: dts: allwinner: a100: Add I2C3 pins on PH12/PH13
      arm64: dts: allwinner: a133: Add KickPi K5C

 Documentation/devicetree/bindings/arm/sunxi.yaml   |   5 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 arch/arm64/boot/dts/allwinner/Makefile             |   1 +
 arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi     |   6 +
 .../boot/dts/allwinner/sun50i-a133-kickpi-k5c.dts  | 228 +++++++++++++++++++++
 5 files changed, 242 insertions(+)
---
base-commit: 03b3355ed7a39b4416f0d0a39061479b1aa13196
change-id: 20261120-k5c-dt-v1-387e65a841c4

Best regards,
--  
Rajan Yadav <rajanyadav0307@gmail.com>

