From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Sun, 08 Mar 2026 16:52:46 +0100
Subject: [PATCH 6/6] arm64: dts: qcom: msm8953-flipkart-rimob: Enable Hall
 sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260308-rimob-new-features-v1-6-aa2c330572c0@protonmail.com>
References: <20260308-rimob-new-features-v1-0-aa2c330572c0@protonmail.com>
In-Reply-To: <20260308-rimob-new-features-v1-0-aa2c330572c0@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772985181; l=1434;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=/6j0+t2XKdKx1e1cFAgI0as9W1ExR5I7yqNCXHZ/Uzs=;
 b=NzbU54tsA4XN8Nz2MbLAnZnyrJar55S2NfzMDiqjaBAhTT2PFW84rbNSK+RHqLfbFlgz8pfgW
 brFoFv9OkFFCjXVwpiII9P8yS/qAxX8jxuvtydmjSD5egBN68AjQz/j
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the Hall effect sensor (flip cover) for Billion Capture+.
The GPIO is mapped to SW_LID events as in other qcom devices.

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
 .../arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts | 25 ++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts b/arch/arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts
index 709ea6fc9fbb..83812050a0a3 100644
--- a/arch/arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts
+++ b/arch/arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts
@@ -44,6 +44,24 @@ framebuffer@90001000 {
 		};
 	};
 
+	gpio-hall-sensor {
+		compatible = "gpio-keys";
+
+		pinctrl-0 = <&hall_sensor_default>;
+		pinctrl-names = "default";
+
+		label = "GPIO Hall Effect Sensor";
+
+		event-hall-sensor {
+			label = "Hall Effect Sensor";
+			gpios = <&tlmm 46 GPIO_ACTIVE_LOW>;
+			linux,input-type = <EV_SW>;
+			linux,code = <SW_LID>;
+			linux,can-disable;
+			wakeup-source;
+		};
+	};
+
 	gpio-keys {
 		compatible = "gpio-keys";
 
@@ -335,6 +353,13 @@ gpio_key_default: gpio-key-default-state {
 		bias-pull-up;
 	};
 
+	hall_sensor_default: hall-sensor-default-state {
+		pins = "gpio46";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
 	mdss_default: mdss-default-state {
 		pins = "gpio61";
 		function = "gpio";

-- 
2.52.0

