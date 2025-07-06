From: Frank Li <Frank.Li@nxp.com>
Date: Sun, 06 Jul 2025 14:46:59 -0400
Subject: [PATCH 03/11] ARM: dts: lpc4350-hitex-eval: change node name flash
 to flash@0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250706-lpc18xxx_dts-v1-3-7ae8cdfe8d7d@nxp.com>
References: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
In-Reply-To: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vladimir Zapolskiy <vz@mleia.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, vz@mleia.com, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751827628; l=2299;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=kvKeu0uSL6H9Hui96OrSfKpctNLAKlofzyW2bVVv/us=;
 b=DmxS+F+3f/HV99/JI5dVWvAPzHZmvs9RZBdcB6bZxK7BpzRNWq/oaa6MaGA5njXoJkS+Jmurj
 kKzC2N09XRbDa5xHksZKRuzpSVj3WqhMGYIlpHDpX2G4Wbg0MCfv7Mn
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change node name 'flash' to 'flash@0' to fix below CHECK_DTB warnings.
arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dtb: flash-controller@40003000 (nxp,lpc1773-spifi): Unevaluated properties are not allowed ('flash' was unexpected)
        from schema $id: http://devicetree.org/schemas/mtd/nxp,lpc1773-spifi.yaml#

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts    | 3 ++-
 arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts | 3 ++-
 arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts   | 3 ++-
 3 files changed, 6 insertions(+), 3 deletions(-)

diff --git a/arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts b/arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts
index 93d0c2e99e7ced638adbfc8bfccd47d17bbb89e8..8fc89fb6eef1e839ad256ae33942e607fed862c6 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts
+++ b/arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts
@@ -451,8 +451,9 @@ &spifi {
 	pinctrl-names = "default";
 	pinctrl-0 = <&spifi_pins>;
 
-	flash {
+	flash@0 {
 		compatible = "jedec,spi-nor";
+		reg = <0>;
 		spi-rx-bus-width = <4>;
 		#address-cells = <1>;
 		#size-cells = <1>;
diff --git a/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts b/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts
index 4aefbc01dfc0fe7abbf87a8cdd0d8da179aae3d5..60bcfa5e0518e55eb3e642f146d1c96f2ebd5267 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts
+++ b/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts
@@ -582,8 +582,9 @@ &spifi {
 	pinctrl-names = "default";
 	pinctrl-0 = <&spifi_pins>;
 
-	flash {
+	flash@0 {
 		compatible = "jedec,spi-nor";
+		reg = <0>;
 		spi-cpol;
 		spi-cpha;
 		spi-rx-bus-width = <4>;
diff --git a/arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts b/arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts
index 846afb8ccbf1de08cccaf445106beeeddee93454..22f7dd671c90d56cc4295151583fd4135c8b707b 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts
+++ b/arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts
@@ -569,8 +569,9 @@ &spifi {
 	pinctrl-0 = <&spifi_pins>;
 
 	/* Atmel AT25DF321A */
-	flash {
+	flash@0 {
 		compatible = "jedec,spi-nor";
+		reg = <0>;
 		spi-max-frequency = <51000000>;
 		spi-cpol;
 		spi-cpha;

-- 
2.34.1

