From: David Heidelberg <david@ixit.cz>
Date: Wed, 18 Nov 2026 18:25:43 +0100
Subject: [PATCH v2 10/12] arm64: dts: qcom: sdm845-lg: Enable vbus support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-pmi8998-vbus-v2-10-3c77a72b280a@ixit.cz>
References: <20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz>
In-Reply-To: <20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz>
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Robin Snyders <robin@snyders.xyz>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 linux-pm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=933; i=david@ixit.cz;
 h=from:subject:message-id; bh=zzz1wDCTzc1/fIjXGnK2jf9q0XuYTFpC4inv6HpNgto=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/d+XjjM2rY8s2yzYBWJxS4HXESt1659FNQHKM
 trBglWfKK2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCav3flwAKCRBgAj/E00kg
 ckU/D/9X9hSuPKpnrY3w9JVtGO+oAT0DR9sSfV5c4waWBsyepm6QCrimBCLO2hcHv+KIyhgydb7
 4cjlF3RmDu12/YYWKOb4cmAIj/17vwUSHMiuJFehk2Evo8E6qh0+vuDwd26PNPuloM2gXjERNUJ
 rUyVZ/exJlWlikakdwgadlBbWrM6oYTeSTKrAdjrAjbOfrvrsJNdmfJFTivn6VCPOO6D0Nf2yth
 N6WETfrp21jTbQOdcnp5IrT4cAg8T/SHrjkjXIARf+MoOV4Ole7jEOoKo8ALrdnUoBUWZVkYcLe
 y2DIjdQrj78lvKXZ8jPvnGjg2ktgV1OeUbYPtUxRJWh8O3VGrJkSgyuo41RsbLZshxLRa5NXTHZ
 onVnXIOHkiv2pYqkUWNz06m/pJBBiCs+/CtpMT6YCURjk551uG30sluIyGg/v6AfL3D58J4krfH
 cIOucEyflVVi57V1hUVco5+bIPmwFt38Ntq+8VfJdW53oGgi7gH9UZaDNocFc81mAZpQRybx1qd
 Q5YLYO61JsQmPJrDQwcjnlfLR72J7yX7W4LUgljWzB3ahkUw5zfpMhb4ozsuyGp3YgMqG9mdRT/
 gY/4glDShY/+vGnrlAedHZ6lUIKiFE9sgkshzMh7MwEeh8fIZgTUovVViQyx18Xk/znY1qhaEwf
 6OFt3WqH0VKkN+w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On this device, vbus was setup and switched off by the charger driver.
Enable proper driver.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
index 6989532584251..e868cf44956b5 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
@@ -548,16 +548,23 @@ led@4 {
 
 		led@5 {
 			reg = <5>;
 			color = <LED_COLOR_ID_RED>;
 		};
 	};
 };
 
+&pmi8998_vbus {
+	regulator-min-microamp = <500000>;
+	regulator-max-microamp = <1500000>;
+
+	status = "okay";
+};
+
 &pmi8998_wled {
 	qcom,current-limit-microamp = <20000>;
 	qcom,ovp-millivolt = <29600>;
 	qcom,switching-freq = <800>;
 	qcom,cabc;
 	status = "okay";
 };
 

-- 
2.55.0

