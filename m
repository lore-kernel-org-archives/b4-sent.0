From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Aug 2026 15:56:40 +0200
Subject: [PATCH 2/2] arm64: dts: qcom: sdm845-oneplus: Define touchscreen
 in the detail
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260819-oneplus-ts-quirk-v1-2-0cdbcea195a2@ixit.cz>
References: <20260819-oneplus-ts-quirk-v1-0-0cdbcea195a2@ixit.cz>
In-Reply-To: <20260819-oneplus-ts-quirk-v1-0-0cdbcea195a2@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Marcus Ramberg <marcus@means.no>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2582; i=david@ixit.cz;
 h=from:subject:message-id; bh=RZY4dkp9L4vG2YEomAXZZWWwCLxe2KNXm/xHA0DScVU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqhbYXFlxsXQQ7VPvnnXgi1kNweny7uhqCPCLWR
 aev2tEbH3uJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaoW2FwAKCRBgAj/E00kg
 co42EAC4/045CoKchklXgBWQA5SUhNiPac+6/WZtTVxR5UsZBUl3g3b7s9SAMJbdmBaLNtC5QnH
 imwSHB2O1yelxO9zJK84sh5rT6bFqeHbEWdwfbIFju5BVFWSX569dMJcZq0qKJ1/XsuBzh6uMa7
 0sDTmv9x9mrfujCOu3z3w5/AUQBmTmhQzSy5Jpi2V2eUuBojAR85a6N8pv78MGWzJY4cWdZPuPt
 VitCLMAP0Kn2GrN6Z74hGDwGkcb5Jh7H7iROQ+ozBFA3W1ZOVnqjemG0yI+fvD0zUy6Kev1bkbJ
 AMBzalRhziRmUupUyv0SJCv1kx2Qnq5nplBID74QjBt8oBZ7oZ+9TZwpxEQn903wNnGMC/M4fvk
 mHEqQOolotn19w7/sWsLZpI33WtJsrkq4I71YQXOG91Pw+B65jH9g3usHkWoBWO3fxOBMcKlquD
 8mv6UJMUYJtsbzb7pdIAhcLfvn76cVJ/I4KNgPfpxek5M8TrgKrkxDSZPSk25VrmD08Lx4Fji8D
 js5eoKZMmZ7FJD7+S6nGeqtDojZdy2Jq7YwP2Zr+065o0foO9Io/ZRTEaAK79bOlWi+Ejl6WCF3
 wmu3N6ooWjMTnrzY4dVirs3Xea3FLd3n/AAG3WI8PB6wJ/0sXMwGlgj6H5UFThoR/HNzeTwVoVD
 uHTQdDX878G+Dlg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Once probing, aftermarket touchscreens report touch over 0..65535
which is unusable. Be explicit in device-tree to avoid this issue.

This change should be irrelevant for original touchscreens, which
reports proper values.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi   | 1 +
 arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts | 1 +
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts    | 1 +
 3 files changed, 3 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index fead66d60e58d..4e65c2368c728 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -538,16 +538,17 @@ synaptics-rmi4-i2c@20 {
 		rmi4-f01@1 {
 			reg = <0x01>;
 			syna,nosleep-mode = <1>;
 		};
 
 		rmi4_f12: rmi4-f12@12 {
 			reg = <0x12>;
 			touchscreen-x-mm = <68>;
+			syna,clip-x-high = <1079>;
 			syna,sensor-type = <1>;
 			syna,rezero-wait-ms = <200>;
 		};
 	};
 };
 
 &ipa {
 	firmware-name = "qcom/sdm845/OnePlus/enchilada/ipa_fws.mbn";
diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
index be346286e19b3..276217f7216b5 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
@@ -92,16 +92,17 @@ led@5 {
 			reg = <5>;
 			color = <LED_COLOR_ID_RED>;
 		};
 	};
 };
 
 &rmi4_f12 {
 	touchscreen-y-mm = <144>;
+	syna,clip-y-high = <2279>;
 };
 
 &sound {
 	model = "OnePlus 6";
 	audio-routing = "RX_BIAS", "MCLK",
 			"AMIC2", "MIC BIAS2",
 			"AMIC3", "MIC BIAS4",
 			"AMIC4", "MIC BIAS1",
diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
index 0542333a83579..e9d1a1c6ac596 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
@@ -65,16 +65,17 @@ &pmi8998_charger {
  * The TFA9894 codec is currently unsupported.
  * We need to delete the node to allow the soundcard
  * to probe for headphones/earpiece.
  */
 /delete-node/ &speaker_playback_dai;
 
 &rmi4_f12 {
 	touchscreen-y-mm = <148>;
+	syna,clip-y-high = <2339>;
 };
 
 &wcd9340 {
 	qcom,micbias1-microvolt = <2700000>;
 	qcom,micbias2-microvolt = <2700000>;
 	qcom,micbias3-microvolt = <2700000>;
 	qcom,micbias4-microvolt = <2700000>;
 };

-- 
2.55.0

