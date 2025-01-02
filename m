From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Thu, 02 Jan 2025 12:15:06 +0100
Subject: [PATCH v2 4/4] arm64: dts: exynos: gs101-oriole: enable Maxim
 max77759 fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250102-b4-gs101_max77759_fg-v2-4-87959abeb7ff@uclouvain.be>
References: <20250102-b4-gs101_max77759_fg-v2-0-87959abeb7ff@uclouvain.be>
In-Reply-To: <20250102-b4-gs101_max77759_fg-v2-0-87959abeb7ff@uclouvain.be>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735816515; l=1485;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=GN3EniKaEOYE0aMNRzhLT0R4oirK05MCY9w8a0rDXYc=;
 b=eMvTZq9F+2RWFQ1BgK4RRLys8hBQwJ8vxzR3brqK5tBh//epZY74AciI9nsB10bwtDs1X2cbA
 YbKhbU97pEDDbvI3SWyzXLCMXp5vg1Z6AoNRMAQDFPtFUDxrpzy1Z+z
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the node for the max77759 fuel gauge as a slave of the i2c.

The todo is still applicable given there are other slaves on the
bus (pca9468, other max77759 functions and the max20339 OVP).

The fuel gauge has been tested and seems to give coherent results.
Manual activation of the charger via i2cset shows that the sign of
the current does indicate charging/discharging status.

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 arch/arm64/boot/dts/exynos/google/gs101-oriole.dts | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm64/boot/dts/exynos/google/gs101-oriole.dts b/arch/arm64/boot/dts/exynos/google/gs101-oriole.dts
index 387fb779bd29ea3812331a7951f03b181c5fe659..6c83ee6f8a6b0327c576573d03a8d2bcc93f9e16 100644
--- a/arch/arm64/boot/dts/exynos/google/gs101-oriole.dts
+++ b/arch/arm64/boot/dts/exynos/google/gs101-oriole.dts
@@ -10,6 +10,7 @@
 
 #include <dt-bindings/gpio/gpio.h>
 #include <dt-bindings/input/input.h>
+#include <dt-bindings/interrupt-controller/irq.h>
 #include "gs101-pinctrl.h"
 #include "gs101.dtsi"
 
@@ -90,6 +91,15 @@ eeprom: eeprom@50 {
 &hsi2c_12 {
 	status = "okay";
 	/* TODO: add the devices once drivers exist */
+
+	fuel-gauge@36 {
+		compatible = "maxim,max77759-fg";
+		reg = <0x36>;
+		reg-names = "m5";
+		shunt-resistor-micro-ohms = <5000>;
+		interrupt-parent = <&gpa9>;
+		interrupts = <3 IRQ_TYPE_LEVEL_LOW>;
+	};
 };
 
 &pinctrl_far_alive {

-- 
2.47.1

