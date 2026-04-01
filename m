From: David Heidelberg <david@ixit.cz>
Date: Wed, 01 Apr 2026 18:51:43 +0200
Subject: [PATCH v2 1/3] arm64: dts: qcom: sdm845-shift-axolotl: Enable
 sdcard
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-axolotl-misc-p1-v2-1-f3af384bbb50@ixit.cz>
References: <20260401-axolotl-misc-p1-v2-0-f3af384bbb50@ixit.cz>
In-Reply-To: <20260401-axolotl-misc-p1-v2-0-f3af384bbb50@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dylan Van Assche <me@dylanvanassche.be>
Cc: linux-arm-msm@vger.kernel.org, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1795; i=david@ixit.cz;
 h=from:subject:message-id; bh=aZdwStcvm+sP0/bffqiFYiM4zgFWPvHavag314QPrS0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzU0jT7/hxZAeWt3scy/df6V3dYcWoYPRU+h2T
 9fov0vKJ9+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac1NIwAKCRBgAj/E00kg
 cglOD/0dGUViocQ/HGt1FG9pRpZRjK6UR7xNAWdv10rQ5ScXXVxYF6bLeIcIeIDCmOPU+zQwR8A
 xfR42u7WkQl3mSAtbRwtQcs1dZ/ys5f/V2nzHOZR3jYeboNB0VHaMun/ViulUzzMku039fgPvKh
 LgXhxNHqgoPJcUinBv1gX+HpCtTY2pic31B4e+41kNVbm+w/8vhBlpTeiiDTS4HieXSeirp81Lx
 KCVE4d7R0LHrshAsXzL/yZNnZRIcC4XGJDnkmAgVb+a4t74SgXErQ3SYQYmH79PzqM6FD9ljkFM
 uZmpquC7WEPtZ9xogfKp7T6Vj2dC6VGT8PyHD6hg75+Kn6rROLWZ2smAykozlrNQdN+3n5iGMz+
 LtAggvVxDmyiuHJKAPd43nHrgzlzWEiMa0cW/6ElVcy7S974fOw33XvERJAuVoMnGdIe92VXGYn
 sqBN+zFPm9RNCdlXiDhzIB3Rn3xM3n7R2X0+4eiWbuNYRY0GrtI94O/cNmkzSX6Uqt5TyD86LNt
 iZI9aWbmTNEjcHc8j5x+cE3hjs1aiJUC3cxTNUwOwiTF7pNbFbEsFK+h0qjlno0aWS2uWgvRciO
 lJL1bhGROezTm1QsYxjWUQ3g7NlNCHxXnnoEP4wCoPAv3j98eRC3DB1ImkQVR/478ujLXsCh8Q3
 owvkhFrh11Oue+Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

The SHIFT6mq features an sdcard slot, add it.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 44 +++++++++++++++++++++++
 1 file changed, 44 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 740eb22550724..c394350998c26 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -600,6 +600,24 @@ &qupv3_id_1 {
 	status = "okay";
 };
 
+&sdhc_2 {
+	status = "okay";
+
+	pinctrl-names = "default";
+	pinctrl-0 = <&sdc2_default_state &sdc2_card_det_n>;
+
+	vmmc-supply = <&vreg_l21a_2p95>;
+	vqmmc-supply = <&vreg_l13a_2p95>;
+
+	bus-width = <4>;
+	/*
+	 * Card detection is broken, but because the battery must be removed
+	 * to insert the card, we use this rather than the broken-cd property
+	 * which would just waste CPU cycles polling.
+	 */
+	non-removable;
+};
+
 &slpi_pas {
 	firmware-name = "qcom/sdm845/SHIFT/axolotl/slpi.mbn";
 
@@ -609,6 +627,32 @@ &slpi_pas {
 &tlmm {
 	gpio-reserved-ranges = <0 4>, <81 4>;
 
+	sdc2_default_state: sdc2-default-state {
+		clk-pins {
+			pins = "sdc2_clk";
+			bias-disable;
+			drive-strength = <16>;
+		};
+
+		cmd-pins {
+			pins = "sdc2_cmd";
+			bias-pull-up;
+			drive-strength = <10>;
+		};
+
+		data-pins {
+			pins = "sdc2_data";
+			bias-pull-up;
+			drive-strength = <10>;
+		};
+	};
+
+	sdc2_card_det_n: sd-card-det-n-state {
+		pins = "gpio126";
+		function = "gpio";
+		bias-disable;
+	};
+
 	sde_dsi_active: sde-dsi-active-state {
 		pins = "gpio6", "gpio11";
 		function = "gpio";

-- 
2.53.0

