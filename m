From: David Heidelberg <david@ixit.cz>
Date: Thu, 31 Jul 2025 23:17:02 +0200
Subject: [PATCH v6 2/2] arm64: dts: qcom: sdm845-oneplus: Add alert-slider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250731-op6-tri-state-v6-2-569c25cbc8c2@ixit.cz>
References: <20250731-op6-tri-state-v6-0-569c25cbc8c2@ixit.cz>
In-Reply-To: <20250731-op6-tri-state-v6-0-569c25cbc8c2@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Jonathan Corbet <corbet@lwn.net>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, Gergo Koteles <soyer@irl.hu>, 
 Casey Connolly <casey@connolly.tech>, David Heidelberg <david@ixit.cz>, 
 Konrad Dybcio <konradybcio@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2333; i=david@ixit.cz;
 h=from:subject:message-id; bh=DXHdtGfW2ujmBmU5jNstKdQ/ztd3ylHZnqWhAQYlHgI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBoi91NRxOGFBofJhr/R5Qdt2mdrdvgOYd4CdEY/
 uWPxnDvh4OJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaIvdTQAKCRBgAj/E00kg
 cszzEADJPC237t0NxPire+2qZzcPXxWYcO+wmI15gTOVT6+wrSM23ipHcqO5jaIr1QgFY40i0Pw
 uPSgd3MFV3+u9K+FcYFzyuOkQZkXv5XD+YKZE/D3kXDUtAvEWZzj5Nt0nJGVWAKApTTqP9JdIa2
 Jdwz54VuKl4567SLe7fJsddZ68UH7cpsp5Q0yUMQtjvJ//I4a8dOaiNG1KnB+vI2iElRkRBFL5E
 bt5I6b5fnQKG1b+fg8ZeN7gUg70vRTl4oEk8dxwJnfogSJ4b9kNuHnfR39ku26Dssls3CIbsaq1
 u0cwdNRwfINl5xs93JiwrWE6jJNy4Vz5hLvOwc29SXBrKHAj+g8T4SAX3PUZM9mAq9klUss6yED
 uLa0mT7ni6OZ2jiKAMVNJ5X5goM0T+7ZxwE4GaLwO7bdEEPDkmksB5l+7vUHonRAJpebdisiOCj
 sZ54XzIFMtXCq4aYoy0MM2NVSpPITVlZNqYrq9p4Jko65xRp57tAUYfOD1AYLHpM7dP1oLlpwVP
 UF/66IcCB60tKcLLshWhHayu5d1XP9V9TK5ckGFahSmhEZKHa52G58HHceZEWsbXYQI1ZlF+0f+
 5ogFenEmvZzgy4KIhaqafM/gZQytYAD1WYct4b00z7hWrtjZNGg0yLTIIgE/zRkp1ILarCDBepu
 V/UDPYponoAfzZA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Gergo Koteles <soyer@irl.hu>

The alert-slider is a tri-state sound profile switch found on the
OnePlus 6, Android maps the states to "silent", "vibrate" and "ring".
Expose them as ABS_SND_PROFILE events.
The previous GPIO numbers were wrong. Update them to the correct ones.

Co-developed-by: Casey Connolly <casey@connolly.tech>
Signed-off-by: Casey Connolly <casey@connolly.tech>
Signed-off-by: Gergo Koteles <soyer@irl.hu>
Reviewed-by: Konrad Dybcio <konrad.dybcio@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 39 ++++++++++++++++++++--
 1 file changed, 37 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index b118d666e535a433f44b66c71b36e55df2ce5c80..242c78828992f9fbb384b690352660a496b22411 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -21,6 +21,41 @@
 /delete-node/ &rmtfs_mem;
 
 / {
+	alert-slider {
+		compatible = "gpio-keys";
+		label = "Alert slider";
+
+		pinctrl-0 = <&alert_slider_default>;
+		pinctrl-names = "default";
+
+		switch-top {
+			label = "Silent";
+			linux,input-type = <EV_ABS>;
+			linux,code = <ABS_SND_PROFILE>;
+			linux,input-value = <SND_PROFILE_SILENT>;
+			gpios = <&tlmm 126 GPIO_ACTIVE_LOW>;
+			linux,can-disable;
+		};
+
+		switch-middle {
+			label = "Vibrate";
+			linux,input-type = <EV_ABS>;
+			linux,code = <ABS_SND_PROFILE>;
+			linux,input-value = <SND_PROFILE_VIBRATE>;
+			gpios = <&tlmm 52 GPIO_ACTIVE_LOW>;
+			linux,can-disable;
+		};
+
+		switch-bottom {
+			label = "Ring";
+			linux,input-type = <EV_ABS>;
+			linux,code = <ABS_SND_PROFILE>;
+			linux,input-value = <SND_PROFILE_RING>;
+			gpios = <&tlmm 24 GPIO_ACTIVE_LOW>;
+			linux,can-disable;
+		};
+	};
+
 	aliases {
 		serial0 = &uart9;
 		serial1 = &uart6;
@@ -799,8 +834,8 @@ hall_sensor_default: hall-sensor-default-state {
 		bias-disable;
 	};
 
-	tri_state_key_default: tri-state-key-default-state {
-		pins = "gpio40", "gpio42", "gpio26";
+	alert_slider_default: alert-slider-default-state {
+		pins = "gpio126", "gpio52", "gpio24";
 		function = "gpio";
 		drive-strength = <2>;
 		bias-disable;

-- 
2.50.1

