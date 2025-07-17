From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 17 Jul 2025 16:59:17 +0800
Subject: [PATCH] dts: arm: amlogic: fix pwm node for c3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250717-fix-pwm-node-v1-1-45021777efa9@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAGS7eGgC/x2MQQqAIBAAvxJ7bkEFlfpKdLBcaw9ZKFQg/j3pO
 AwzBTIlpgxjVyDRzZnP2ED2Hay7ixsh+8aghNLCSouBX7yeA+PpCY2koOziBiM0tORK1Py/m+Z
 aP+a/zN9eAAAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chuan Liu <chuan.liu@amlogic.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752742757; l=1025;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=o5anEexAdJpsa2RWVePMFRWkvLxzPjZ8flBM5Edgoco=;
 b=WiA8ozMtVIYrzvTWtrwaxBiYQ1SRzjW6Ye/Tg8+39l0g9LF2BvFGboskS2qOMR+lmFFa8W+jL
 Wo+31HvFNR4DFp7Ch5eHYMjU1LfkqNrvMUZSOaxphRUWBHalHX/VvNz
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix reg address for c3 pwm node.

Fixes: 431a5281e701 ("arm64: dts: amlogic: Add Amlogic C3 PWM")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Fix c3 pwm node reg.
---
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi
index cb9ea3ca6ee0..71b2b3b547f7 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi
@@ -792,7 +792,7 @@ spicc1: spi@52000 {
 			pwm_mn: pwm@54000 {
 				compatible = "amlogic,c3-pwm",
 					     "amlogic,meson-s4-pwm";
-				reg = <0x0 54000 0x0 0x24>;
+				reg = <0x0 0x54000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_M>,
 					 <&clkc_periphs CLKID_PWM_N>;
 				#pwm-cells = <3>;

---
base-commit: 58abdca0eb653c1a2e755ba9ba406ee475d87636
change-id: 20250717-fix-pwm-node-61ef27ba9605

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

