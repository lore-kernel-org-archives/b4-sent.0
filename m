From: Ricardo Pardini <ricardo@pardini.net>
Subject: [PATCH 0/3] arm64: dts: rockchip: Add Mekotronics R58X-Pro
Date: Fri, 20 Nov 2026 01:39:26 +0100
Message-Id: <20261120-rk3588-mekotronics-r58x-pro-v1-0-4e70c077c7b4@pardini.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL6W/2oC/yXMwQ6CMAwA0F8hPdvE4WYWf8V4GFvRStxIC4aE8
 O8MPb7LW0FJmBRuzQpCX1YuucKcGoivkJ+EnKqhPbdXY4xHGS7Oe/zQUCYpmaOiOL/gKAWdjX0
 Ktks+WKjDKNTz8tvvj7917t4Up6OEbdsBGklNMH8AAAA=
X-Change-ID: 20261118-rk3588-mekotronics-r58x-pro-54cfda4bd8a4
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2290; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=qkeBb/nL37zpe/lCO/iNX9Ueu125W6clmIxV9IQB1Tc=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq/5a/rKyFUzEa+akU1CoUICGtE4RZXisRa4iEo
 DiAG/Yw1bSJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCav+WvwAKCRA7Xj/jnsft
 6XrGB/oD0+HisA/tWCn9MPRMdhZzKXzX8CaKmRHlythf6+qJU/bdGa2w53MFO7AMhGfHJ6ll0VX
 tlRUrp0L/V4oLavjBeCdHl0DmaS/F1GO2Z1mpnIiaWI8wsTGco8BU70XsLRtwneMbb3CQqvQEuk
 9gsTZMzzU3BZGRwR/KqeCn9CyMobM89ln9N+I/fPVBiqy/B3yQwgWJQLN6hNGD1ffm3EkFPI3+u
 8k4Nb46tsnOlVWfXZUV7IpuE32nQ/k6/jU7iZqOazzldt1tNaMQHAzieVXwsTdvojsCnJ4or9mm
 e6EI/qkLtQ7WBZx6PKLUOK3DTC7B9iVwG1P8ud3++AJ3ohvD
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the Mekotronics R58X-Pro, an industrial
mini PC based on the Rockchip RK3588.

There is no public schematic; the DT is based on Armbian's and on the
vendor BSP DT.

dt-check-style --mode=strict is clean except where the existing
rockchip DTs differ (pinctrl-names first, no blank line before status)
and for names fixed by bindings.

GMAC0 gets RX CRC errors with rgmii-id under iperf3 load, so it uses
rgmii-rxid with tx_delay = <0x44>; GMAC1 uses rgmii-id.

The Type-C port is source only (the board is powered from a 12V barrel
jack). usbdp_phy0 has both orientation-switch and mode-switch, as
asked for in the cover letter of [2]. On its own, v7.4-rc3 brings up
USB 3.0 in either orientation at boot, but when the cable is re-plugged
the other way round, the SuperSpeed link does not come up until the
USBDP PHY is re-initialized. With Sebastian Reichel's pending DWC3 glue
[1] and USBDP [2] series applied, it works in both orientations on
hotplug. DP alt mode is not described, as I could not test it.

Tested on the board with v7.4-rc3: it boots from eMMC and NVMe, and
both GbE ports, USB 3.0 over Type-C, the HDMI and DP outputs,
headphone audio, the RTC, WiFi/BT, the LEDs, the keys, the GPU
(Panfrost) and the NPU (Mesa Teflon) work.

I used Claude for cleanups, ordering and naming, according to recent
series lore.

[1] https://lore.kernel.org/all/20261114-b4-rockchip-dwc3-rockchip-glue-v19-0-b79fb5f4b42a@collabora.com/
[2] https://lore.kernel.org/all/20261119-b4-rockchip-usbdp-cleanup-part3-v18-0-fb325e336494@collabora.com/

---
Ricardo Pardini (3):
      dt-bindings: vendor-prefixes: Add Mekotronics
      dt-bindings: arm: rockchip: Add Mekotronics R58X-Pro
      arm64: dts: rockchip: Add Mekotronics R58X-Pro

 .../devicetree/bindings/arm/rockchip.yaml          |    5 +
 .../devicetree/bindings/vendor-prefixes.yaml       |    2 +
 arch/arm64/boot/dts/rockchip/Makefile              |    1 +
 .../dts/rockchip/rk3588-mekotronics-r58x-pro.dts   | 1215 ++++++++++++++++++++
 4 files changed, 1223 insertions(+)
---
base-commit: 23c62304dde29abe92013d85910d03a77dada35d
change-id: 20261118-rk3588-mekotronics-r58x-pro-54cfda4bd8a4

Best regards,
--  
Ricardo Pardini <ricardo@pardini.net>

