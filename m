From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/3] arm64: dts: rockchip: Orange Pi 5/5B ethernet, SPI NOR
 supply and USB-C DP
Date: Tue, 10 Nov 2026 07:19:32 +0000
Message-Id: <20261110-opi5-dts-v1-0-582b63d074be@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw5AMBCF4VeRWWvScanLq4gFNRgLpINIxLsrl
 l/yn3OBkGMSKIMLHB0svMweGAZgx2YeSHHnDZGODCJqtaycqm4TlbR5nBRoTaYN+Hx11PP5XVX
 1b9nbiez27uG+H2Knik1sAAAA
X-Change-ID: 20261110-opi5-dts-4b83491c6706
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295172; l=2440;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=HJ/BXx7+tB60XtSCFZJWcugv6n2lOzZb7iZUXRqozfI=;
 b=5GcNHNcKvKaV4jXPqK/dC/4X9EZf9mooqT4NdHmNcxGE6rWJL8JNsJ1LYJ2mwbqcXZutICLzk
 uaFQaoDtRN0C4xMko4yb7z1nyJwqbpwA7vQAbg65oQhLOin5qMsBzgA
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three device tree changes for the Orange Pi 5 and 5B:

1. The YT8531C PHY on gmac1 is described as "rgmii-rxid" with a MAC TX
   delay copied from the vendor kernel; the PCB adds no delay, so the
   correct description is "rgmii-id" (as the Orange Pi CM5 already
   uses), with both delays in the PHY.
2. The SPI NOR flash gets its real 1.8 V supply instead of a dummy
   regulator.
3. The USB-C port gets DP Alt Mode: the FUSB302 connector advertises
   the DisplayPort alternate mode and the graph links the connector,
   the USBDP PHY and the DP0 controller. It uses only bindings already
   in mainline.

Tested on an Orange Pi 5 (RK3588S, PCB v1.2): with "rgmii-id" the link
comes up at 1000/Full and receives at 940 Mbit/s with no errors (with
"net: stmmac: dwmac-rk: only read the delays the MAC applies", sent
separately, the "Can not read property" warnings are gone too); the
regulator summary lists the flash supply under vcc_1v8_s3 and the dummy
regulator message is gone. With patch 3, a USB-C dock (DP-to-HDMI
converter, USB3 hub) enters DP Alt Mode in pin assignment D (2 lanes
HBR2) and its monitor runs at 3840x2160@30 next to HDMI at 4K60, pin
assignment D -> C -> D switches work, 100 of 100 attach cycles
configured DP Alt Mode, and the dock's USB3 devices keep working. The
driver stack used for that test carried the pending "USBDP PHY cleanup
part 3" and dw-dp HPD/Alt Mode patches; the description itself does
not depend on them. CHECK_DTBS is clean for both boards. The Orange
Pi 5B was not tested (no board at hand); it shares the changed .dtsi.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (3):
      arm64: dts: rockchip: use rgmii-id for the Orange Pi 5/5B ethernet PHY
      arm64: dts: rockchip: add the SPI NOR flash supply on Orange Pi 5
      arm64: dts: rockchip: Add USB-C DP AltMode for Orange Pi 5/5B

 .../boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi   | 92 +++++++++++++++++++---
 .../arm64/boot/dts/rockchip/rk3588s-orangepi-5.dts |  4 +
 2 files changed, 83 insertions(+), 13 deletions(-)
---
base-commit: c3baae5f1a15645cddadcb2b9abddef5df291f59
change-id: 20261110-opi5-dts-4b83491c6706

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

