From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Wed, 18 Mar 2026 23:28:14 +0100
Subject: [PATCH v2 6/6] arm64: dts: qcom: msm8953-flipkart-rimob: Enable
 Hall sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260318-rimob-new-features-v2-6-c1bf8917449e@protonmail.com>
References: <20260318-rimob-new-features-v2-0-c1bf8917449e@protonmail.com>
In-Reply-To: <20260318-rimob-new-features-v2-0-c1bf8917449e@protonmail.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773872973; l=1490;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=BpEZAxaRMbsFvhAErL6IwwI9A2ip6vYnZ5JNw0nz32s=;
 b=whBdo/7s0zM3mHmWzAdJdGUUI6jcZyDam8GsX/EJe+E24kLpf85/XjK1HI0gANmQvGzI3qNWg
 +pErE36jT2UCVJCTKAFsqlckct7MYDaicolZRIHbvicXSSw+pbmy4Eg
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the Hall effect sensor (flip cover) for Billion Capture+.
The GPIO is mapped to SW_LID events as in other qcom devices.

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
 arch/arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts | 18 +++++++++++++++++-
 1 file changed, 17 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts b/arch/arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts
index f641ec9f9486..113ece32edbc 100644
--- a/arch/arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts
+++ b/arch/arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts
@@ -47,9 +47,18 @@ framebuffer@90001000 {
 	gpio-keys {
 		compatible = "gpio-keys";
 
-		pinctrl-0 = <&gpio_key_default>;
+		pinctrl-0 = <&gpio_hall_sensor_default>, <&gpio_key_default>;
 		pinctrl-names = "default";
 
+		event-hall-sensor {
+			label = "Hall Effect Sensor";
+			gpios = <&tlmm 46 GPIO_ACTIVE_LOW>;
+			linux,input-type = <EV_SW>;
+			linux,code = <SW_LID>;
+			linux,can-disable;
+			wakeup-source;
+		};
+
 		key-volume-up {
 			label = "Volume Up";
 			gpios = <&tlmm 85 GPIO_ACTIVE_LOW>;
@@ -329,6 +338,13 @@ &sdhc_2 {
 &tlmm {
 	gpio-reserved-ranges = <0 4>, <135 4>;
 
+	gpio_hall_sensor_default: gpio-hall-sensor-default-state {
+		pins = "gpio46";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
 	gpio_key_default: gpio-key-default-state {
 		pins = "gpio85";
 		function = "gpio";

-- 
2.53.0

