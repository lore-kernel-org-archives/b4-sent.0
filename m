From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Mon, 04 Aug 2025 16:26:41 +0200
Subject: [PATCH v5 4/4] arm64: dts: exynos: google: add Maxim MAX77759
 Fuel-gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250804-b4-gs101_max77759_fg-v5-4-03a40e6c0e3d@uclouvain.be>
References: <20250804-b4-gs101_max77759_fg-v5-0-03a40e6c0e3d@uclouvain.be>
In-Reply-To: <20250804-b4-gs101_max77759_fg-v5-0-03a40e6c0e3d@uclouvain.be>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754317658; l=4842;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=WF3EeuQVRCI8z8XyGntN8UgYyyixrVyY5uSQUCZ94dw=;
 b=v68T20khFe1UGQ2JyoNgy4ms6kbeJYjj9SRA+1t4Mx+n0o6kAgF3AMdV/EemaH96ywtN6rd6t
 EPtpPJzp0m8A2BonUtQTkzYgodWp+grRpoUrNC1z/wYrp6tl5qw45Kw
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the node for the Maxim MAX77759 fuel gauge as a slave of the i2c.

The TODO is still applicable given there are other slaves on the
bus (e.g. PCA9468, other MAX77759 functions and the MAX20339 OVP).

For the device specific values (full design capacity and terminal
current), the device should check an EEPROM at address 0x50 of the
hsi2c_8 for a battery id stored in register 0x17. A set of parameters
for the initialization of the fuel gauge should be chosen based on
this id. Those sets are defined here:

Link: https://android.googlesource.com/kernel/gs/+/refs/heads/android-gs-raviole-5.10-android15/arch/arm64/boot/dts/google/gs101-oriole-battery-data.dtsi
Link: https://android.googlesource.com/kernel/gs/+/refs/heads/android-gs-raviole-5.10-android15/arch/arm64/boot/dts/google/gs101-raven-battery-data.dtsi

This does not seem to be a standard pattern in the kernel currently
so it is not implemented. Values observed on tested devices are
instead used. The driver or the devicetree should be should be
extended in the future to take versions into account.

The pinctrl name follows the convention proposed in
Link: https://lore.kernel.org/all/20250524-b4-max77759-mfd-dts-v2-2-b479542eb97d@linaro.org/

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 arch/arm64/boot/dts/exynos/google/gs101-oriole.dts | 10 ++++++++
 .../boot/dts/exynos/google/gs101-pixel-common.dtsi | 30 ++++++++++++++++++++++
 arch/arm64/boot/dts/exynos/google/gs101-raven.dts  | 11 ++++++++
 3 files changed, 51 insertions(+)

diff --git a/arch/arm64/boot/dts/exynos/google/gs101-oriole.dts b/arch/arm64/boot/dts/exynos/google/gs101-oriole.dts
index 8df42bedbc036b5e97f6238d64820370043ffef2..18d147f6ea4a1a76c375996557349c866b9dad72 100644
--- a/arch/arm64/boot/dts/exynos/google/gs101-oriole.dts
+++ b/arch/arm64/boot/dts/exynos/google/gs101-oriole.dts
@@ -13,6 +13,12 @@
 / {
 	model = "Oriole";
 	compatible = "google,gs101-oriole", "google,gs101";
+
+	battery: battery {
+		compatible = "simple-battery";
+		charge-full-design-microamp-hours = <4524000>;
+		charge-term-current-microamp = <45000>;
+	};
 };
 
 &cont_splash_mem {
@@ -27,3 +33,7 @@ &framebuffer0 {
 	format = "a8r8g8b8";
 	status = "okay";
 };
+
+&fuel_gauge {
+	monitored-battery = <&battery>;
+};
diff --git a/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi b/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
index d6ddcc13f7b20c6dfbe92e86abafe965870d0c78..3362ad89ef6bacb7349259cf9e14452193ff7361 100644
--- a/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
+++ b/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
@@ -10,6 +10,7 @@
 
 #include <dt-bindings/gpio/gpio.h>
 #include <dt-bindings/input/input.h>
+#include <dt-bindings/interrupt-controller/irq.h>
 #include <dt-bindings/usb/pd.h>
 #include "gs101-pinctrl.h"
 #include "gs101.dtsi"
@@ -99,6 +100,16 @@ &hsi2c_8 {
 	eeprom: eeprom@50 {
 		compatible = "atmel,24c08";
 		reg = <0x50>;
+
+		nvmem-layout {
+			compatible = "fixed-layout";
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			fg_state: fgstate@42 {
+				reg = <0x42 0x17>;
+			};
+		};
 	};
 };
 
@@ -188,6 +199,18 @@ usbc0_role_sw: endpoint {
 			};
 		};
 	};
+
+	fuel_gauge: fuel-gauge@36 {
+		compatible = "maxim,max77759-fg";
+		reg = <0x36>;
+		pinctrl-names = "default";
+		pinctrl-0 = <&if_pmic_fg_int>;
+		interrupt-parent = <&gpa9>;
+		interrupts = <3 IRQ_TYPE_LEVEL_LOW>;
+		shunt-resistor-micro-ohms = <5000>;
+		nvmem-cell-names = "fg_state";
+		nvmem-cells = <&fg_state>;
+	};
 };
 
 &pinctrl_far_alive {
@@ -214,6 +237,13 @@ typec_int: typec-int-pins {
 };
 
 &pinctrl_gpio_alive {
+	if_pmic_fg_int: if-pmic-fg-int-pins {
+		samsung,pins = "gpa9-3";
+		samsung,pin-function = <GS101_PIN_FUNC_EINT>;
+		samsung,pin-pud = <GS101_PIN_PULL_UP>;
+		samsung,pin-drv = <GS101_PIN_DRV_2_5_MA>;
+	};
+
 	key_power: key-power-pins {
 		samsung,pins = "gpa10-1";
 		samsung,pin-function = <GS101_PIN_FUNC_EINT>;
diff --git a/arch/arm64/boot/dts/exynos/google/gs101-raven.dts b/arch/arm64/boot/dts/exynos/google/gs101-raven.dts
index 1e7e6b34b8649bc700a745c579a0268f0f6a9524..f91800879ea94b8fb0008c5e1f828072cabc1ac7 100644
--- a/arch/arm64/boot/dts/exynos/google/gs101-raven.dts
+++ b/arch/arm64/boot/dts/exynos/google/gs101-raven.dts
@@ -13,6 +13,13 @@
 / {
 	model = "Raven";
 	compatible = "google,gs101-raven", "google,gs101";
+
+	battery: battery {
+		compatible = "simple-battery";
+
+		charge-full-design-microamp-hours = <4904000>;
+		charge-term-current-microamp = <49000>;
+	};
 };
 
 &cont_splash_mem {
@@ -27,3 +34,7 @@ &framebuffer0 {
 	format = "a8r8g8b8";
 	status = "okay";
 };
+
+&fuel_gauge {
+	monitored-battery = <&battery>;
+};

-- 
2.50.1

