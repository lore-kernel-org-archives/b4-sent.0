From: Amit Sunil Dhamne <amitsd@google.com>
Date: Sat, 19 Sep 2026 01:04:10 +0000
Subject: [PATCH v3] arm64: dts: exynos: gs101-pixel-common: add supply and
 regulator properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260919-max77759-charger-dts-v3-1-78b68fbf7d4a@google.com>
X-B4-Tracking: v=1; b=H4sIAInfrWoC/43NwQ7CIAyA4VcxnK3ZCozhyfcwHpBVRuKGgYXML
 Ht32W6e9Pi36deFJYqeEjsfFhYp++TDWIIfD8z2ZnQEvivNsMKmQhQwmFkpJTWUdXQUoZsSIBe
 ac92SUpaV01ekh5939nor3fs0hfjev+R6m/4Acw013IXgUkhbCWMuLgT3pJMNA9vEjP8oWBTdc
 myksS01/EtZ1/UDH3S0sP8AAAA=
X-Change-ID: 20260224-max77759-charger-dts-23493398e77c
To: Peter Griffin <peter.griffin@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789779853; l=2698;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=H3o0xNkJTaPRJts1fDtzq2bsFqrsr68JNgCV5PXC4hE=;
 b=WDzv0jaKgpSBLo/lEduuK+4j/pX+X87tGgx6bpqVRhUSPl1/NMl8e1FF7uY8ghZGnB15jdeUE
 wRo9yz4Y3bnC57nOsWQmWSHaS5w6zxRHV/l4ri4qmMYDTx/WYIwLL2f
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power supply and regulator properties to the MAX77759 pmic. The
usb-typec device will reference the regulator provided by the pmic as
it supplies vbus to the typec device when operating in source mode.

Additionally, describe the charging path as well. The pmic draws its
input from the Type-C port and in turn charges the battery that the
fuel gauge measures, which gives the full ladder:

  usb-typec@25  ->  pmic@66  ->  fuel-gauge@36

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
Changes in v3:
- Additionally describe the charging path from max77759_pmic to the
  fuel-gauge.
- Dropped André's Reviewed-by, as the patch grew a property.
- Link to v2: https://lore.kernel.org/r/20260224-max77759-charger-dts-v2-1-983265ac8e63@google.com

Changes in v2:
- Added a line between property and child node as per DTS coding std.
  (Krzysztof Kozlowski)
- Added the "power-supplies" property immediately after the prev
  property without leaving a line space.
- Link to v1: https://lore.kernel.org/r/20260224-max77759-charger-dts-v1-1-b443545c04aa@google.com
---
 arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi b/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
index a12f2b88d72d..c366df36380b 100644
--- a/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
+++ b/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
@@ -646,12 +646,13 @@ &hsi2c_12 {
 	status = "okay";
 	/* TODO: add the devices once drivers exist */
 
-	usb-typec@25 {
+	maxtcpci: usb-typec@25 {
 		compatible = "maxim,max77759-tcpci", "maxim,max33359";
 		reg = <0x25>;
 		interrupts-extended = <&gpa8 2 IRQ_TYPE_LEVEL_LOW>;
 		pinctrl-0 = <&typec_int>;
 		pinctrl-names = "default";
+		vbus-supply = <&chgin_otg_reg>;
 
 		connector {
 			compatible = "usb-c-connector";
@@ -738,9 +739,10 @@ fuel-gauge@36 {
 		interrupts-extended = <&gpa9 3 IRQ_TYPE_LEVEL_LOW>;
 
 		shunt-resistor-micro-ohms = <5000>;
+		power-supplies = <&max77759_pmic>;
 	};
 
-	pmic@66 {
+	max77759_pmic: pmic@66 {
 		compatible = "maxim,max77759";
 		reg = <0x66>;
 
@@ -750,6 +752,11 @@ pmic@66 {
 
 		interrupt-controller;
 		#interrupt-cells = <2>;
+		power-supplies = <&maxtcpci>;
+
+		chgin_otg_reg: chgin-otg-regulator {
+			regulator-name = "chgin-otg";
+		};
 
 		gpio {
 			compatible = "maxim,max77759-gpio";

---
base-commit: 587858367581b9c55c3690f4e63382ad622719d4
change-id: 20260224-max77759-charger-dts-23493398e77c

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

