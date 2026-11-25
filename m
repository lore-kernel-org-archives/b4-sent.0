From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Nov 2026 14:08:16 +0100
Subject: [PATCH v3 5/5] arm64: dts: qcom: sdm845-google: drop panel
 regulator-always-on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-fix-blueline-panel-v3-5-914b4a30b73e@ixit.cz>
References: <20261125-fix-blueline-panel-v3-0-914b4a30b73e@ixit.cz>
In-Reply-To: <20261125-fix-blueline-panel-v3-0-914b4a30b73e@ixit.cz>
To: Abel Vesa <abelvesa@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Airlie <airlied@gmail.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, Jessica Zhang <jesszhan0024@gmail.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maxime Ripard <mripard@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Simona Vetter <simona@ffwll.ch>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Thomas Zimmermann <tzimmermann@suse.de>, Vinod Koul <vkoul@kernel.org>
Cc: devicetree@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3724; i=david@ixit.cz;
 h=from:subject:message-id; bh=7MbJWcOA7VgDjyx+wISNbX3wFon6Upjhtfj1PpZjQxE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBt3BP5Lf1wO+j5Mx/5MSPqPEcwqPoMlGv/Zcc
 PrK11+eEfiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawbdwQAKCRBgAj/E00kg
 clXoD/41wH4jQ2DlT9BhUtMArglYyo7sqm5aOY7yyZ5mM5eH9losiXE56sS8ihyEO/UZAN5vyDQ
 QDPdpORQ5pxnA2Mmc1pxQYCl0TeEbjsxXji3wZ0CItqXEk/wettggKnb5hlaBU1z6EiGdp2f7De
 Mx1IbciyUHEgSW9yzzuv94ZzWIkAVaKEi8gUiMSJBatJn7WFrpQrxD7aEGm2KV5vlsWKB7SqSJW
 WtS4okXZrAbEGQGFRH+hFgddp0eHGZX3WAEyBgR0NaPt0sUoFMW2QmovUFAeEScVCy+puZdKwe3
 GLE9pPCZyPRWgEdk2bl1XaxnnZJ+wa/Z724pbryOPx/XGP2Cld7DAgiQaTNYxTvK5Q0puBUoaFx
 eWFbqdupYvQ9r5fBAt6tFu+0LbK8To9ylptdOYwzFmLIFBfH/saQDQARRgI2gznL3xATV1UDMrA
 AJECdsfywp8KZqvE189QTe0NBFsktAw71L0A2LmT9dX699c0isV8Ks52dU6+xiIpECizTFSNkUI
 00CT5xZYa5XTm+WDFmyDHZWqEsV5erwrwWzHdrPAVkBvdC968m108HfBR0uJhLewZr0V5fW0x1T
 b8SspazuuKf3Ee33ppR0y8O2/uONXGz/KohqS0E8O833dylOAUCa8kRBRT5hd5w8EVAWcVwaZbv
 O8PzMa64wMKLTqA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop the regulator-always-on workaround from vreg_l14a_1p8 (vddi) and
vreg_l28a_3p0 (vpnl/vci) now that the LG SW43408 panel driver keeps vpnl
paired with vddi, allowing both rails to power down on Pixel 3 when
neither the panel nor the touchscreen requires vddi.

Define the supplies on Pixel 3 XL's framebuffer0 node so simpledrm keeps
the panel powered once regulator late cleanup runs, while intentionally
leaving them off Pixel 3's framebuffer0 node so simpledrm handover does
not drop vpnl independently of vddi.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts   |  2 ++
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi    | 10 ----------
 arch/arm64/boot/dts/qcom/sdm845-google-crosshatch.dts |  3 +++
 3 files changed, 5 insertions(+), 10 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
index a000c75494f1c..f916f4dbb89c5 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
@@ -14,16 +14,18 @@ &battery {
 	voltage-min-design-microvolt = <3600000>;
 	voltage-max-design-microvolt = <4400000>;
 };
 
 &framebuffer0 {
 	width = <1080>;
 	height = <2160>;
 	stride = <(1080 * 4)>;
+
+	/* intentionally no supplies here, see the LG SW43408 driver */
 };
 
 &i2c2 {
 	clock-frequency = <1000000>;
 
 	status = "okay";
 
 	/* ST,FTS @ 49 */
diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 3c9656b88b696..c025b2df4ea25 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -246,21 +246,16 @@ vreg_l13a_2p95: ldo13 {
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
 		};
 
 		vreg_l14a_1p8: ldo14 {
 			regulator-min-microvolt = <1800000>;
 			regulator-max-microvolt = <1800000>;
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
 			regulator-boot-on;
-			/*
-			 * We can't properly bring the panel back if it gets turned off
-			 * so keep it's regulators always on for now.
-			 */
-			regulator-always-on;
 		};
 
 		vreg_l17a_1p3: ldo17 {
 			regulator-min-microvolt = <1304000>;
 			regulator-max-microvolt = <1304000>;
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
 		};
 
@@ -308,21 +303,16 @@ vreg_l26a_1p2: ldo26 {
 			regulator-boot-on;
 		};
 
 		vreg_l28a_3p0: ldo28 {
 			regulator-min-microvolt = <2856000>;
 			regulator-max-microvolt = <3008000>;
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_LPM>;
 			regulator-boot-on;
-			/*
-			 * We can't properly bring the panel back if it gets turned off
-			 * so keep it's regulators always on for now.
-			 */
-			regulator-always-on;
 		};
 	};
 
 	regulators-1 {
 		compatible = "qcom,pmi8998-rpmh-regulators";
 		qcom,pmic-id = "b";
 
 		vdd-bob-supply = <&vph_pwr>;
diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-crosshatch.dts b/arch/arm64/boot/dts/qcom/sdm845-google-crosshatch.dts
index 2a81ca1d00b1b..7591c6ebb1cb9 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-crosshatch.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-crosshatch.dts
@@ -19,16 +19,19 @@ &dispcc {
 	/* Disable for now so simple-framebuffer continues working */
 	status = "disabled";
 };
 
 &framebuffer0 {
 	width = <1440>;
 	height = <2960>;
 	stride = <(1440 * 4)>;
+
+	vddi-supply = <&vreg_l14a_1p8>;
+	vci-supply = <&vreg_l28a_3p0>;
 };
 
 &mdss {
 	/* Disable for now so simple-framebuffer continues working */
 	status = "disabled";
 };
 
 &wifi {

-- 
2.55.0

