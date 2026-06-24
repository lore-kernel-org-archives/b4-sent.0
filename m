From: Ricardo Pardini <ricardo@pardini.net>
Date: Wed, 24 Jun 2026 13:41:50 +0200
Subject: [PATCH] arm64: dts: mediatek: mt8395-radxa-nio-12l: Enable I2C3 on
 40-pin header
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260624-nio-12l-add-i2c-40-pin-v1-1-f6c11ed2184c@pardini.net>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDuQjFHUq5QuNBl1SomSVBHEu
 xt1+Rb/7xA5CEdosh0CrxJl8gn6lYEdWz8wiksGUlSqkgx6mVDTD1vnUMiiUTiLR12zMhX1rso
 LSPEcuJftHr8/j+PSfdn+rxscxwkHLTmbegAAAA==
X-Change-ID: 20260624-nio-12l-add-i2c-40-pin-19e0482fd835
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1939; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=bk5ea6cLdsnJpmBdpwgO3E/mbMZWo2izXGkJpWcYnGg=;
 b=owEBiQF2/pANAwAIATteP+Oex+3pAcsmYgBqO8KM5gmzPvJ/rOmLT+qPMGepPIDKiCk8X5DBu
 5jAJoBZRaSJAU8EAAEIADkWIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCajvCjBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQO14/457H7eliKwf/RkZ83zDF2MFSMVYiVJmHI8+ZuRR4XYD
 nmdBGdJ1vpt7+H9f1xXNJr8MafhwauM1waRUw2x8cK2BgbUbNVvz7O+03KxR1dwP5xzYTP8N9Pa
 eG3rxMC81LILXsxmleoMnJ8TSbsvlxLJYTiZ/ZMmjncU0Sm4Dzx8Km8puNAYXGr/tDsgf0JPH/q
 0mOXv5YVPVwWJzWeH+JVtUgY4lnxUh0m61v6SXzQAfCnipWskgWmCnjNiskyTOtuMew3eJNzlX9
 Y1lA74GukTKRTFwLK+GI9SaNl3XFoKDvT1/l8i/YsztE6DWpmGaHDAg0EYvdurkCtLdGJQ4Jihm
 mm1jmx1rbYg==
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I2C3 (SDA3/SCL3 on GPIO14/GPIO15) is routed to the 40-pin GPIO header,
exposed on the blue-colored pins 27 (SCL3) and 28 (SDA3). Enable the
controller, add the corresponding pin configuration in the pinctrl node
so users can use external I2C devices.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
The Radxa NIO 12L exposes I2C3 (SDA3/SCL3, GPIO14/GPIO15) on its 40-pin
GPIO header, on the blue-coloured pins 27 (SCL3) and 28 (SDA3).

Enable the I2C3 controller, add the matching pinctrl configuration and run
the bus at 400 kHz, matching the other I2C buses already enabled on this
board.

Tested using a SD1306 I2C OLED display.
---
 arch/arm64/boot/dts/mediatek/mt8395-radxa-nio-12l.dts | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/arch/arm64/boot/dts/mediatek/mt8395-radxa-nio-12l.dts b/arch/arm64/boot/dts/mediatek/mt8395-radxa-nio-12l.dts
index bf91305e8e4a5..03a2f2e746475 100644
--- a/arch/arm64/boot/dts/mediatek/mt8395-radxa-nio-12l.dts
+++ b/arch/arm64/boot/dts/mediatek/mt8395-radxa-nio-12l.dts
@@ -371,6 +371,14 @@ it5205_sbu_mux: endpoint {
 	};
 };
 
+/* Exposed on 40-pin header (blue-colored pins 27:SCL3 28:SDA3) */
+&i2c3 {
+	clock-frequency = <400000>;
+	pinctrl-0 = <&i2c3_pins>;
+	pinctrl-names = "default";
+	status = "okay";
+};
+
 &i2c4 {
 	clock-frequency = <400000>;
 	pinctrl-0 = <&i2c4_pins>;
@@ -789,6 +797,16 @@ pins-bus {
 		};
 	};
 
+	i2c3_pins: i2c3-pins {
+		pins-bus {
+			pinmux = <PINMUX_GPIO14__FUNC_SDA3>,
+				 <PINMUX_GPIO15__FUNC_SCL3>;
+			bias-pull-up = <1000>;
+			drive-strength = <6>;
+			drive-strength-microamp = <1000>;
+		};
+	};
+
 	i2c4_pins: i2c4-pins {
 		pins-bus {
 			pinmux = <PINMUX_GPIO16__FUNC_SDA4>,

---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260624-nio-12l-add-i2c-40-pin-19e0482fd835

Best regards,
--  
Ricardo Pardini <ricardo@pardini.net>

