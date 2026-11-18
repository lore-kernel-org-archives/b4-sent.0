From: Igor Velkov <iav@iav.lv>
Date: Wed, 18 Nov 2026 23:01:05 +0000
Subject: [PATCH] arm64: dts: rockchip: Keep the PCIe power of Kobol
 Helios64 on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-helios64-pcie-always-on-v1-1-b77dcf4f01b4@iav.lv>
X-B4-Tracking: v=1; b=H4sIADAu/moC/x3MywqEMAxA0V+RrA00ZaiPXxEXHSeOAWmlAR8U/
 93i8izuzaCchBX6KkPiXVRiKKC6gmnx4c8ov2KwxjoianHhVaK6D26TMPr18JdiDOiNpe/cGNe
 1DZR6SzzL+Z6H8b4f+VBGr2kAAAA=
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1592; i=iav@iav.lv;
 h=from:subject:message-id; bh=csC4RQd6YR8LhC4D4T+ae3/8hKPMoykDjDiK28IYahI=;
 b=kA0DAAoWMpeVi+pfeQMByyZiAGr+LjGjXuGgGi0NcgRJibYyX3z3oA2z4fntgBZHDpxaGAz22
 Yh1BAAWCgAdFiEEkMIo2mik1f1PSDfgMpeVi+pfeQMFAmr+LjEACgkQMpeVi+pfeQOdGQEAixzq
 JcOSwoAS3wZZDLkOiE1x//+RWLpYCBczjYcLrKcBAJYJLXShTf5deewKTgzhNeB8iCyJzBXRINC
 Jv3xurRoD
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The JMB585 SATA controller needs PERST# high for about 60 ms after its
supply comes up. If PERST# is low at power-on, the chip stays dead
until the next power cycle.

At boot pcie_power is already on and PERST# is pulled high, so the
driver only pulses PERST# on a running chip. On unbind the driver
switches pcie_power off; on bind it asserts PERST# before it switches
the supply back on, and the link never trains (LTSSM in Detect.Active).

Keep pcie_power on, so that a rebind resets the chip the way boot does.

Tested with unbind/bind of the controller on v7.4-rc2 (plus the pending
rockchip-host link retry patch, which did not trigger): 0 of 4 attempts
without this change, 8 of 8 with it.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index 76beac38699f..aba8a0c87edb 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -230,6 +230,7 @@ pcie_power: regulator-pcie-power {
 		gpio = <&gpio1 RK_PD0 GPIO_ACTIVE_HIGH>;
 		pinctrl-0 = <&pcie_pwr>;
 		pinctrl-names = "default";
+		regulator-always-on;
 		regulator-boot-on;
 		regulator-name = "pcie_power";
 		startup-delay-us = <10000>;

---
base-commit: a9d78db32fe78bdbe7c66ba77cb7dbb729b885de
change-id: 20261118-helios64-pcie-always-on-a021bf706987

Best regards,
-- 
Igor Velkov <iav@iav.lv>

