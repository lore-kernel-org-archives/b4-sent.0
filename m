From: Ricardo Pardini <ricardo@pardini.net>
Date: Fri, 05 Jun 2026 13:54:35 +0200
Subject: [PATCH] arm64: dts: rockchip: fix regulator names on NanoPC-T6
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-rk3588-dts-rockchip-nanopct6-fix-schematic-names-v1-1-15dd3b23ab1a@pardini.net>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNQQrCMBBFr1Jm7UCaYhu8irhIJ1MzlqYlE0Uov
 btRl+/zeW8H5SyscGl2yPwSlTVVaE8NUPTpziihMlhje9ObDvPcnZ3DUBTzSjNF2TD5tG5Uepz
 kjUqRF1+E6rywom9HF+wwOcsDVO2Wud5+yevtz/ocH0zl24Hj+AC4kf6rlAAAAA==
X-Change-ID: 20260603-rk3588-dts-rockchip-nanopct6-fix-schematic-names-a1b8d27f82e7
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4043; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=kgSZTfQ3v8bdt151HvlymrV22R4yaefcQJY9/TyNagE=;
 b=owEBiQF2/pANAwAIATteP+Oex+3pAcsmYgBqIrkCKjjYJPyA0jamo3cGmC4t1a33loZ4y4QVl
 8IxJe1nsWOJAU8EAAEIADkWIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaiK5AhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQO14/457H7enpNwf7BYfuQLgrCLiVvn1YHpmkizBLJrhd1kQ
 78tWZjq4WLqeGryGR/BFiSoyZ0dsYH9tdah9Cz4MPpsLn5RvLv2rKUTRm8Ucy4kEKkijZ5aDytg
 dC7lzmx9l3iMXLbR0q80dUcn4oTRxcW4TZ8WY2MvqOccfl2C+EkQOPVhKRoEzdMCF3XbrBrnnCN
 moTgXuQQ2hDscxrEEsu+eveq2jK3jDfZwNxtmIqC8ZfW7Tv92e9Jai5hJBK5kDvoi5cnIfroKI0
 aEDi6Pp4MNYQU6NLEfnjz+FPHQOKzD4dXbouQAjB1V8hFppyve5pPhcEytS98D5oXjx1RfsrFLp
 wTJyfKLfHLw==
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three fixed-regulator names on the NanoPC-T6 don't match the board
schematic [1].

- vcc3v3_pcie2x1l0 -> vdd_mpcie_3v3
  This GPIO-switched 3v3 regulator is labeled vcc3v3_pcie2x1l0, but
  it is wired to and consumed by &pcie2x1l1. Per the schematic,
  the GPIO PCIE_M2_1_PWREN controls the power net VDD_MPCIE_3.3V;
  rename to match.
- vdd_2v0_pldo_s3 -> vcc_2v0_pldo_s3
  Typo in the regulator-name property of RK806-1 DCDC reg7. The node
  label and the schematic power-net name both already use the vcc_
  form; only the regulator-name string had vdd_.
- vcc3v3_pcie30 -> vcc3v3_pcie_m2_0
  The GPIO-switched 3v3 feeding the M.2 M-Key (NVMe) slot is named
  after the PCIe controller it sits behind rather than the schematic
  power net. The schematic names it VCC3V3_PCIE_M2_0 (produced by an
  MP2143-based buck off VCC_5V0, enabled by PCIE_M2_0_PWREN); rename
  to match.

No functional change.

[1] https://wiki.friendlyelec.com/wiki/images/9/97/NanoPC-T6_2301_SCH.PDF

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
Align three fixed-regulator names on the NanoPC-T6 (and LTS) with
the labels used in the board schematic: the mini-PCIe 3v3 regulator
(whose current name is actively misleading), a vdd_/vcc_ typo on
RK806-1 DCDC reg7, and the M.2 M-Key 3v3 supply (named after the
PCIe controller rather than the schematic power net).

Using actual schematic names was pointed out by Sebastian during
review of an earlier (and mostly unrelated) series [1].

No functional change.

[1] https://lore.kernel.org/linux-rockchip/ah2AYT4XmYR03I7z@venus/
---
 arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
index 84b6b53f016ab..b44aff39cb32e 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
@@ -201,25 +201,25 @@ vbus5v0_usb: regulator-vbus5v0-usb {
 		vin-supply = <&vcc5v0_sys>;
 	};
 
-	vcc3v3_pcie2x1l0: regulator-vcc3v3-pcie2x1l0 {
+	vdd_mpcie_3v3: regulator-vdd-mpcie-3v3 {
 		compatible = "regulator-fixed";
 		enable-active-high;
 		gpio = <&gpio4 RK_PC2 GPIO_ACTIVE_HIGH>;
 		pinctrl-names = "default";
 		pinctrl-0 = <&pcie_m2_1_pwren>;
-		regulator-name = "vcc3v3_pcie2x1l0";
+		regulator-name = "vdd_mpcie_3v3";
 		regulator-min-microvolt = <3300000>;
 		regulator-max-microvolt = <3300000>;
 		vin-supply = <&vcc5v0_sys>;
 	};
 
-	vcc3v3_pcie30: regulator-vcc3v3-pcie30 {
+	vcc3v3_pcie_m2_0: regulator-vcc3v3-pcie-m2-0 {
 		compatible = "regulator-fixed";
 		enable-active-high;
 		gpios = <&gpio2 RK_PC5 GPIO_ACTIVE_HIGH>;
 		pinctrl-names = "default";
 		pinctrl-0 = <&pcie_m2_0_pwren>;
-		regulator-name = "vcc3v3_pcie30";
+		regulator-name = "vcc3v3_pcie_m2_0";
 		regulator-min-microvolt = <3300000>;
 		regulator-max-microvolt = <3300000>;
 		vin-supply = <&vcc5v0_sys>;
@@ -639,7 +639,7 @@ &pcie2x1l0 {
 
 &pcie2x1l1 {
 	reset-gpios = <&gpio4 RK_PA2 GPIO_ACTIVE_HIGH>;
-	vpcie3v3-supply = <&vcc3v3_pcie2x1l0>;
+	vpcie3v3-supply = <&vdd_mpcie_3v3>;
 	pinctrl-names = "default";
 	pinctrl-0 = <&pcie2_1_rst>;
 	status = "okay";
@@ -659,7 +659,7 @@ &pcie30phy {
 
 &pcie3x4 {
 	reset-gpios = <&gpio4 RK_PB6 GPIO_ACTIVE_HIGH>;
-	vpcie3v3-supply = <&vcc3v3_pcie30>;
+	vpcie3v3-supply = <&vcc3v3_pcie_m2_0>;
 	status = "okay";
 };
 
@@ -965,7 +965,7 @@ vcc_2v0_pldo_s3: dcdc-reg7 {
 				regulator-min-microvolt = <2000000>;
 				regulator-max-microvolt = <2000000>;
 				regulator-ramp-delay = <12500>;
-				regulator-name = "vdd_2v0_pldo_s3";
+				regulator-name = "vcc_2v0_pldo_s3";
 
 				regulator-state-mem {
 					regulator-on-in-suspend;

---
base-commit: e43ffb69e0438cddd72aaa30898b4dc446f664f8
change-id: 20260603-rk3588-dts-rockchip-nanopct6-fix-schematic-names-a1b8d27f82e7

Best regards,
--  
Ricardo Pardini <ricardo@pardini.net>

