From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 22 Aug 2025 13:39:57 +0800
Subject: [PATCH 3/5] arm64: dts: amlogic: s6: add power domain controller
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250822-pm-s6-s7-s7d-v1-3-82e3f3aff327@amlogic.com>
References: <20250822-pm-s6-s7-s7d-v1-0-82e3f3aff327@amlogic.com>
In-Reply-To: <20250822-pm-s6-s7-s7d-v1-0-82e3f3aff327@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 "hongyu.chen1" <hongyu.chen1@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755841286; l=1145;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=kaj5R8JXVNmN1FRoL5Yj/r2ULPjPs0Piqs4W5hS0JIc=;
 b=mNWwLLgu/xNH88+Fcp2R6hiHPFt3qyqtax1tCkA5cWc5xDTGy40bxgHirv+0PdP4kSNEpHllh
 ErUZY0ni+izBFCMmB47LG4bOyeAuJGPyYKWMyELiZbj6DppovDMfviA
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "hongyu.chen1" <hongyu.chen1@amlogic.com>

Add power domain controller node for Amlogic S6 SoC.

Signed-off-by: hongyu.chen1 <hongyu.chen1@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi
index 5f602f1170c0..0dca64a2ef9e 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi
@@ -7,6 +7,7 @@
 #include <dt-bindings/interrupt-controller/arm-gic.h>
 #include <dt-bindings/gpio/gpio.h>
 #include <dt-bindings/pinctrl/amlogic,pinctrl.h>
+#include <dt-bindings/power/amlogic,s6-pwrc.h>
 / {
 	cpus {
 		#address-cells = <2>;
@@ -41,6 +42,15 @@ cpu3: cpu@300 {
 		};
 	};
 
+	sm: secure-monitor {
+		compatible = "amlogic,meson-gxbb-sm";
+
+		pwrc: power-controller {
+			compatible = "amlogic,s6-pwrc";
+			#power-domain-cells = <1>;
+		};
+	};
+
 	timer {
 		compatible = "arm,armv8-timer";
 		interrupts = <GIC_PPI 13 (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_LOW)>,

-- 
2.37.1

