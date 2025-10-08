From: David Heidelberg <david@ixit.cz>
Date: Wed, 08 Oct 2025 16:05:31 +0200
Subject: [PATCH v2 4/7] arm64: dts: qcom: sdm845-oneplus: Describe TE gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251008-s6e3fc2x01-v2-4-21eca1d5c289@ixit.cz>
References: <20251008-s6e3fc2x01-v2-0-21eca1d5c289@ixit.cz>
In-Reply-To: <20251008-s6e3fc2x01-v2-0-21eca1d5c289@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=802; i=david@ixit.cz;
 h=from:subject:message-id; bh=6dQxM0IMSr3zsyolXreEE2WPEzcxlj+3dZAUqGx7Ra4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo5m+oxJlepJwVpuhRk+jL6sBj30CNdaZGLqKzR
 MsZtOZOaJaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaOZvqAAKCRBgAj/E00kg
 cguHEADOxL2F+63NYgqSUUh7HyAP4sZyLpY2ZDmDm0jGwTEaqCDsSMZz5ELYrGqRmoe5TyzK7GL
 ArfakhFNCUZdiq0G6BOggDFcZwY8EI/W7zJ94D16EJnU7aVvpnOezbXUm6V5NVWrCrpdYl6+n+2
 gTs7s82g6pRoF0Q1BexTpis8KWas8vTUxPleN5LzQO1aPU2fdEOc/gD97T6u7cLoQHLwMYXgdAg
 cEhbk8+7JshZL2FcukepFAAF5kAWaQigsiJeUuctaWJtPTj1uQKyT3Vb++SdBOouZ8AJn5+2Gt2
 wT7sc8WfHLOPpDYClYzUi+he5mb3jiZ13aqUIuEXJcf8m5cZrRxgFS2lk3hmt8snUuqRaBx2w2r
 o2FiNwLiM8QAhdbuQS+d/hlWt/DOV+bnfvjEJ2Lzg7+z2iPG/3+mWr4k65R1g9TTfhmihFm0l+i
 0414Ow31o/ZghCuBS3lUYW+kL+tiB6u/16cCIy+nn+xqUKqahYnR4R/aWr0zSr3Hdrp2pr/OtTR
 wJM3M2nBI03whrav/RqXtdT71t+Le2qoTs3V3B71ADm6Dmx9QiLf+lwC1EvfCfjgziAKnHGNPKj
 HcTBmmKffxY59mhrUnA+nE/7s02Fg5V/UaLY7xb7ia2+cDIvsAn8g9QJww8Wk1a3i5Ki2edT54t
 cEunZwKbYXTnm1Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe panel Tearing Effect (TE) GPIO line.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 1cf03047dd7ae..75989b377f8bc 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -460,6 +460,7 @@ display_panel: panel@0 {
 		vci-supply = <&panel_vci_3v3>;
 		poc-supply = <&panel_vddi_poc_1p8>;
 
+		te-gpios = <&tlmm 30 GPIO_ACTIVE_HIGH>;
 		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
 
 		pinctrl-names = "default";

-- 
2.51.0

