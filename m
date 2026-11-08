From: Igor Velkov <iav@iav.lv>
Date: Sun, 08 Nov 2026 23:00:18 +0000
Subject: [PATCH v2] arm64: dts: rockchip: Describe more of the power tree
 on Kobol Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-helios64-power-tree-v2-1-639ac2fc5ad7@iav.lv>
X-B4-Tracking: v=1; b=H4sIAAH/8GoC/32NQQrCMBBFr1Jm7UgSm7G68h7SRUlGO1CakpSol
 Nzd2AO4fA/++xskjsIJrs0GkbMkCXMFc2jAjcP8ZBRfGYwypJUmHHmSkKjFJbw44hqZ0Z5NR61
 zTJagLpfID3nv1XtfeZS0hvjZT7L+2f+9rFHhSXtynXdWXcxNhnycMvSllC+R/i/yswAAAA==
To: Heiko Stuebner <heiko@sntech.de>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4317; i=iav@iav.lv;
 h=from:subject:message-id; bh=q4DkBQaFCKCe8qKMF/toFq0OPupIRXkfyB7nLuL7qmg=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkf/jNbv11+JHHf5IcVenLHrfkWbXvKM6fu6otn6re47
 hhb7PZm7yhlYRDjYpAVU2SZcEjjVsaSq3/9PcwfwMxhZQIZwsDFKQATMXdmZLhp+/n4ZovfUQLr
 S1jc1h1UMs2+E/CnvTLz+ns9MT8nOzOGf5rWPOxn5h2cZJ/hJfKn7fmXe+FnueI+vN9Zuck1eUr
 aUwYA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the regulators that the Helios64 schematic shows and the device
tree does not describe yet:

- RK808 DCDC_REG3 vcc_ddr_s3, LDO_REG6 vcc1v5_s3 and SWITCH_REG1
  vcc3v3_sys_s0 (sheet 6),
- the fixed 0.9 V regulator vcc0v9_s3, fed from vcc3v3_sys_s3 (sheet 8),
- the hard disk supplies vcc5v0_hdd and vcc12v_hdd, fed from
  vcc12v_dcin_bkup (sheets 4 and 9).

The hdd_a_power and hdd_b_power switches each take both vcc5v0_hdd and
vcc12v_hdd (sheet 5). A regulator has one vin-supply, so the two disk
supplies stay without a consumer. They feed the disks through those
switches.

Link: https://wiki.kobol.io/helios64/files/schematics/Helios64_Schematics_Rev1.2.pdf
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on Helios64 with a 7.3-rc7 kernel, on v1 of this patch; the DTS
hunks are unchanged in v2. All six regulators register, and the disks
and Ethernet work.
---
Changes in v2:
- Drop patch 2 (unused RK808 outputs) after Chen-Yu Tsai's remark.
- Rebase on for-next.
- Link to v1: https://lore.kernel.org/r/20261016-helios64-power-tree-v1-0-31d6c8dc5092@iav.lv
---
 .../boot/dts/rockchip/rk3399-kobol-helios64.dts    | 63 ++++++++++++++++++++++
 1 file changed, 63 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index f13ea2df7a30..61e50c3e7ef2 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -248,6 +248,16 @@ usblan_power: regulator-usblan-power {
 		vin-supply = <&vcc5v0_usb>;
 	};
 
+	vcc0v9_s3: regulator-vcc0v9-s3 {
+		compatible = "regulator-fixed";
+		regulator-name = "vcc0v9_s3";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <900000>;
+		regulator-max-microvolt = <900000>;
+		vin-supply = <&vcc3v3_sys_s3>;
+	};
+
 	vcc1v8_sys_s0: regulator-vcc1v8-sys-s0 {
 		compatible = "regulator-fixed";
 		regulator-name = "vcc1v8_sys_s0";
@@ -285,6 +295,16 @@ regulator-state-mem {
 		};
 	};
 
+	vcc5v0_hdd: regulator-vcc5v0-hdd {
+		compatible = "regulator-fixed";
+		regulator-name = "vcc5v0_hdd";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <5000000>;
+		regulator-max-microvolt = <5000000>;
+		vin-supply = <&vcc12v_dcin_bkup>;
+	};
+
 	vcc5v0_perdev: regulator-vcc5v0-perdev {
 		compatible = "regulator-fixed";
 		regulator-name = "vcc5v0_perdev";
@@ -342,6 +362,16 @@ vcc12v_dcin_bkup: regulator-vcc12v-dcin-bkup {
 		vin-supply = <&vcc12v_dcin>;
 	};
 
+	vcc12v_hdd: regulator-vcc12v-hdd {
+		compatible = "regulator-fixed";
+		regulator-name = "vcc12v_hdd";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <12000000>;
+		regulator-max-microvolt = <12000000>;
+		vin-supply = <&vcc12v_dcin_bkup>;
+	};
+
 	vdd_log: regulator-vdd-log {
 		compatible = "pwm-regulator";
 		pwms = <&pwm2 0 25000 1>;
@@ -479,6 +509,16 @@ regulator-state-mem {
 				};
 			};
 
+			vcc_ddr_s3: DCDC_REG3 {
+				regulator-name = "vcc_ddr_s3";
+				regulator-always-on;
+				regulator-boot-on;
+
+				regulator-state-mem {
+					regulator-on-in-suspend;
+				};
+			};
+
 			vcc1v8_sys_s3: DCDC_REG4 {
 				regulator-name = "vcc1v8_sys_s3";
 				regulator-always-on;
@@ -518,6 +558,19 @@ regulator-state-mem {
 				};
 			};
 
+			vcc1v5_s3: LDO_REG6 {
+				regulator-name = "vcc1v5_s3";
+				regulator-always-on;
+				regulator-boot-on;
+				regulator-min-microvolt = <1500000>;
+				regulator-max-microvolt = <1500000>;
+
+				regulator-state-mem {
+					regulator-on-in-suspend;
+					regulator-suspend-microvolt = <1500000>;
+				};
+			};
+
 			vcc3v0_s3: LDO_REG8 {
 				regulator-name = "vcc3v0_s3";
 				regulator-always-on;
@@ -530,6 +583,16 @@ regulator-state-mem {
 					regulator-suspend-microvolt = <3000000>;
 				};
 			};
+
+			vcc3v3_sys_s0: SWITCH_REG1 {
+				regulator-name = "vcc3v3_sys_s0";
+				regulator-always-on;
+				regulator-boot-on;
+
+				regulator-state-mem {
+					regulator-off-in-suspend;
+				};
+			};
 		};
 	};
 

---
base-commit: c3baae5f1a15645cddadcb2b9abddef5df291f59
change-id: 20261016-helios64-power-tree-572864cce656

Best regards,
-- 
Igor Velkov <iav@iav.lv>

