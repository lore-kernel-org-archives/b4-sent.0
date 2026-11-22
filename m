From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 22 Nov 2026 15:46:19 -0600
Subject: [PATCH 4/4] arm64: dts: qcom: qcs8550-retroidpocket-rp6: Enable
 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-rp-qcs8550-display-v1-4-d513d9819a34@gmail.com>
References: <20261122-rp-qcs8550-display-v1-0-d513d9819a34@gmail.com>
In-Reply-To: <20261122-rp-qcs8550-display-v1-0-d513d9819a34@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795383979; l=1393;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=sS5jhdq9h9XCoaTgODmQdhNRvP+F/XPgg9IT8jRPQa8=;
 b=zUIshMSKq8Px7GuMZJr598a35qPlLtS8GUNerLpan6tj2oVOxmT5NfJeYgAn6RBgbknYPmwsx
 RuGg3U+O+ArAzuAfWe3Con77SJWqLWqWAkix6WDOd7fVAP7pNnckOX8
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is supported by the Visionox vtdr6130 driver.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 .../boot/dts/qcom/qcs8550-retroidpocket-rp6.dts    | 39 ++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-rp6.dts b/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-rp6.dts
index 91fed8795d611..5bbec9e1bae7c 100644
--- a/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-rp6.dts
+++ b/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-rp6.dts
@@ -84,6 +84,45 @@ touchscreen@38 {
 	};
 };
 
+&mdss_dsi0 {
+	vdda-supply = <&vreg_l3e_1p2>;
+
+	status = "okay";
+
+	panel@0 {
+		reg = <0>;
+		compatible = "retroidpocket,rp6-panel", "visionox,vtdr6130";
+
+		pinctrl-0 = <&dsi_p_rst_active>, <&dsi_p_te_active>;
+		pinctrl-1 = <&dsi_p_rst_suspend>, <&dsi_p_te_suspend>;
+		pinctrl-names = "default", "sleep";
+
+		vddio-supply = <&vdd_disp_1v8>;
+		vci-supply = <&vdd_disp_2v8>;
+
+		reset-gpios = <&tlmm 133 GPIO_ACTIVE_LOW>;
+
+		rotation = <270>;
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

