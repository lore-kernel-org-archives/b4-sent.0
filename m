From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 09 Jul 2024 16:48:26 +0800
Subject: [PATCH 2/2] arm64: dts: amlogic: add watchdog node for A4 SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240709-a4-a5_watchdog-v1-2-2ae852e05ec2@amlogic.com>
References: <20240709-a4-a5_watchdog-v1-0-2ae852e05ec2@amlogic.com>
In-Reply-To: <20240709-a4-a5_watchdog-v1-0-2ae852e05ec2@amlogic.com>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-watchdog@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Huqiang Qin <huqiang.qin@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720514906; l=898;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=nyw71UzO4OzW4LTj0eCc11shu2eqR6ZaJjbu/OQDEDw=;
 b=aWsB85jIFB9Rl+qfZ2QeulNuT3GyzoAIAwWkmfKJSU6pREfcaqDIpxneE0SWsaIe5hqCLoI4c
 ghCrFuV6L19D3mI+ykUXubGTygUq6G/+UPj0x0Knm417uxSwB/7xUJx
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Huqiang Qin <huqiang.qin@amlogic.com>

Add watchdog device.

Signed-off-by: Huqiang Qin <huqiang.qin@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi
index b6106ad4a072..496c3a2bcf25 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi
@@ -52,6 +52,12 @@ apb: bus@fe000000 {
 			#size-cells = <2>;
 			ranges = <0x0 0x0 0x0 0xfe000000 0x0 0x480000>;
 
+			watchdog@2100 {
+				compatible = "amlogic,a4-wdt", "amlogic,t7-wdt";
+				reg = <0x0 0x2100 0x0 0x10>;
+				clocks = <&xtal>;
+			};
+
 			uart_b: serial@7a000 {
 				compatible = "amlogic,a4-uart",
 					     "amlogic,meson-s4-uart";

-- 
2.37.1

