From: Frank Li <Frank.Li@nxp.com>
Date: Fri, 15 May 2026 17:40:36 -0400
Subject: [PATCH 5/6] ARM: dts: imx: replace undocumented compatible string
 edt,edt-ft5x06 with edt,edt-ft5206
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-imx25_dts_simple_warning_2-v1-5-b06bff192a05@nxp.com>
References: <20260515-imx25_dts_simple_warning_2-v1-0-b06bff192a05@nxp.com>
In-Reply-To: <20260515-imx25_dts_simple_warning_2-v1-0-b06bff192a05@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778881235; l=9043;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=AOVw1M7zQlb65bw1DPrZXPBsg7v9jNLK9xQ41dQcIMo=;
 b=kpNTSLM5bkd6P4023vBkTiE890KlD7saNAmYXOZoF2JkCSxWi5OwN8ezRq0iPBT2D8prTbUDb
 2OVl82+qWQOAbLS5tDNSyMjKrVEbNmSfDAYQUiAc5m7MoMGgWIXQH8X
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The edt,edt-ft5x06 compatible is not referenced in
drivers/input/touchscreen/edt-ft5x06.c and is not documented.

There is no publicly available datasheet or binding information that
distinguishes edt-ft5206/ft5306/ft5406 variants and the driver treats these
FT5x06-family controllers with the same configuration model. So switch to
the lowest common and documented baseline compatible edt,edt-ft5206.

Fix below CHECK_DTBS warnings:
arch/arm/boot/dts/nxp/imx/imx53-m53menlo.dtb: /soc/bus@60000000/i2c@63fc8000/touchscreen@38: failed to match any schema with compatible: ['edt,edt-ft5x06']

ABI impact consideration:
Not affect Linux kernel ABI because edt,edt-ft5x06 is not used by the
existing driver. U-Boot does not parse or use edt,edt-ft* touchscreen
compatibles.

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
Change binding doc discuss at
- https://lore.kernel.org/imx/aasmQiZJO2gSKzNH@lizhi-Precision-Tower-5810/
---
 arch/arm/boot/dts/nxp/imx/imx53-m53menlo.dts           | 2 +-
 arch/arm/boot/dts/nxp/imx/imx53-tx53-x03x.dts          | 2 +-
 arch/arm/boot/dts/nxp/imx/imx6q-var-dt6customboard.dts | 2 +-
 arch/arm/boot/dts/nxp/imx/imx6qdl-nit6xlite.dtsi       | 2 +-
 arch/arm/boot/dts/nxp/imx/imx6qdl-nitrogen6_max.dtsi   | 2 +-
 arch/arm/boot/dts/nxp/imx/imx6qdl-nitrogen6x.dtsi      | 2 +-
 arch/arm/boot/dts/nxp/imx/imx6qdl-pico.dtsi            | 2 +-
 arch/arm/boot/dts/nxp/imx/imx6qdl-tx6.dtsi             | 2 +-
 arch/arm/boot/dts/nxp/imx/imx6ul-pico-hobbit.dts       | 2 +-
 arch/arm/boot/dts/nxp/imx/imx6ul-pico-pi.dts           | 2 +-
 arch/arm/boot/dts/nxp/imx/imx6ul-tx6ul.dtsi            | 2 +-
 arch/arm/boot/dts/nxp/imx/imx7d-pico-dwarf.dts         | 2 +-
 arch/arm/boot/dts/nxp/imx/imx7d-pico-pi.dts            | 2 +-
 13 files changed, 13 insertions(+), 13 deletions(-)

diff --git a/arch/arm/boot/dts/nxp/imx/imx53-m53menlo.dts b/arch/arm/boot/dts/nxp/imx/imx53-m53menlo.dts
index 2acbc86cabb3193f1b27b5de3155cf3d88381f49..aa1c7e5012c6af16e559c914777de476d6eab966 100644
--- a/arch/arm/boot/dts/nxp/imx/imx53-m53menlo.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx53-m53menlo.dts
@@ -248,7 +248,7 @@ &i2c1 {
 	status = "okay";
 
 	touchscreen@38 {
-		compatible = "edt,edt-ft5x06";
+		compatible = "edt,edt-ft5206";
 		reg = <0x38>;
 		pinctrl-names = "default";
 		pinctrl-0 = <&pinctrl_edt_ft5x06>;
diff --git a/arch/arm/boot/dts/nxp/imx/imx53-tx53-x03x.dts b/arch/arm/boot/dts/nxp/imx/imx53-tx53-x03x.dts
index 872cf7e16f20c923e7772e8def7df46276d683ef..6a1063c455f0c225c3d23ac4621c9957c95d491e 100644
--- a/arch/arm/boot/dts/nxp/imx/imx53-tx53-x03x.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx53-tx53-x03x.dts
@@ -201,7 +201,7 @@ sgtl5000: codec@a {
 	};
 
 	polytouch: edt-ft5x06@38 {
-		compatible = "edt,edt-ft5x06";
+		compatible = "edt,edt-ft5206";
 		reg = <0x38>;
 		pinctrl-names = "default";
 		pinctrl-0 = <&pinctrl_edt_ft5x06_1>;
diff --git a/arch/arm/boot/dts/nxp/imx/imx6q-var-dt6customboard.dts b/arch/arm/boot/dts/nxp/imx/imx6q-var-dt6customboard.dts
index 0225a621ec7a9e697ba95cf0617513156f8c521f..ccf6a048c9184c95105231f50acd96038ab353d9 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6q-var-dt6customboard.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx6q-var-dt6customboard.dts
@@ -169,7 +169,7 @@ &i2c3 {
 	status = "okay";
 
 	touchscreen@38 {
-		compatible = "edt,edt-ft5x06";
+		compatible = "edt,edt-ft5206";
 		reg = <0x38>;
 		interrupt-parent = <&gpio1>;
 		interrupts = <4 IRQ_TYPE_EDGE_FALLING>;
diff --git a/arch/arm/boot/dts/nxp/imx/imx6qdl-nit6xlite.dtsi b/arch/arm/boot/dts/nxp/imx/imx6qdl-nit6xlite.dtsi
index 610b2a72fe82557c51fbad1bfff65154540e2279..cebfd622df688ecd01cecc0621d1ed23512da007 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6qdl-nit6xlite.dtsi
+++ b/arch/arm/boot/dts/nxp/imx/imx6qdl-nit6xlite.dtsi
@@ -256,7 +256,7 @@ touchscreen@4 {
 	};
 
 	touchscreen@38 {
-		compatible = "edt,edt-ft5x06";
+		compatible = "edt,edt-ft5206";
 		reg = <0x38>;
 		interrupt-parent = <&gpio1>;
 		interrupts = <9 IRQ_TYPE_EDGE_FALLING>;
diff --git a/arch/arm/boot/dts/nxp/imx/imx6qdl-nitrogen6_max.dtsi b/arch/arm/boot/dts/nxp/imx/imx6qdl-nitrogen6_max.dtsi
index ef0c26688446ef5a92c94f553ab900ae4e5fdcfb..f8a7218b13ef20675c0e9b7af1f56c0b7bcc2b11 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6qdl-nitrogen6_max.dtsi
+++ b/arch/arm/boot/dts/nxp/imx/imx6qdl-nitrogen6_max.dtsi
@@ -405,7 +405,7 @@ touchscreen@4 {
 	};
 
 	touchscreen@38 {
-		compatible = "edt,edt-ft5x06";
+		compatible = "edt,edt-ft5206";
 		reg = <0x38>;
 		interrupt-parent = <&gpio1>;
 		interrupts = <9 IRQ_TYPE_EDGE_FALLING>;
diff --git a/arch/arm/boot/dts/nxp/imx/imx6qdl-nitrogen6x.dtsi b/arch/arm/boot/dts/nxp/imx/imx6qdl-nitrogen6x.dtsi
index 6a353a99e13daa2f13ba91d7311f60c88b40695b..9fe52e0ca7aa24379ad11c62236d586885242aa0 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6qdl-nitrogen6x.dtsi
+++ b/arch/arm/boot/dts/nxp/imx/imx6qdl-nitrogen6x.dtsi
@@ -333,7 +333,7 @@ touchscreen@4 {
 	};
 
 	touchscreen@38 {
-		compatible = "edt,edt-ft5x06";
+		compatible = "edt,edt-ft5206";
 		reg = <0x38>;
 		interrupt-parent = <&gpio1>;
 		interrupts = <9 IRQ_TYPE_EDGE_FALLING>;
diff --git a/arch/arm/boot/dts/nxp/imx/imx6qdl-pico.dtsi b/arch/arm/boot/dts/nxp/imx/imx6qdl-pico.dtsi
index c39a9ebdaba1c56b7422c1beb77ba9ddd502609f..ca4cb986efbc204a4ccc8b4d3eb035f4b3504dcd 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6qdl-pico.dtsi
+++ b/arch/arm/boot/dts/nxp/imx/imx6qdl-pico.dtsi
@@ -217,7 +217,7 @@ &i2c2 {
 	status = "okay";
 
 	touchscreen@38 {
-		compatible = "edt,edt-ft5x06";
+		compatible = "edt,edt-ft5206";
 		reg = <0x38>;
 		interrupt-parent = <&gpio5>;
 		interrupts = <31 IRQ_TYPE_EDGE_FALLING>;
diff --git a/arch/arm/boot/dts/nxp/imx/imx6qdl-tx6.dtsi b/arch/arm/boot/dts/nxp/imx/imx6qdl-tx6.dtsi
index ec1528ff3ea0146157a56f2ecba500e651f857ff..fe25934e06b1fea9bc2b16cb53c24a11ca0525f9 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6qdl-tx6.dtsi
+++ b/arch/arm/boot/dts/nxp/imx/imx6qdl-tx6.dtsi
@@ -292,7 +292,7 @@ sgtl5000: sgtl5000@a {
 	};
 
 	polytouch: edt-ft5x06@38 {
-		compatible = "edt,edt-ft5x06";
+		compatible = "edt,edt-ft5206";
 		reg = <0x38>;
 		pinctrl-names = "default";
 		pinctrl-0 = <&pinctrl_edt_ft5x06>;
diff --git a/arch/arm/boot/dts/nxp/imx/imx6ul-pico-hobbit.dts b/arch/arm/boot/dts/nxp/imx/imx6ul-pico-hobbit.dts
index bf7dbb4f1f3ed99a9b9cff76e052bd1d9aa8bafe..e99ba04216b8670173bed60b98f0011b423b23aa 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6ul-pico-hobbit.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx6ul-pico-hobbit.dts
@@ -62,7 +62,7 @@ &i2c3 {
 	status = "okay";
 
 	polytouch: touchscreen@38 {
-		compatible = "edt,edt-ft5x06";
+		compatible = "edt,edt-ft5206";
 		reg = <0x38>;
 		interrupt-parent = <&gpio1>;
 		interrupts = <29 IRQ_TYPE_EDGE_FALLING>;
diff --git a/arch/arm/boot/dts/nxp/imx/imx6ul-pico-pi.dts b/arch/arm/boot/dts/nxp/imx/imx6ul-pico-pi.dts
index 6cfc943a8fa3ee4452244bf4198d65a319453d66..f79090fb2e6e2e7bfe886d67f45df06923bb96ac 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6ul-pico-pi.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx6ul-pico-pi.dts
@@ -65,7 +65,7 @@ &i2c3 {
 	status = "okay";
 
 	polytouch: touchscreen@38 {
-		compatible = "edt,edt-ft5x06";
+		compatible = "edt,edt-ft5206";
 		reg = <0x38>;
 		interrupt-parent = <&gpio1>;
 		interrupts = <29 IRQ_TYPE_EDGE_FALLING>;
diff --git a/arch/arm/boot/dts/nxp/imx/imx6ul-tx6ul.dtsi b/arch/arm/boot/dts/nxp/imx/imx6ul-tx6ul.dtsi
index 1992dfb53b45cd308522c3e922d5758f5b8fe527..192c6a95ae589f491473a92277e38ad1d4c7b23c 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6ul-tx6ul.dtsi
+++ b/arch/arm/boot/dts/nxp/imx/imx6ul-tx6ul.dtsi
@@ -317,7 +317,7 @@ sgtl5000: codec@a {
 	};
 
 	polytouch: polytouch@38 {
-		compatible = "edt,edt-ft5x06";
+		compatible = "edt,edt-ft5206";
 		reg = <0x38>;
 		pinctrl-names = "default";
 		pinctrl-0 = <&pinctrl_edt_ft5x06>;
diff --git a/arch/arm/boot/dts/nxp/imx/imx7d-pico-dwarf.dts b/arch/arm/boot/dts/nxp/imx/imx7d-pico-dwarf.dts
index 347dd0fe4f82e00ff5fa57487f3333d61c4b27c5..fca8aab9d850791d5df1569a9a3ef4301bd0503c 100644
--- a/arch/arm/boot/dts/nxp/imx/imx7d-pico-dwarf.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx7d-pico-dwarf.dts
@@ -70,7 +70,7 @@ pca9554: io-expander@25 {
 	};
 
 	touchscreen@38 {
-		compatible = "edt,edt-ft5x06";
+		compatible = "edt,edt-ft5206";
 		reg = <0x38>;
 		pinctrl-names = "default";
 		pinctrl-0 = <&pinctrl_touchscreen>;
diff --git a/arch/arm/boot/dts/nxp/imx/imx7d-pico-pi.dts b/arch/arm/boot/dts/nxp/imx/imx7d-pico-pi.dts
index 62221131336f12b9233474496888e0d34631765b..673bbe49de52500a9218fb06c4212a5a4238d677 100644
--- a/arch/arm/boot/dts/nxp/imx/imx7d-pico-pi.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx7d-pico-pi.dts
@@ -49,7 +49,7 @@ sgtl5000: codec@a {
 
 &i2c4 {
 	polytouch: touchscreen@38 {
-		compatible = "edt,edt-ft5x06";
+		compatible = "edt,edt-ft5206";
 		reg = <0x38>;
 		pinctrl-names = "default";
 		pinctrl-0 = <&pinctrl_touchscreen>;

-- 
2.43.0

