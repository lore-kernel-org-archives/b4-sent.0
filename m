From: Igor Velkov <iav@iav.lv>
Date: Fri, 16 Oct 2026 08:34:34 +0300
Subject: [PATCH 2/2] arm64: dts: rockchip: Describe the unused RK808
 outputs on Kobol Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-helios64-power-tree-v1-2-31d6c8dc5092@iav.lv>
References: <20261016-helios64-power-tree-v1-0-31d6c8dc5092@iav.lv>
In-Reply-To: <20261016-helios64-power-tree-v1-0-31d6c8dc5092@iav.lv>
To: Heiko Stuebner <heiko@sntech.de>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1855; i=iav@iav.lv;
 h=from:subject:message-id; bh=q+lERKCDnOjng4lQyfplDkXO0aaernq5BCDtZUzNjMI=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkXt2ffMj9gPDm6g7HyEbORruy0LcsZ/xyd/oBlpX55w
 gGj8zcKO0pZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBE7u5j+Ct2695OU5Uyfe9Y
 yxYbu7tTUrZdfOOlebPqg7zL2sc5mw4x/K+wOrNTMFNSSmNZlMPuXv5q9qX37bQF0i7nvfOVlz+
 whwMA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Helios64 schematic lists RK808 LDO_REG1, LDO_REG2, LDO_REG5,
LDO_REG7 and SWITCH_REG2 as unused (sheet 2). Each output has only a
0.1 uF capacitor and goes nowhere else (sheet 6).

Describe them with the names from the schematic and no constraints, so
the regulator core switches them off as unused.

Link: https://wiki.kobol.io/helios64/files/schematics/Helios64_Schematics_Rev1.2.pdf
Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 .../boot/dts/rockchip/rk3399-kobol-helios64.dts      | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index cf247d6c6212..35e92e1c8ff8 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -436,6 +436,14 @@ regulator-state-mem {
 				};
 			};
 
+			vcc1v8_dvp: LDO_REG1 {
+				regulator-name = "vcc1v8_dvp";
+			};
+
+			vcc3v0_touch: LDO_REG2 {
+				regulator-name = "vcc3v0_touch";
+			};
+
 			vcc1v8_s3: LDO_REG3 {
 				regulator-name = "vcc1v8_s3";
 				regulator-always-on;
@@ -462,6 +470,10 @@ regulator-state-mem {
 				};
 			};
 
+			vcca3v0_codec: LDO_REG5 {
+				regulator-name = "vcca3v0_codec";
+			};
+
 			vcc1v5_s3: LDO_REG6 {
 				regulator-name = "vcc1v5_s3";
 				regulator-always-on;
@@ -475,6 +487,10 @@ regulator-state-mem {
 				};
 			};
 
+			vcca1v8_codec: LDO_REG7 {
+				regulator-name = "vcca1v8_codec";
+			};
+
 			vcc3v0_s3: LDO_REG8 {
 				regulator-name = "vcc3v0_s3";
 				regulator-always-on;
@@ -497,6 +513,10 @@ regulator-state-mem {
 					regulator-off-in-suspend;
 				};
 			};
+
+			vcc3v3_s0: SWITCH_REG2 {
+				regulator-name = "vcc3v3_s0";
+			};
 		};
 	};
 

-- 
2.43.0

