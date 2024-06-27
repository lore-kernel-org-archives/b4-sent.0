From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 27 Jun 2024 19:47:53 +0800
Subject: [PATCH 3/3] arm64: dts: amlogic: a5: add power domain controller
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240627-a5_secpower-v1-3-1f47dde1270c@amlogic.com>
References: <20240627-a5_secpower-v1-0-1f47dde1270c@amlogic.com>
In-Reply-To: <20240627-a5_secpower-v1-0-1f47dde1270c@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Hongyu Chen <hongyu.chen1@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719488872; l=952;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=a2Zu+uHx7AvPgs0U7XpBlBsH/P/9nCVcrhSWZWMj+mI=;
 b=QgBeyLD1Kac4MHjy5kyxtif4bCHe3DmeuihH4WAyneRpGvyo31dywxlvvHylqdPXeH7o/vv3N
 QBZtc7xUpsQAbNsGbVbH85wfd+4zPivbRtVm+3Ojs5fVy7LPkc+N2nM
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power domain controller node for Amlogic A5 SoC.

Signed-off-by: Hongyu Chen <hongyu.chen1@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
index 43f68a7da2f7..17a6316de891 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
@@ -4,6 +4,7 @@
  */
 
 #include "amlogic-a4-common.dtsi"
+#include <dt-bindings/power/amlogic,a5-pwrc.h>
 / {
 	cpus {
 		#address-cells = <2>;
@@ -37,4 +38,13 @@ cpu3: cpu@300 {
 			enable-method = "psci";
 		};
 	};
+
+	sm: secure-monitor {
+		compatible = "amlogic,meson-gxbb-sm";
+
+		pwrc: power-controller {
+			compatible = "amlogic,a5-pwrc";
+			#power-domain-cells = <1>;
+		};
+	};
 };

-- 
2.37.1

