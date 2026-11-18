From: David Heidelberg <david@ixit.cz>
Date: Wed, 18 Nov 2026 18:25:41 +0100
Subject: [PATCH v2 08/12] arm64: dts: qcom: sdm845-oneplus: Enable vbus
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-pmi8998-vbus-v2-8-3c77a72b280a@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1021; i=david@ixit.cz;
 h=from:subject:message-id; bh=qtK8U0DG1cRkdsACHAr+c1jMalJb+5fDCyLN85kWDvA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/d+Xux/XV/RcXxApBTxcJ2ZIuM8XgqAeK/KNK
 oiW3dqxLhCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCav3flwAKCRBgAj/E00kg
 cpXqD/0cPSi/Spa6ztty2BllXCoc8Y4UUnWTZswjzAhVje+ckv0MNJKQB50DIqRZpPJ9aawHKbk
 N6E9/IapIM+brBH6XCLadnKgIZ5tayWX2BeOeEToCibAAMoNKA1mUXBCUz4yOyMx26pwb5ykTEj
 /6ltPIUNvlJYTBSY0Ag4TVOBxSDyVvfAuX1SeXzg0UIHFBTG1W81m+YOTVr6MhzEfnJv8pGGzsz
 aTQzhXh9KZse1YZGPXsRMYVi3Pk1sOIHdEg7DGvwNwcCvqYnyuWknh+KWy0/izApn8MI6fLjiPo
 WgBkQbmwzdU1uvyxc8kuNLo1DZmpuqckgOpEZZZjyg0ykcwxzv4K1piUpVaTyELUNE1V3aZDLUd
 VNam24iFesz58IY6sUhhOwSFtE5AwyzPHVJMi35vFa3GiqxFCl5kD01j2dl98Rk6xOfaacPUhX2
 tpDa5oTzEb4133IVX+0sQvRLQOyw/vtAKhAV8ATH/z3zttbk6BURLC3dKjwiJnFn1TkarlhrW7Q
 B/tAJNBAQVmKvm3bb6b6wRooFUj1lLeZfBPbpbyro2nsIL7ltEDdHOT6ODLJ8Us8Obk7pSPs3NQ
 WXMhi4likHlzUE1SmyNkIUNSGkw/GnoSNJ8JHiuF/fg+qAv/YWFYokgdrVLIOb5xPvKANWr3wob
 MG4Yrdla/Na43Cw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On this device, vbus was setup and switched off by the charger driver.
Enable proper driver.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 1df09da3c4d71..4996ce24fee36 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -660,16 +660,23 @@ led-1 {
 		color = <LED_COLOR_ID_YELLOW>;
 		led-sources = <2>;
 		led-max-microamp = <500000>;
 		flash-max-microamp = <1500000>;
 		flash-max-timeout-us = <1280000>;
 	};
 };
 
+&pmi8998_vbus {
+	regulator-min-microamp = <500000>;
+	regulator-max-microamp = <1500000>;
+
+	status = "okay";
+};
+
 &q6afedai {
 	dai@22 {
 		reg = <QUATERNARY_MI2S_RX>;
 		qcom,sd-lines = <1>;
 	};
 
 	dai@23 {
 		reg = <QUATERNARY_MI2S_TX>;

-- 
2.55.0

