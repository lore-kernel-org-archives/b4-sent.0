From: David Heidelberg <david@ixit.cz>
Date: Sun, 02 Aug 2026 14:42:42 +0200
Subject: [PATCH RFC 3/3] arm64: dts: qcom: sdm845-oneplus-fajita: Enable
 speaker codec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-tfa98xx-upstream-v1-3-4dd55cdd658a@ixit.cz>
References: <20260802-tfa98xx-upstream-v1-0-4dd55cdd658a@ixit.cz>
In-Reply-To: <20260802-tfa98xx-upstream-v1-0-4dd55cdd658a@ixit.cz>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1636; i=david@ixit.cz;
 h=from:subject:message-id; bh=jfc8/ssQ2PwWrFcsQPsWbLM3HVG5aaZh0yH7VMAE9ek=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbztF/6V6YQjlQWKENweA8e5wnpFz2pRL0gABo
 dwJeCYJgvKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCam87RQAKCRBgAj/E00kg
 cr3IEACX+Q7zD82+2I8YuD02BBGDQyaEHjodKUiZBChlOvJmhsdvK4GwmGRTn501vqrnD4taycD
 lwcSH8jzYADB94qysIuNbw1cMGJA8QuCYasa9wfDLpGLKXWnt5wSKmhzZB/ESoMO2bnXKoHX58Q
 b4i49dzobd31gFjfLysbp79Xk989pqUGk/D99BfFmBrMovSDWgy4mh0vz2hAV0a9kJr1FtKTdiK
 KbmLXHWES3DpmjlSzFQPUWnyd7+paMHySe/rEe7mPlwWZcWK1VIPA57aWSddRXx+RHD32pBC+F/
 LyOfIOLs0qkTI9wHuJnb8wwmNu3Chj2I0cc1uYVmJSQlDm8zP2Wl0FDAoQNyyORosNlT2JhF4Z3
 Dg10IZ5d6afohpuqZJSS4Hou1VOmn61in2j/v69znKYX46QHLGdwUpEGrz1T0aUPyl8t48Jat0U
 SjnpPFQbdmQvYPlCsM4KxEDODAPfl+GhxDa894ppdcZHjjjTzwESA266cCcH44bT62ofuNuS20G
 Wrntx+M/YDpkfTKKCRIYtdbQE8ICL7sx9nk8Y2s9+t+WNdChVF+Vw/FI3FNu8Y5Wf/7Psq6f/XV
 UrawLiaSL7QFQMWBWboaKM49xrQax+/L8euU2Om93s0Npo6uGcQcZBFcrfkf2J+AGw9MPB8MKbZ
 RJfhKVGcVLJYoQA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

OnePlus 6 uses NXP TFA9894 audio codec. Enable it.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts | 22 +++++++++++++++-------
 1 file changed, 15 insertions(+), 7 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
index 0542333a83579..cb08aab4740a4 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
@@ -35,17 +35,26 @@ &display_panel {
 	compatible = "samsung,s6e3fc2x01-ams641rw", "samsung,s6e3fc2x01";
 };
 
 &framebuffer {
 	height = <2340>;
 };
 
 &i2c4 {
-	/* nxp,tfa9894 @ 0x34 */
+	clock-frequency = <400000>;
+
+	status = "okay";
+
+	tfa9894_codec: audio-codec@34 {
+		compatible = "nxp,tfa9894";
+		reg = <0x34>;
+		reset-gpios = <&tlmm 69 GPIO_ACTIVE_HIGH>;
+		#sound-dai-cells = <0>;
+	};
 };
 
 &bq27441_fg {
 	monitored-battery = <&battery>;
 };
 
 &sound {
 	model = "OnePlus 6T";
@@ -56,22 +65,21 @@ &sound {
 			"AMIC4", "MIC BIAS1",
 			"AMIC5", "MIC BIAS3";
 };
 
 &pmi8998_charger {
 	monitored-battery = <&battery>;
 };
 
-/*
- * The TFA9894 codec is currently unsupported.
- * We need to delete the node to allow the soundcard
- * to probe for headphones/earpiece.
- */
-/delete-node/ &speaker_playback_dai;
+&speaker_playback_dai {
+	codec {
+		sound-dai = <&tfa9894_codec>;
+	};
+};
 
 &rmi4_f12 {
 	touchscreen-y-mm = <148>;
 };
 
 &wcd9340 {
 	qcom,micbias1-microvolt = <2700000>;
 	qcom,micbias2-microvolt = <2700000>;

-- 
2.53.0

