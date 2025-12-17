From: David Heidelberg <david@ixit.cz>
Date: Wed, 17 Dec 2025 12:39:23 +0100
Subject: [PATCH v2 1/2] arm64: dts: qcom: sdm845: Introduce camera master
 clock pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251217-sdm845-mclk-v2-1-7028c2d09145@ixit.cz>
References: <20251217-sdm845-mclk-v2-0-7028c2d09145@ixit.cz>
In-Reply-To: <20251217-sdm845-mclk-v2-0-7028c2d09145@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2039; i=david@ixit.cz;
 h=from:subject:message-id; bh=cTUXa+N953sv5GxQGdBXyAR0p0U/nn2ORgNoDyha5zM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpQpZrjyrLIEO33W/yON0eBpo3ZJGTkEg+d6onq
 vjDiyLzhlKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUKWawAKCRBgAj/E00kg
 cgzCD/9DaIPYE3l3aFYA49lwXZi905wJ7LMUxGqKLVRoMzQ3/2nWHPdD0bRc7dUgoF0sDLpNsX9
 XqF7/kCC3eILkDb4xeoygrI7dt2uqwGgtyFj5UDxK2y4jE+cmrhusQBbaS3nzXuaBkNAU6Axx8I
 w/5dwe6bWxk46Yfif1+zyDiZmXZFEPFG6d+RjXT2GGI7wlt6HxkEHb0GWu/kpcHN73RjsNFhSKI
 qcRjE2Kr4JWJFYlfjS7K/Imvos9LyPvTzYAkk+HGJjwqWatNp6b/kDVI5qKH4HFOw91Z4cRsyMJ
 p2yq0zcKu07cQWhf/qKNuTpJv7307I/bxNOol3FvNM+zNARIgR/bBTPQhyQtYSCxGAUxIT32hY8
 vFJ/YqePaXUYCS+1L3RjwJE0qT2Zxiql/Iy4uswP/Vh/J2fSyMMq8mT/lTnKdDy0Yb9HfKnGc5d
 40gogk/T26Sm+x2Wv7fJhqniUTcJqbujICHsVBCQ5bsGRCnCq0BfJUZzKD/9NsRDiM8Cfn4yaXn
 6HCXAPKY6nKmNFyV648p+xVoXLJjT7eYis/FyX++A2CX1lS7VTc3oy5Dg687XoIaSVPBZshwaZO
 6YBzP6e5oo10/LGjR+MZcPsX/BVoQowc9EV37sT8yH7SJNXKWEZkCSeb3UrYevXzMK7SEXbHt8f
 jDlw2c248fndF/A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Put clock pins configuration for camera master clock into the dtsi.

Reviewed-by: Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845.dtsi | 56 ++++++++++++++++++++++++++++++++++++
 1 file changed, 56 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845.dtsi b/arch/arm64/boot/dts/qcom/sdm845.dtsi
index bf2f9c04adba7..c0f21a745fb0c 100644
--- a/arch/arm64/boot/dts/qcom/sdm845.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845.dtsi
@@ -2805,6 +2805,62 @@ tlmm: pinctrl@3400000 {
 			gpio-ranges = <&tlmm 0 0 151>;
 			wakeup-parent = <&pdc_intc>;
 
+			cam_mclk0_default: cam-mclk0-default-state {
+				pins = "gpio13";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-disable;
+			};
+
+			cam_mclk0_sleep: cam-mclk0-sleep-state {
+				pins = "gpio13";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+
+			cam_mclk1_default: cam-mclk1-default-state {
+				pins = "gpio14";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-disable;
+			};
+
+			cam_mclk1_sleep: cam-mclk1-sleep-state {
+				pins = "gpio14";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+
+			cam_mclk2_default: cam-mclk2-default-state {
+				pins = "gpio15";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-disable;
+			};
+
+			cam_mclk2_sleep: cam-mclk2-sleep-state {
+				pins = "gpio15";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+
+			cam_mclk3_default: cam-mclk3-default-state {
+				pins = "gpio16";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-disable;
+			};
+
+			cam_mclk3_sleep: cam-mclk3-sleep-state {
+				pins = "gpio16";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+
 			cci0_default: cci0-default-state {
 				/* SDA, SCL */
 				pins = "gpio17", "gpio18";

-- 
2.51.0

