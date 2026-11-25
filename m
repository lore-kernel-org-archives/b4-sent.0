From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Nov 2026 19:12:52 +0100
Subject: [PATCH v4 8/9] arm64: dts: qcom: sdm845-samsung-starqltechn:
 Update panel compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-crosshatch-panel-v4-8-120adc58e737@ixit.cz>
References: <20261125-crosshatch-panel-v4-0-120adc58e737@ixit.cz>
In-Reply-To: <20261125-crosshatch-panel-v4-0-120adc58e737@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, Abel Vesa <abel.vesa@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1497; i=david@ixit.cz;
 h=from:subject:message-id; bh=mkxVrIpbAVEtMAGbgohHi1tEOw9U/nu44YtOaqkhOKA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrByUeUCj8JXk8HfdS7gJ6Hh+5fJFHcs4+F6ByI
 M5RKPhtxK2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawclHgAKCRBgAj/E00kg
 cuMoD/wJI6NkkyxeycrWfjgnO5bqmxt6xGPflHA7v7lshuX7fs6IrhhneCXg7SuTXEQDwmDO7io
 XUo1d/et6E0pLtMuO0C9ZGZfQ/ljDjP984HZxsBaGNNXsYILsBWO9xcLuJqqSha20nU9FExbIBB
 48BFW526HfyPtetgXyqwqV3MoYKIjAT+cwSajMln0ycxN81uOJb0Gg+8RJEvZK9CBPxA6n6FXba
 7KSJHFx6MGuWIBAz6Db2EMTM6bOim6qnWAZcDgBJC4WHX1Ol1ImTEeeRlHia7U/WE7iwVsBA0Xl
 lXoqALZwNoSktFA43G/qWrWT4qZfCuXVnob38cjC2+rQjc1g0abHl8JZcnko9iACr89eUiCa5Lg
 LlDDjvIDIrFTgD8bUW7VTBIGUhAn1jiMd7v3bYllfPqp78XzveCCZwpXslptAlREhiN7J5+F2BP
 tDED2AV2mRrbt0pHrWktZAr7IX7NDDXA6eAJSioOwDXERkxFcuwMpt7wa1K6HlbbqzLQTqKJhIK
 p73GOVjncaqYxedTnYR4vg3vAjM4gitZURLMs11+bkOg8fMU5oi4WZgu/9pK3lOBKE3Ad2h95Iw
 Tj7vAHwMoP69rbdeBeBoiQNMgV+pyErRZAOG1pAxlZRhDRwWL1IWOIfZMDtFLXAcTyKyMDYWRIQ
 J1ePZ5Q0zzaQHYg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Original compatible describing only the DDIC used, but omit describing
the panel used (Samsung AMB577PX01), which we have no way to detect.

New compatible allows without breaking ABI fixing the inverted reset.

Reviewed-by: Petr Vorel <petr.vorel@gmail.com>
Reviewed-by: Abel Vesa <abel.vesa@oss.qualcomm.com>
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

