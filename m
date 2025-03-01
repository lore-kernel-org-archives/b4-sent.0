From: Joel Selvaraj <foss@joelselvaraj.com>
Date: Sat, 01 Mar 2025 17:43:10 -0600
Subject: [PATCH v3 4/4] arm64: dts: qcom: sdm845-xiaomi-beryllium-ebbg:
 introduce touchscreen support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250301-pocof1-touchscreen-support-v3-4-af01c3b30b55@joelselvaraj.com>
References: <20250301-pocof1-touchscreen-support-v3-0-af01c3b30b55@joelselvaraj.com>
In-Reply-To: <20250301-pocof1-touchscreen-support-v3-0-af01c3b30b55@joelselvaraj.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 Joel Selvaraj <foss@joelselvaraj.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740872603; l=1286;
 i=foss@joelselvaraj.com; s=20241007; h=from:subject:message-id;
 bh=RjgUxrTDZeUZrOstA31OE2MhayiA53NoLQULv+T9AW4=;
 b=qAPYySoh/iApH9aSUQYNS2tH7+LHh3fWU2i6VPL6LdtFUB+5lRGSAJGZ7k9s9HQUzrWsp5um/
 GKkxBxsxjNeAnKtYvR05sg8AF/0XqRh3JRRNWKd36+ydp27RSjZeT44
X-Developer-Key: i=foss@joelselvaraj.com; a=ed25519;
 pk=pqYvzJftxCPloaoUbVsfQE7Gwv8bynZPy8mjYohwMCc=
X-Endpoint-Received: by B4 Relay for foss@joelselvaraj.com/20241007 with auth_id=238
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the Focaltech FT8719 touchscreen controller used in the Poco F1
(EBBG) panel variant.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
---
 .../boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts | 23 ++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts
index 76931ebad065..2d6f0e382a6c 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts
@@ -13,3 +13,26 @@ &display_panel {
 	compatible = "ebbg,ft8719";
 	status = "okay";
 };
+
+&i2c14 {
+	status = "okay";
+
+	touchscreen@38 {
+		compatible = "focaltech,ft8719";
+		reg = <0x38>;
+
+		interrupts-extended = <&tlmm 31 IRQ_TYPE_EDGE_RISING>;
+		reset-gpios = <&tlmm 32 GPIO_ACTIVE_LOW>;
+		panel = <&display_panel>;
+
+		iovcc-supply = <&vreg_l14a_1p8>;
+		vcc-supply = <&lab>;
+
+		pinctrl-0 = <&ts_int_default &ts_reset_default>;
+		pinctrl-1 = <&ts_int_sleep &ts_reset_sleep>;
+		pinctrl-names = "default", "sleep";
+
+		touchscreen-size-x = <1080>;
+		touchscreen-size-y = <2246>;
+	};
+};

-- 
2.48.1

