From: David Heidelberg <david@ixit.cz>
Date: Sat, 31 Oct 2026 16:05:07 +0100
Subject: [PATCH 10/11] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 vbus support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-pmi8998-vbus-v1-10-4d805e5a0f27@ixit.cz>
References: <20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz>
In-Reply-To: <20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1319; i=david@ixit.cz;
 h=from:subject:message-id; bh=pWeViIMDuSNHB82CtRWxu+MFw3oz1VMoW84oZxyP/2s=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq5gOwDXKqQ8GqeE33K9jzyYozL4KpVaQSmgjMC
 SlPBy2X4XCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCauYDsAAKCRBgAj/E00kg
 cnIoEADOXThUpx81FmPowhpVnT4AmAQV5ohbU/UVRbX8F7H5x3qDJ6YMCR63duwlG4I/k7NT+ry
 pfkUruPpDT4LNFSRr8Wnft3cV6PoVFyBTssAXZGlCU3UtCgCRCN0KMh2GeX3hkKHTcDfDDi+a/Y
 H2Xta4xlfbvBbZGx1C0GKrhw99Zq4jFft1xwZxxn1KB/IE+QRA8Bd6ab1ALJcOMfWoRAQ54Gxwh
 U3ic8rqPYj0lngXuDQYNq7QAlJ3YamomPZAR0aDwAjqSNEkxOdDFjtJ76QZHqiHBhnWbl8a6Ej6
 kTGJJ1vP3eZsabwmRur07ASeAcZObvZLjZuw+tR3zEjAILz4Muu3aPB0a5DFTsP1C616XbHYNkv
 YAAbvso/vLyFh5Y1VcAc5kPNnEeFW/LptOoXnHK4EJ4ZMZlmnv1v3TWHkyEcBq5FGUGajEWRL0l
 KAEqiA5qZpIRMdFKHSJ6a9k8DgDyZ9K/BybROw5hiPEW/Wdml7yvKbq1KJZOC6UBOwkOEVfzrCG
 kUhtillWgy2uHIF3VStA3+daTD5ebNWwAHFHS9rz9Zp8P9TyOWuGjDzALCj4SF0CpKbmwUIkdpG
 52ucWu0qWw7b4GdM9P+sD1AXqXnCHW77CqhwncwPnNjNGlDuLKtrs2hPiTO7W8VKT//uSYnHcYB
 TzBBENIy+iGKCoA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On this device, vbus was setup and switched off by the charger driver.
Enable proper driver.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 35babe8c5f757..2986693b3ed71 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -414,16 +414,23 @@ led-1 {
 	};
 };
 
 &pm8998_resin {
 	linux,code = <KEY_VOLUMEDOWN>;
 	status = "okay";
 };
 
+&pmi8998_vbus {
+	regulator-min-microamp = <500000>;
+	regulator-max-microamp = <1500000>;
+
+	status = "okay";
+};
+
 /* QUAT I2S Uses 1 I2S SD Line for audio on TAS2559/60 amplifiers */
 &q6afedai {
 	dai@22 {
 		reg = <QUATERNARY_MI2S_RX>;
 		qcom,sd-lines = <0>;
 	};
 };
 
@@ -678,9 +685,8 @@ &wifi {
 	vdd-1.8-xo-supply = <&vreg_l7a_1p8>;
 	vdd-1.3-rfa-supply = <&vreg_l17a_1p3>;
 	vdd-3.3-ch0-supply = <&vreg_l25a_3p3>;
 	vdd-3.3-ch1-supply = <&vreg_l23a_3p3>;
 
 	qcom,calibration-variant = "xiaomi_beryllium";
 	qcom,snoc-host-cap-skip-quirk;
 };
-

-- 
2.55.0

