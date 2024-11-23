From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sat, 23 Nov 2024 12:05:53 +0100
Subject: [PATCH 3/4] arm64: dts: qcom: x1e80100-vivobook-s15: Add lid
 switch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241123-asus_qcom_display-v1-3-85a9ff9240aa@hotmail.com>
References: <20241123-asus_qcom_display-v1-0-85a9ff9240aa@hotmail.com>
In-Reply-To: <20241123-asus_qcom_display-v1-0-85a9ff9240aa@hotmail.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Douglas Anderson <dianders@chromium.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732359972; l=1398;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=2Fsv6gofTnQRjFCbk36VF6plX1Xp9Ps/3F/wjNK21VE=;
 b=Um8NXi0h8NeArK/WBUEadfl1aT/oMvEnxcaHDshwHy+Y1tzpsA2MGi46Hw25Te+E0YS1lt1DH
 I4a6W+NvsPqBpY8Y/PONwP6Pyo2mTdUv0LnEHhq0qIwCqVYOpp9yznZ
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the lid switch for the Asus vivobook s15

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 .../boot/dts/qcom/x1e80100-asus-vivobook-s15.dts      | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts b/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
index dbc85aff50a95bfc2ac11528d1901979ec7b1501..109b9d8816d26550ccfcb9906d69f2745d02f1d3 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
@@ -17,6 +17,19 @@ / {
 	compatible = "asus,vivobook-s15", "qcom,x1e80100";
 	chassis-type = "laptop";
 
+	gpio-keys {
+		compatible = "gpio-keys";
+		pinctrl-0 = <&hall_int_n_default>;
+		pinctrl-names = "default";
+		switch-lid {
+			gpios = <&tlmm 92 GPIO_ACTIVE_LOW>;
+			linux,input-type = <EV_SW>;
+			linux,code = <SW_LID>;
+			wakeup-source;
+			wakeup-event-action = <EV_ACT_DEASSERTED>;
+		};
+	};
+
 	pmic-glink {
 		compatible = "qcom,x1e80100-pmic-glink",
 			     "qcom,sm8550-pmic-glink",
@@ -537,6 +550,12 @@ edp_reg_en: edp-reg-en-state {
 		bias-disable;
 	};
 
+	hall_int_n_default: hall-int-n-state {
+			pins = "gpio92";
+			function = "gpio";
+		bias-disable;
+	};
+
 	kybd_default: kybd-default-state {
 		pins = "gpio67";
 		function = "gpio";

-- 
2.47.0

