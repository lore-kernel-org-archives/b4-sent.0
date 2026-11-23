From: Ricardo Pardini <ricardo@pardini.net>
Subject: [PATCH v2 0/3] arm64: dts: rockchip: Add Mekotronics R58X-Pro
Date: Mon, 23 Nov 2026 16:07:25 +0100
Message-Id: <20261123-rk3588-mekotronics-r58x-pro-v2-0-2a3430cf5f88@pardini.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK1WBGsC/32NQQ6CMBAAv0J6tqatxTae/IfhUNpFVmJLtkgwh
 L8L6NnjJJOZmWUghMwuxcwIRsyY4grqUDDfungHjmFlpoQ6Syktp+5UWsuf0KWBUkSfOZV24j0
 lXmrfBKfrYJ1ma6EnaHDa67fqy/lVP8APW3IzWsxDove+H+Xm/U5K/D2NkguuwQgvjPGm1tfeU
 cCIxwgDq5Zl+QCrsTHh2gAAAA==
X-Change-ID: 20261118-rk3588-mekotronics-r58x-pro-54cfda4bd8a4
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2971; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=d2sf5RqKKP9EUG7tTzYnxgGQH1qtUjbKzdzzezlCuVE=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBrBFa3i9XtZ2yfNALYmNG/zUk/nnL2bqosYSJzh
 5WtRwkL9QiJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCawRWtwAKCRA7Xj/jnsft
 6b8DB/9fKKUAJaUDZv3oDrjKGN+Vrd+GWo6/Kq2LKb0lsBhmXMmWxF9c7WrV3bsU5AJ15Ou8ZXV
 fxslsOp99JLuzjWBl4QaDpDTspokn24Z8Ikndie+8EKNy1BnrK0cxIqHjOS4EAz0ByTu6oFILky
 byMxTnrynnnl5YpY6dtn36No2j4C6X9sVOMqkJZQutpcvC6jQTHuBr2MdKYJoGCq/FNGbtOfTpC
 kWCQPXmOdcyr+u/aVZALPm3zV5SmHbsYPyqWrrF/IRLSViY6FlDjuCQlrb5WCN0i+//3y5+gqGI
 vgqKdlWo+RKWadHCcEbFhWFTCr4CHH/m+W4mkAVDDWwpIV2W
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
hotplug. DP alt mode goes to dp0 (VP1) through usbdp_phy0. With [1],
[2] and the dw-dp series [3], an Apple USB-C to HDMI adapter gives
1080p60 in both orientations, with USB 3.0 on the adapter working too.

Tested on the board with v7.4-rc3: it boots from eMMC and NVMe, and
both GbE ports, USB 3.0 over Type-C, the HDMI and DP outputs, DP alt
mode, headphone audio, the RTC, WiFi/BT, the LEDs, the keys, the GPU
(Panfrost) and the NPU (Mesa Teflon) work.

I used Claude for cleanups, ordering and naming, according to recent
series lore.

[1] https://lore.kernel.org/all/20261114-b4-rockchip-dwc3-rockchip-glue-v19-0-b79fb5f4b42a@collabora.com/
[2] https://lore.kernel.org/all/20261119-b4-rockchip-usbdp-cleanup-part3-v18-0-fb325e336494@collabora.com/
[3] https://lore.kernel.org/all/20261114-synopsys-dw-dp-improvements-v12-0-d42d3dc5bdd4@collabora.com/

---
Changes in v2:
- Describe DP alt mode on the Type-C port (dp0 via usbdp_phy0)
- Keep the default USB3 PHY on usb_host1_xhci, so the USBDP PHY disables
  the unused U3 port (Sashiko)
- Pull down the BT host-wake pin, it is active high (Sashiko)
- Add pinctrl for the HDMI0 FRL enable GPIO (Sashiko)
- Link to v1: https://patch.msgid.link/20261120-rk3588-mekotronics-r58x-pro-v1-0-4e70c077c7b4@pardini.net

---
Ricardo Pardini (3):
      dt-bindings: vendor-prefixes: Add Mekotronics
      dt-bindings: arm: rockchip: Add Mekotronics R58X-Pro
      arm64: dts: rockchip: Add Mekotronics R58X-Pro

 .../devicetree/bindings/arm/rockchip.yaml          |    5 +
 .../devicetree/bindings/vendor-prefixes.yaml       |    2 +
 arch/arm64/boot/dts/rockchip/Makefile              |    1 +
 .../dts/rockchip/rk3588-mekotronics-r58x-pro.dts   | 1285 ++++++++++++++++++++
 4 files changed, 1293 insertions(+)
---
base-commit: 23c62304dde29abe92013d85910d03a77dada35d
change-id: 20261118-rk3588-mekotronics-r58x-pro-54cfda4bd8a4

Best regards,
--  
Ricardo Pardini <ricardo@pardini.net>

