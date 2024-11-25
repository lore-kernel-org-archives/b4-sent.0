From: Maud Spierings <maud_spierings@hotmail.com>
Date: Mon, 25 Nov 2024 20:11:17 +0100
Subject: [PATCH v4 1/3] arm64: dts: qcom: x1e80100-vivobook-s15: Use the
 samsung,atna33xc20 panel driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241125-asus_qcom_display-v4-1-61a4da162406@hotmail.com>
References: <20241125-asus_qcom_display-v4-0-61a4da162406@hotmail.com>
In-Reply-To: <20241125-asus_qcom_display-v4-0-61a4da162406@hotmail.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Douglas Anderson <dianders@chromium.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732561888; l=1440;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=/7ww43t4PL3OnNaGBy55/XHQy/o3cpc7eGJ7M5Nsi7k=;
 b=59b76BxFiKShlT5Zlo3YLSAemYxcOgNFq5CctPB1xE/ZTqx2Q5XaJwiWfZRyilkGKTyA8kcgW
 ttOuyqOrSX/Dxbi4HspRD0nhqR1GdEoGG04B6KDwY3yUUBGg5ustsmD
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Asus vivobook s15 uses the ATNA56AC03 panel.
This panel is controlled by the atna33xc20 driver instead of the generic
edp-panel driver

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 .../arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts | 18 +++++++++++++++++-
 1 file changed, 17 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts b/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
index f25991b887de3fca0092c5f81c881c5d8bd71aac..8cdb2888d10a1dfc0c28480b6636584ab06853bb 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
@@ -407,9 +407,13 @@ &mdss_dp3 {
 
 	aux-bus {
 		panel {
-			compatible = "edp-panel";
+			compatible = "samsung,atna56ac03", "samsung,atna33xc20";
+			enable-gpios = <&pmc8380_3_gpios 4 GPIO_ACTIVE_HIGH>;
 			power-supply = <&vreg_edp_3p3>;
 
+			pinctrl-0 = <&edp_bl_en>;
+			pinctrl-names = "default";
+
 			port {
 				edp_panel_in: endpoint {
 					remote-endpoint = <&mdss_dp3_out>;
@@ -475,6 +479,18 @@ &pcie6a_phy {
 	status = "okay";
 };
 
+&pmc8380_3_gpios {
+	edp_bl_en: edp-bl-en-state {
+		pins = "gpio4";
+		function = "normal";
+		power-source = <1>;
+		qcom,drive-strength = <2>;
+		bias-pull-down;
+		input-disable;
+		output-enable;
+	};
+};
+
 &qupv3_0 {
 	status = "okay";
 };

-- 
2.47.1

