From: David Heidelberg <david@ixit.cz>
Date: Sun, 08 Nov 2026 12:32:29 +0000
Subject: [PATCH v3 08/10] arm64: dts: qcom: sdm845-samsung-starqltechn:
 Update panel compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-crosshatch-panel-v3-8-87dd4ec4f7cc@ixit.cz>
References: <20261108-crosshatch-panel-v3-0-87dd4ec4f7cc@ixit.cz>
In-Reply-To: <20261108-crosshatch-panel-v3-0-87dd4ec4f7cc@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1444; i=david@ixit.cz;
 h=from:subject:message-id; bh=x6P5UdtWDbDVtREtjJhW7uE5AV7f8NAB6Gz3Qx7Wn2k=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq8GvfpE76WxZbbuHgYNw7/amRn5Y4xNwub3ONk
 18lfENrVPeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavBr3wAKCRBgAj/E00kg
 cnBDD/9ifPfx37wSDxdubEvukkufVdYXyzuaauRzzvEcZv1yQFKHdRZrQqGuF1X09cWyPHtsWUO
 u41NdafRPKWDSLTELibxJsxCWFe/Lejeue5VYYI2csrSz9Q5S3Dnr78Uu0RAviIk/1JZI9z6CEe
 iY6YkNTJuOYBK9QlshsJGBGwIJOVcWeotdxQd1rSMRhULuRVmsIcboe5o8iMKYSACaut8YyNu+m
 o674qI7xOG4QSNOlyp7+Mg0NBxeYAmontqBmifPYXBS+TP6yG5tsBBlr45ylEY2/mh2eWVP+Ywx
 QFXNmXTEUIcsxp5lPe1NZCMF7OskbTIMmpIweiZOVE5bBfh5VIqAIlgc7HME0gqFCoNaViYt5Bf
 oycUHwi1lCQ77vvhf9efczm0jrKvb+expyq6iPG//CuL6XWijIYlWW+GiufhziYW37gbmMOT0Nn
 qtL/2qWdYGRXBO1IBuERF8ANUvRrdPCDcsOeF9/9JMlnYK7tcHIdT3zsk2eqtM6YjmEbJI/iGXt
 Vri5VI3x34oETQBUMAy7ZiJ1buORYs5whZgZjueb1L+Qfkps88yUc2GH3JkrjMt4Ze/OCPcl9jT
 fsY20DNS715onNXcILRolqHixhluUA1iI4C7A7TjqRzUve6Ul11d3PxmKkWAg0US81AgQ9Y1F22
 8e2lTCeRXkxK62w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Original compatible describing only the DDIC used, but omit describing
the panel used (Samsung AMB577PX01), which we have no way to detect.

New compatible allows without breaking ABI fixing the inverted reset.

Reviewed-by: Petr Vorel <petr.vorel@gmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts b/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
index bd59f1dcd96dc..c156ed3733b4e 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
@@ -262,23 +262,23 @@ &mdss {
 	status = "okay";
 };
 
 &mdss_dsi0 {
 	vdda-supply = <&vreg_l26a_1p2>;
 	status = "okay";
 
 	panel@0 {
-		compatible = "samsung,s6e3ha8";
+		compatible = "samsung,s6e3ha8-amb577px01";
 		reg = <0>;
 		vci-supply = <&s2dos05_ldo4>;
 		vddr-supply = <&s2dos05_buck>;
 		vdd3-supply = <&s2dos05_ldo1>;
 		te-gpios = <&tlmm 10 GPIO_ACTIVE_HIGH>;
-		reset-gpios = <&tlmm 6 GPIO_ACTIVE_HIGH>;
+		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
 		pinctrl-0 = <&dsi_default &dsi_te>;
 		pinctrl-1 = <&dsi_suspend &dsi_te>;
 		pinctrl-names = "default", "suspend";
 
 		port {
 			panel_in: endpoint {
 				remote-endpoint = <&mdss_dsi0_out>;
 			};

-- 
2.55.0

