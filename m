From: David Heidelberg <david@ixit.cz>
Date: Tue, 03 Mar 2026 20:52:29 +0100
Subject: [PATCH v3 3/4] arm64: dts: rockchip: Use reference PCIe clock
 generator for BPI-R2-Pro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260303-rk3568-bri-r2-pro-fix-pcie-v3-3-af5a5207b0a1@ixit.cz>
References: <20260303-rk3568-bri-r2-pro-fix-pcie-v3-0-af5a5207b0a1@ixit.cz>
In-Reply-To: <20260303-rk3568-bri-r2-pro-fix-pcie-v3-0-af5a5207b0a1@ixit.cz>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Frank Wunderlich <frank-w@public-files.de>
Cc: Martin Filla <freebsd@sysctl.cz>, 
 Charalampos Mitrodimas <charmitro@posteo.net>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3580; i=david@ixit.cz;
 h=from:subject:message-id; bh=ErDena6uQvd0JzFK1uxs+tYPpVApCktOwvCHIp0f9fM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppzv8NGkEODwhzAbXCqppzfwNaLpq0XZL0mqZd
 I/ZhEoi+d6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaac7/AAKCRBgAj/E00kg
 cv5LD/4qAWipALq+N7TdC2t3WCrg3REaLfx5ZbkwdflIivDNk0hv0MBM5PSkOXmM1hFF6d83DCG
 xuJ9ICz5bqUT9qOulKIzdjAWqBXO6GNT5x/eAIdWujRmITN7ik4Mj8x8KJW4go1yYecuYtfMGOG
 SHUyU5sWesQsJoM/JU/ENp2ov/fzE8/2bKjVZdmDBqrjJzfMUQFawjTwiE5+rB3Zs8fhJX2bc6D
 HzB2i6p77zRbU9iPjxCvaH39YB/X6GZbXMPIVUGvoqIiZaC55fmNCpMjJOJRiZaseuKaVwSqZzl
 /tfIvXpXSOenFcfmNeCZhEvQUYFzxp5t1BWag7/6kz9RqufdKEjKHaHwb3eDjqJSuBF1SbB9J+u
 VN9RbhHNAZ6VOvXmKwB9PkO6rM5a8Aom4wnSqA6/GrdNoT9AwhEIPjEcgm6cyXL9YkzVfMff+6x
 OhqL1rDqrJxl1qm/eU4l2UkfO03bEgL5DzEG7PxEFX8Dja1T5wmMtpFW9spl2xu5nnLyUC2mUE2
 2b0gMPZ/vdYsym0O7jfFQtIx2A2HHsGNVNwig2t+tl66iBL23ZQys2c5gQI/N4PvOI5C3AJty8/
 R8WfdceqAaweEoIpkF1kKynWnrU1dxhJ7I6CpJGyGy8mOES99XmY9ImDREXcKRKbMXdoJtG444C
 akzUKBzT/d/NbFg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe properly PCIe clock, which allows us correct the
toplogy (removing the vcc3v3-{minipcie,ngff} dependency on pi6c as
supply) and adding the clock dependency in the PCIe nodes.

Suggested-by: Heiko Stuebner <heiko@sntech.de>
Tested-by: Martin Filla <freebsd@sysctl.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts | 47 +++++++++++++++-------
 1 file changed, 33 insertions(+), 14 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts b/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
index d02b82c5f979a..3cdea9456a28c 100644
--- a/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
@@ -120,18 +120,13 @@ pcie_refclk_gen: pcie-refclk-gen-clock {
 		clock-frequency = <100000000>;
 	};
 
-	vcc3v3_pi6c_05: regulator-vcc3v3-pi6c-05 {
-		compatible = "regulator-fixed";
-		regulator-name = "vcc3v3_pcie";
-		regulator-min-microvolt = <3300000>;
-		regulator-max-microvolt = <3300000>;
-		enable-active-high;
-		gpios = <&gpio0 RK_PD4 GPIO_ACTIVE_HIGH>;
-		startup-delay-us = <200000>;
-		vin-supply = <&vcc5v0_sys>;
+	pcie_refclk: pcie-refclk-clock {
+		compatible = "gpio-gate-clock";
+		clocks = <&pcie_refclk_gen>;
+		#clock-cells = <0>;
+		enable-gpios = <&gpio0 RK_PD4 GPIO_ACTIVE_HIGH>;
 	};
 
-	/* actually fed by vcc3v3_sys, dependent on pi6c clock generator */
 	vcc3v3_minipcie: regulator-vcc3v3-minipcie {
 		compatible = "regulator-fixed";
 		regulator-name = "vcc3v3_minipcie";
@@ -142,10 +137,9 @@ vcc3v3_minipcie: regulator-vcc3v3-minipcie {
 		pinctrl-names = "default";
 		pinctrl-0 = <&minipcie_enable_h>;
 		startup-delay-us = <50000>;
-		vin-supply = <&vcc3v3_pi6c_05>;
+		vin-supply = <&vcc3v3_sys>;
 	};
 
-	/* actually fed by vcc3v3_sys, dependent on pi6c clock generator */
 	vcc3v3_ngff: regulator-vcc3v3-ngff {
 		compatible = "regulator-fixed";
 		regulator-name = "vcc3v3_ngff";
@@ -156,7 +150,7 @@ vcc3v3_ngff: regulator-vcc3v3-ngff {
 		pinctrl-names = "default";
 		pinctrl-0 = <&ngffpcie_enable_h>;
 		startup-delay-us = <50000>;
-		vin-supply = <&vcc3v3_pi6c_05>;
+		vin-supply = <&vcc3v3_sys>;
 	};
 
 	vcc5v0_usb: regulator-vcc5v0-usb {
@@ -586,12 +580,24 @@ rgmii_phy1: ethernet-phy@0 {
 
 &pcie30phy {
 	data-lanes = <1 2>;
-	phy-supply = <&vcc3v3_pi6c_05>;
+
 	status = "okay";
 };
 
 &pcie3x1 {
 	/* M.2 slot */
+	/*
+	 * The board has a gpio-controlled "pcie_refclk" generator,
+	 * so add it to the list of clocks.
+	 */
+	clocks = <&cru ACLK_PCIE30X1_MST>, <&cru ACLK_PCIE30X1_SLV>,
+		 <&cru ACLK_PCIE30X1_DBI>, <&cru PCLK_PCIE30X1>,
+		 <&cru CLK_PCIE30X1_AUX_NDFT>,
+		 <&cru CLK_PCIE30X1_PIPE_DFT>,
+		 <&pcie_refclk>;
+	clock-names = "aclk_mst", "aclk_slv",
+		      "aclk_dbi", "pclk", "aux",
+		      "pipe", "ref";
 	num-lanes = <1>;
 	pinctrl-names = "default";
 	pinctrl-0 = <&ngffpcie_reset_h>;
@@ -602,6 +608,19 @@ &pcie3x1 {
 
 &pcie3x2 {
 	/* mPCIe slot */
+	/*
+	 * The board has a gpio-controlled "pcie_refclk" generator,
+	 * so add it to the list of clocks.
+	 */
+	clocks = <&cru ACLK_PCIE30X2_MST>, <&cru ACLK_PCIE30X2_SLV>,
+		 <&cru ACLK_PCIE30X2_DBI>, <&cru PCLK_PCIE30X2>,
+		 <&cru CLK_PCIE30X2_AUX_NDFT>,
+		 <&cru CLK_PCIE30X2_PIPE_DFT>,
+		 <&pcie_refclk>;
+	clock-names = "aclk_mst", "aclk_slv",
+		      "aclk_dbi", "pclk", "aux",
+		      "pipe", "ref";
+
 	num-lanes = <1>;
 	pinctrl-names = "default";
 	pinctrl-0 = <&minipcie_reset_h>;

-- 
2.53.0

