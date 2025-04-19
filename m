From: David Heidelberg <david@ixit.cz>
Date: Sat, 19 Apr 2025 21:46:25 +0200
Subject: [PATCH v5 2/2] arm64: dts: qcom: sdm845-oneplus: Add alert-slider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250419-op6-tri-state-v5-2-443127078517@ixit.cz>
References: <20250419-op6-tri-state-v5-0-443127078517@ixit.cz>
In-Reply-To: <20250419-op6-tri-state-v5-0-443127078517@ixit.cz>
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
 h=from:subject:message-id; bh=QhCUbDmUHcz4RzxVc6XbeZUejFzQoncYw+4pfYDvJbY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBoA/2SXNUW9FmCVx/sofCVR1893e6A0Pgi0fk2t
 /vlzsdqOCOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaAP9kgAKCRBgAj/E00kg
 clf8D/9u8uPCDLrbj2Z6HGbMlLcVBRPLnOb//zm6tNBBYYlkWtuSbIA4+ziaEy7T7v9mYMzPyVy
 L0lRRx62HtcjCdCaOvfebpZUh8tJ0xOJ/5wzORGEsHbsBVseMdjZi7cddRm0FXw//3e3tPdlqfX
 J+MmSRz2RDYsavYWjVdcnmSXmIni9aLGBWTg+hAY2WK+8Cn003wZ5E5wi02KMhprT36HNVVQsWK
 994To8W4xb/LMsUmYf0LD3ImbBYVyEAixDeIW2Ondy7TtuQN80KH9Dzzw2KDBj0j35mWjJWUuzs
 96htMIWpmGPuUsQoaR05EmetYyynt6eHdnEs0LeWLxtpGbacZwJSIZRXqnsGDEDpqCIv3M3atqH
 +Fbsa2vgJSeH4AJgGsUM62WIdXWCs9bgez5JuwsZsV3f5nYiNgTrR6Wa+6btvPNTKaVG0zJK3Qc
 nGMILNV0iaeCpbjby8Z+6rQOagCNa31ELCp4UUun7wPmFX6N6fIWrKlvos+mccgOluIcl1n3/+A
 +6BqBxepc/MC6tYCiGGg+wqvokSUY9i5YLHsCk3NVLtUH8qmIbbPXs1raRaS0K+LGTdggQu4Kc4
 XFUsiABTxGtUw0vWH8NLYUJajZIqiBv2Hbf/4LU0MITDguUfmwjiBTFEXDnVld1N/oooKnZqIEz
 TO1xwGF/KlLHmTA==
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
index 8a0f154bffc3d55ae2134ef28cb7653dde702552..9a508b3149bef50c0ed897dec3c01a3f08712e85 100644
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
2.49.0

