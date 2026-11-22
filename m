From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 22 Nov 2026 15:46:17 -0600
Subject: [PATCH 2/4] arm64: dts: qcom: qcs8550-retroidpocket-nova: Enable
 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-rp-qcs8550-display-v1-2-d513d9819a34@gmail.com>
References: <20261122-rp-qcs8550-display-v1-0-d513d9819a34@gmail.com>
In-Reply-To: <20261122-rp-qcs8550-display-v1-0-d513d9819a34@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795383979; l=1370;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=EZkGLXBz93tAMjSBCGHN5T876EfnxJnLxEzSPtgJ7MI=;
 b=SXoRBMsBKJxKIt+Efw694s+vk/N73MsCDojqeXMOdcTF72gJT2W29quiQhWLbpY0BjqAOOjTx
 L0pIzRT0hJkCuocjnqXgxTTz0fptwlWAiy7Epml6icLx+BTPmevWgXb
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is supported by the Ilitek ili7836a driver.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 .../boot/dts/qcom/qcs8550-retroidpocket-nova.dts   | 37 ++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-nova.dts b/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-nova.dts
index ef1356f4c34ce..11689f1bc3d8f 100644
--- a/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-nova.dts
+++ b/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-nova.dts
@@ -80,6 +80,43 @@ touchscreen@38 {
 	};
 };
 
+&mdss_dsi0 {
+	vdda-supply = <&vreg_l3e_1p2>;
+
+	status = "okay";
+
+	panel@0 {
+		reg = <0>;
+		compatible = "retroidpocket,nova-panel", "ilitek,ili7836a";
+
+		pinctrl-0 = <&dsi_p_rst_active>, <&dsi_p_te_active>;
+		pinctrl-1 = <&dsi_p_rst_suspend>, <&dsi_p_te_suspend>;
+		pinctrl-names = "default", "sleep";
+
+		vddio-supply = <&vdd_disp_1v8>;
+		avdd-supply = <&vdd_disp_2v8>;
+
+		reset-gpios = <&tlmm 133 GPIO_ACTIVE_LOW>;
+
+		port {
+			panel0_in: endpoint {
+				remote-endpoint = <&mdss_dsi0_out>;
+			};
+		};
+	};
+};
+
+&mdss_dsi0_out {
+	remote-endpoint = <&panel0_in>;
+	data-lanes = <0 1 2 3>;
+};
+
+&mdss_dsi0_phy {
+	vdds-supply = <&vreg_l1e_0p88>;
+
+	status = "okay";
+};
+
 &mdss_dsi1 {
 	status = "disabled";
 };

-- 
2.56.0

