From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Mon, 21 Apr 2025 20:13:36 +0200
Subject: [PATCH v3 5/5] arm64: dts: exynos: gs101-oriole: enable Maxim
 max77759 fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250421-b4-gs101_max77759_fg-v3-5-50cd8caf9017@uclouvain.be>
References: <20250421-b4-gs101_max77759_fg-v3-0-50cd8caf9017@uclouvain.be>
In-Reply-To: <20250421-b4-gs101_max77759_fg-v3-0-50cd8caf9017@uclouvain.be>
To: Rob Herring <robh@kernel.org>, Peter Griffin <peter.griffin@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alim Akhtar <alim.akhtar@samsung.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sebastian Reichel <sre@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745259219; l=1313;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=+E8KTkRWD/mhjwDdm0OrzwMI0i7bo8G/TbulwCt/cNU=;
 b=3Vmi01/6lLR8bdWK8rEFtyFk8OJvaSSYwt+P0HGLokKmOmUByXF181HxjD28obfVkyXl2dRlz
 +rwW3Uw+43aDGPshLCK05RKjDNecb/srcSX5tw0KEv7JXZaDrFG9C9G
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the node for the Maxim MAX77759 fuel gauge as a slave of the i2c.

The TODO is still applicable given there are other slaves on the
bus (e.g. PCA9468, other MAX77759 functions and the MAX20339 OVP).

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi b/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
index b25230495c64dce60916b7cd5dcb9a7cce5d0e4e..84fc10c3562958ab1621f24644709e85a9433b9b 100644
--- a/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
+++ b/arch/arm64/boot/dts/exynos/google/gs101-pixel-common.dtsi
@@ -10,6 +10,7 @@
 
 #include <dt-bindings/gpio/gpio.h>
 #include <dt-bindings/input/input.h>
+#include <dt-bindings/interrupt-controller/irq.h>
 #include <dt-bindings/usb/pd.h>
 #include "gs101-pinctrl.h"
 #include "gs101.dtsi"
@@ -188,6 +189,15 @@ usbc0_role_sw: endpoint {
 			};
 		};
 	};
+
+	fuel-gauge@36 {
+		compatible = "maxim,max77759-fg";
+		reg = <0x36>;
+		reg-names = "m5";
+		interrupt-parent = <&gpa9>;
+		interrupts = <3 IRQ_TYPE_LEVEL_LOW>;
+		shunt-resistor-micro-ohms = <5000>;
+	};
 };
 
 &pinctrl_far_alive {

-- 
2.49.0

