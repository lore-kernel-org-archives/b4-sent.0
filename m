From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 29 May 2024 11:10:35 +0800
Subject: [PATCH v2 3/3] arm64: dts: amlogic: a4: add power domain
 controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240529-a4_secpowerdomain-v2-3-47502fc0eaf3@amlogic.com>
References: <20240529-a4_secpowerdomain-v2-0-47502fc0eaf3@amlogic.com>
In-Reply-To: <20240529-a4_secpowerdomain-v2-0-47502fc0eaf3@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716952234; l=894;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=AmiofDYC3IFCMwy7sO4GQjRfJjCUwOi49fG3NzsnzK4=;
 b=3Bx9xAD4eRBo4zTKnXndZ9mni8Z2V6Ohu2ryGjhp0WUKOdgr0sd2zyuR2P5JOPQ3cObwW2hyM
 smZ8i+VozEdBdtMFmxSbzNCtICyEjW/tjoIEH2qW5BiqBW6Y2XLZCeg
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power domain controller node for Amlogic A4 SoC

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
index 73ca1d7eed81..de10e7aebf21 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
@@ -4,6 +4,7 @@
  */
 
 #include "amlogic-a4-common.dtsi"
+#include <dt-bindings/power/amlogic,a4-pwrc.h>
 / {
 	cpus {
 		#address-cells = <2>;
@@ -37,4 +38,13 @@ cpu3: cpu@3 {
 			enable-method = "psci";
 		};
 	};
+
+	sm: secure-monitor {
+		compatible = "amlogic,meson-gxbb-sm";
+
+		pwrc: power-controller {
+			compatible = "amlogic,a4-pwrc";
+			#power-domain-cells = <1>;
+		};
+	};
 };

-- 
2.37.1

