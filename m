From: Igor Velkov <iav@iav.lv>
Date: Fri, 16 Oct 2026 08:34:33 +0300
Subject: [PATCH 1/2] arm64: dts: rockchip: Describe more of the power tree
 on Kobol Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-helios64-power-tree-v1-1-31d6c8dc5092@iav.lv>
References: <20261016-helios64-power-tree-v1-0-31d6c8dc5092@iav.lv>
In-Reply-To: <20261016-helios64-power-tree-v1-0-31d6c8dc5092@iav.lv>
To: Heiko Stuebner <heiko@sntech.de>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3722; i=iav@iav.lv;
 h=from:subject:message-id; bh=8ZjlctZruWiHyaCJNzcvo71K9qLA5V8M8d4dh5Ckn8g=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkXt2fdmxnxeLKiXNIWuwOPLnT9kJh0ud/Mv8FixdlGw
 YPpCUbvOkpZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBE9G4wMmxoy/xw2qI804Rl
 RtSPJXLFz8QTWp4X/1w9J+rZhry1WtcY/pf839Zewv7msmGI7CyGA2ZPr7A05ex4ke775OefqQ+
 eWzMBAA==
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
supplies stay without a consumer.

Link: https://wiki.kobol.io/helios64/files/schematics/Helios64_Schematics_Rev1.2.pdf
Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 .../boot/dts/rockchip/rk3399-kobol-helios64.dts    | 63 ++++++++++++++++++++++
 1 file changed, 63 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index 63ad79b4c8ac..cf247d6c6212 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -178,6 +178,16 @@ usblan_power: regulator-usblan-power {
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
@@ -215,6 +225,16 @@ regulator-state-mem {
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
@@ -271,6 +291,16 @@ vcc12v_dcin_bkup: regulator-vcc12v-dcin-bkup {
 		regulator-max-microvolt = <12000000>;
 		vin-supply = <&vcc12v_dcin>;
 	};
+
+	vcc12v_hdd: regulator-vcc12v-hdd {
+		compatible = "regulator-fixed";
+		regulator-name = "vcc12v_hdd";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <12000000>;
+		regulator-max-microvolt = <12000000>;
+		vin-supply = <&vcc12v_dcin_bkup>;
+	};
 };
 
 /*
@@ -383,6 +413,16 @@ regulator-state-mem {
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
@@ -422,6 +462,19 @@ regulator-state-mem {
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
@@ -434,6 +487,16 @@ regulator-state-mem {
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
 

-- 
2.43.0

