From: David Heidelberg <david@ixit.cz>
Date: Thu, 24 Sep 2026 16:01:37 +0200
Subject: [PATCH v2 09/11] arm64: dts: qcom: sdm845-samsung-starqltechn:
 Update panel compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-crosshatch-panel-v2-9-08d5c7bf72fc@ixit.cz>
References: <20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz>
In-Reply-To: <20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1462; i=david@ixit.cz;
 h=from:subject:message-id; bh=mO5/aAEZbBdx1nt31w9gZYWlTQTbXXTVDaFrlxUGvuo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtS09f21HWVr6wGidI7N2CXXhMb3+ZQJXPIX3X
 LhH8LqTx2yJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUtPQAKCRBgAj/E00kg
 ctPJEACSk1nGor5Xs1UmrLupod4cREi2ILeZQPXlTeh2veAX8fCq6MPY79gstJiQzoGqiKYm9hZ
 M3qdA6qiH6Xo/zYaL6o5L2Tx/cfpdPunQdsalsJUBLxCidWbfJaerD4o48NdC3sTP/JxeFcq1Ct
 EUaRMxNa4aYsiBaAyNJ1qbalESLKxCi8myhGag53uEFk3KQrtPbY1XuGyZEKma3LcSVAAKWufIG
 j07Nikkpqr0G6w4OA5HYiMBiNIYEBLB5c4kyskM7Qli/EwGTAkGYV8AM+g9+h1FOhq1DMnpouOr
 0sgNNkYDdLhSyk0bCUTT5irxQDcvr6xIuzzKidvEFdHL5IZ2Rk3BTr7Xn9dKGMEug3cAM+rLhzr
 T6+DdLqBCCtruy5vUILF9IJr5ztjKlBUFnsdiEYzd+oP6Z6KXPJ0+JA++2iPUPx3hDYTTn+YWuA
 SUIgxHdjKfJdR5ZoV8OMN2PMtHIUz/pRctstDpeszcWUglqTS8txx1XjptDxiSoKwgqGhYAx9xR
 HfS14mk5d90WsuQ36BAuWFhcYNpEWNEwDwoGL+oWmVGkFEB8liEq5LqyhIOgmAdI4cGKwF0k5nY
 b8z5kNTjQEAoAwHZzeO6n4v9c/jVIqnAmIFX58fSiQxL1lJTnrNdixSgRefw/PC5CEvPudbEiEr
 Tqwo0Rmr8VxQYSQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Original compatible describing only the DDIC used, but omit describing
the panel used (Samsung AMB577PX01), which we have no way to detect.

New compatible allows without breaking ABI fixing the inverted reset.

Assisted-by: LLM
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

