From: David Heidelberg <david@ixit.cz>
Date: Mon, 24 Nov 2025 22:53:40 +0100
Subject: [PATCH RFC 7/8] arm64: dts: qcom: sdm660-xiaomi-lavender: Enable
 support for battery
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251124-pmi8998_fuel_gauge-v1-7-dd3791f61478@ixit.cz>
References: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
In-Reply-To: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Casey Connolly <casey@connolly.tech>, Joel Selvaraj <foss@joelselvaraj.com>, 
 Yassine Oudjana <y.oudjana@protonmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 =?utf-8?q?Barnab=C3=A1s_Cz=C3=A9m=C3=A1n?= <barnabas.czeman@mainlining.org>, 
 Richard Acayan <mailingradian@gmail.com>, 
 Alexey Minnekhanov <alexeymin@postmarketos.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1321; i=david@ixit.cz;
 h=from:subject:message-id; bh=//aqcSpHZqCf7Mxnh6vHuPIwTM+lRyzwo555sjaHWYQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpJNPgrjHhAZgGkJRJFtjUg8tuRv4ka4Q3yB3je
 dyrZooQwrmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaSTT4AAKCRBgAj/E00kg
 chwTD/4/GOvibHB+A6jj1nlegYxO1fobQm020Fk2yy+lZ+X7zYV3IAd3dAJcIJIMHcPa4/ZAyDl
 nnclreUzuijV8H0Rj8MFp7B25J5XNUPa+ZE9kwrOTNp6uWVrRo25ft1/cS6AnxVWc86DS+3MQ3T
 oEmy56/52kuKyL2kZkVa1gcpZADRqSvi965KuhHYKZlTZenqfWUQBFybCO/yQER7f1LAdwjFbNC
 67OIvlVKhIoLq2zPLu/7Daxf6KypaLTHMnA5jt1sQRW598WEaEKmXx0GJNR2tZYpu3lmuLaV5eS
 l/rEkvpOkwFioU/R7oWsPy52dkaMW5gHC7MZ6uRHsFOCPLCuqENkKANHJm9rV/R/E1h+jXX4B6p
 HbZ+uDifRd1IPxgIc4+QRhMfYz+czqHv2YzcWkzCX5rIQJwVXx300XkA2y/xpL8TBbANFEqRIUm
 qsTSZTWA4uD+jQC8B9RKiOa2NpDORvD9XPwV3hjdaT0sTYXndKmBOi9RpTQ+v6sMek3cMRI9hK4
 ps3fLHKSx5UOV/Ox2nCftygviLdL9efjTNnIjCpCvhpbsSmCEL1UU3s6vHrTrXecxfqz7hOG73z
 PeOpDuJVSWELW4mcTv3G/cx6/XC1OjdrmUS3IV95D0qUIeRAzWRC/LcVF5Yegpz7nQwyaCqOWgk
 1AfBNTow9k3tiQQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alexey Minnekhanov <alexeymin@postmarketos.org>

Add support for battery, fuelgauge and charger.

Signed-off-by: Alexey Minnekhanov <alexeymin@postmarketos.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../arm64/boot/dts/qcom/sdm660-xiaomi-lavender.dts | 25 ++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm660-xiaomi-lavender.dts b/arch/arm64/boot/dts/qcom/sdm660-xiaomi-lavender.dts
index a9926ad6c6f9f..cb89b88d887d1 100644
--- a/arch/arm64/boot/dts/qcom/sdm660-xiaomi-lavender.dts
+++ b/arch/arm64/boot/dts/qcom/sdm660-xiaomi-lavender.dts
@@ -38,6 +38,14 @@ framebuffer0: framebuffer@9d400000 {
 		};
 	};
 
+	battery: battery {
+		compatible = "simple-battery";
+
+		charge-full-design-microamp-hours = <4000000>;
+		voltage-min-design-microvolt = <3400000>;
+		voltage-max-design-microvolt = <4400000>;
+	};
+
 	vph_pwr: vph-pwr-regulator {
 		compatible = "regulator-fixed";
 		regulator-name = "vph_pwr";
@@ -93,6 +101,23 @@ &blsp1_uart2 {
 	status = "okay";
 };
 
+&pm660_charger {
+	monitored-battery = <&battery>;
+
+	status = "okay";
+};
+
+&pm660_fg {
+	monitored-battery = <&battery>;
+	power-supplies = <&pm660_charger>;
+
+	status = "okay";
+};
+
+&pm660_rradc {
+	status = "okay";
+};
+
 &pon_pwrkey {
 	status = "okay";
 };

-- 
2.51.0

