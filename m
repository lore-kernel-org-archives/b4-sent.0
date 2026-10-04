From: Igor Velkov <iav@iav.lv>
Date: Sun, 04 Oct 2026 22:39:58 +0000
Subject: [PATCH] arm64: dts: rockchip: Add the battery charger to Kobol
 Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-helios64-dc-charger-v1-1-0eabf0274d47@iav.lv>
X-B4-Tracking: v=1; b=H4sIAL3VwmoC/x2MQQqAMAwEv1JyNtAWrehXxIO0sQZEJQURpH83C
 HMZmN0XCglTgdG8IHRz4fNQcY2BuC1HJuSkDt764KztcKOdzxJaTBG1kEyClGI7KEO0PejyElr
 5+V+nudYPz9yeUGUAAAA=
To: Heiko Stuebner <heiko@sntech.de>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2197; i=iav@iav.lv;
 h=from:subject:message-id; bh=DAhlfIUWqvGqD77K4GZRu5rOeDoaIBCJ6zw/SQS3zzI=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmHru7Lig//2vTZPf/F63ncxZ1qTC/Md11Zp3Lm0+k0w
 w++ArWWHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiLsoM/7OWJcyrnVq08Nm1
 lR9ZUift6rt/PSTI0cU++PmWY/8r36xiZNjWXfb2yb+pVWrX365/6X253ThbzUxTYn1y6QbRO7c
 fcbACAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Helios64 has a battery backup built around a BQ24133 charger. The
charger works on its own; the SoC only sees two status lines:

- VCC12V_DCIN_GOOD on GPIO0_A2, a divider from the 12 V input, high
  while the mains adapter powers the board;
- CHARGER_STATUS# on GPIO2_D3, the inverted STAT output of the charger,
  high while the battery is charging.

Describe them as a gpio-charger. Both lines have external resistors, so
the pins get no pull.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on 7.3-rc5: online follows the mains adapter, status reads
Charging while the battery recharges and Not charging once it is full.

Schematic, sheets 9, 15 and 29:
https://wiki.kobol.io/helios64/files/schematics/Helios64_Schematics_Rev1.2.pdf
---
 .../arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index d146e5075b4f..813a39964357 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -62,6 +62,15 @@ chosen {
 		stdout-path = "serial2:1500000n8";
 	};
 
+	dc-charger {
+		compatible = "gpio-charger";
+		charger-type = "mains";
+		gpios = <&gpio0 RK_PA2 GPIO_ACTIVE_HIGH>;
+		charge-status-gpios = <&gpio2 RK_PD3 GPIO_ACTIVE_HIGH>;
+		pinctrl-names = "default";
+		pinctrl-0 = <&dcin_good>, <&charger_status>;
+	};
+
 	clkin_gmac: external-gmac-clock {
 		compatible = "fixed-clock";
 		clock-frequency = <125000000>;
@@ -493,6 +502,16 @@ user1_btn: user1-btn {
 		};
 	};
 
+	charger {
+		charger_status: charger-status {
+			rockchip,pins = <2 RK_PD3 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		dcin_good: dcin-good {
+			rockchip,pins = <0 RK_PA2 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+	};
+
 	gmac {
 		gphy_reset: gphy-reset {
 			rockchip,pins = <3 RK_PB7 RK_FUNC_GPIO &pcfg_output_low>;

---
base-commit: 36bd12104f6e9462f6e97989fd8ef9eb1609623f
change-id: 20261005-helios64-dc-charger-edc49c499c07

Best regards,
-- 
Igor Velkov <iav@iav.lv>

