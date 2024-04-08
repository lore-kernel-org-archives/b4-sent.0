From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Mon, 08 Apr 2024 11:26:25 +0800
Subject: [PATCH] arm64: dts: meson: fix S4 power-controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240408-fix-secpwr-s4-v1-1-01aa7ee72c52@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAOBjE2YC/x2MQQqAIBAAvyJ7bmELiewr0UFyrb2UuFCB+Pek4
 8DMFFDOwgqzKZD5FpXrbNB3BrbDnzujhMYw0GDJ0oRRXlTe0pNRLXrnYnQjBfIMrUmZm/D/lrX
 WDxnMTcFfAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712546787; l=1062;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=aYGam5atTvFCi6MANFq1gTnEWCmMJGBzGpQ68DNxd4s=;
 b=QOZasB9XfpjbYCM2NkQXMlQePi2brRVq25BtW9pZQ/O/LAgdf/E30jblrbUc47W0QCYLKqMCn
 Sd+AOKQpyePAuPOG9BkArADHL7TsnkikXqRDb0KtLIx1RUfQSqwjBEd
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The power-controller module works well by adding its parent
node secure-monitor.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi | 11 +++++++----
 1 file changed, 7 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
index ce90b35686a2..24d00dce4969 100644
--- a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
@@ -65,10 +65,13 @@ xtal: xtal-clk {
 		#clock-cells = <0>;
 	};
 
-	pwrc: power-controller {
-		compatible = "amlogic,meson-s4-pwrc";
-		#power-domain-cells = <1>;
-		status = "okay";
+	sm: secure-monitor {
+		compatible = "amlogic,meson-gxbb-sm";
+
+		pwrc: power-controller {
+			compatible = "amlogic,meson-s4-pwrc";
+			#power-domain-cells = <1>;
+		};
 	};
 
 	soc {

---
base-commit: 4cece764965020c22cff7665b18a012006359095
change-id: 20240408-fix-secpwr-s4-a99ff960d0ae

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

