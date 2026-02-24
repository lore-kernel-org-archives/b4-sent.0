From: Amit Sunil Dhamne <amitsd@google.com>
Date: Tue, 24 Feb 2026 23:30:09 +0000
Subject: [PATCH v2] arm64: dts: exynos: gs101-pixel-common: add supply and
 regulator properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260224-max77759-charger-dts-v2-1-983265ac8e63@google.com>
X-B4-Tracking: v=1; b=H4sIAIA0nmkC/4WNTQ6CMBSEr0Le2mf6a60r72FY1PIsTYSSlhAM4
 e5WLuDym8l8s0GhHKnArdkg0xJLTGMFcWrA924MhLGrDIKJCxNC4eBWY4y2WOscKGM3FxRSWSn
 tlYzxUKdTpldcD+2jrdzHMqf8OV4W/kv/CBeOHJ9KSa20Z8q5e0gpvOns0wDtvu9f3olMZLkAA
 AA=
X-Change-ID: 20260224-max77759-charger-dts-23493398e77c
To: Peter Griffin <peter.griffin@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771975832; l=2045;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=88wsB5MWvHCzIwGqyj8+p1i8avmUTsCvuP3h53Fmyv8=;
 b=dh7Wzn/BI6+sbCg7HzZuAnFKztyTTZjpc3QWBJVkfFGIWyd3aWswVHKJHeGu12064DZor3HAs
 Wq9qT3xRmsMCcFk2m99357uGLp58VjOtJ3IF0y9YaqYq9U8GL3xE4W9
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power supply and regulator properties to the MAX77759 pmic. The
usb-typec device will reference the regulator provided by the pmic as
it supplies vbus to the typec device when operating in power source mode.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
This patch depends on the patchset [1].
[1] https://lore.kernel.org/all/20260224-max77759-charger-v8-0-eb86bd570e9c@google.com/
---
Changes in v2:
- Added a line between property and child node as per DTS coding std.
  (Krzysztof Kozlowski)
- Added the "power-supplies" property immediately after the prev
  property without leaving a line space.
- Link to v1: https://lore.kernel.org/r/20260224-max77759-charger-dts-v1-1-b443545c04aa@google.com
---
 arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi b/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
index 93892adaa679..14c1518bef81 100644
--- a/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
+++ b/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
@@ -142,12 +142,13 @@ &hsi2c_12 {
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
@@ -235,6 +236,11 @@ pmic@66 {
 
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
base-commit: 8bf22c33e7a172fbc72464f4cc484d23a6b412ba
change-id: 20260224-max77759-charger-dts-23493398e77c

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

