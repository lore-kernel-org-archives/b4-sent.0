From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 12 Apr 2024 16:42:30 +0800
Subject: [PATCH v2] arm64: dts: meson: fix S4 power-controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240412-fix-secpwr-s4-v2-1-3802fd936d77@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAPXzGGYC/3WMQQ6CMBBFr0Jm7Zi2qSKuvIdh0ZQpTCKUdEzVk
 N7dyt7l+/nvbSCUmASuzQaJMgvHpYI5NOAnt4yEPFQGo4xVVl0w8BuF/PpKKBZd14XQndWgHEF
 11kT1sPfufeWJ5RnTZ89n/Vv/lbJGjUo71xK1xp/Mzc2POLI/+jhDX0r5AkNlCI+sAAAA
To: Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712911352; l=1368;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=oKEf8J5zEQ5VRP4drtkFgH9o2pd0Lw+wi/tMBGddobo=;
 b=g58n8V9t/QOY/0zH12yHIGuXoV1zedqzQpBb4TpKujUbaYz9w6Iv3V+0IJTaDWu4CybnE7KPy
 U0mZWlwsjwxBksQosAldqYNI8h4o8x1+ufJ+NDJhg+Mhz7pmacs70Z5
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The power-controller module works well by adding its parent
node secure-monitor.

Fixes: 085f7a298a14 ("arm64: dts: add support for S4 power domain controller")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Add fixes tags in commit message.
- Add firmware node to adapt documentation.
- Link to v1: https://lore.kernel.org/r/20240408-fix-secpwr-s4-v1-1-01aa7ee72c52@amlogic.com
---
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
index ce90b35686a2..10896f9df682 100644
--- a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
@@ -65,10 +65,15 @@ xtal: xtal-clk {
 		#clock-cells = <0>;
 	};
 
-	pwrc: power-controller {
-		compatible = "amlogic,meson-s4-pwrc";
-		#power-domain-cells = <1>;
-		status = "okay";
+	firmware {
+		sm: secure-monitor {
+			compatible = "amlogic,meson-gxbb-sm";
+
+			pwrc: power-controller {
+				compatible = "amlogic,meson-s4-pwrc";
+				#power-domain-cells = <1>;
+			};
+		};
 	};
 
 	soc {

---
base-commit: 4cece764965020c22cff7665b18a012006359095
change-id: 20240408-fix-secpwr-s4-a99ff960d0ae

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

