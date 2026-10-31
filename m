From: David Heidelberg <david@ixit.cz>
Date: Sat, 31 Oct 2026 16:05:06 +0100
Subject: [PATCH 09/11] arm64: dts: qcom: sdm845-lg: Enable vbus support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-pmi8998-vbus-v1-9-4d805e5a0f27@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=957; i=david@ixit.cz;
 h=from:subject:message-id; bh=Rihonp/y8+HoX4rhsOxsAwY056X8OB2FPhm/6tjGeo8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq5gOwu6Es3lE0a5vv22oieDwXQsTItibWBcimX
 aV8eNKGZQKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCauYDsAAKCRBgAj/E00kg
 cvLOEADO8ds7RwJwPjQL7KH0HSxa4vjtSilyl4fuCEN7Wwisumhe/Nl146RpydO6rngFMkfxVA8
 w5YwVGKgR3mOsiZss3vL1K+YY1lKM3RJvxfMg68yIAAHLzsFCIzHP5OvR4RdoiWN4CHbLu/W7B/
 VfUtT7Kf8/qBBHSmKj3VgnFuLbt8W5381TSp3nKv8LNVHxLu+o04JsEEktGzNx4ObVvWrkjccg7
 CLHLjmRV70hGx4mxwG1XPtQfIi8FQiCSKGh/3hfe5QIvl0kwu0FY7FuonlQ6T/cW+dJDppbz6T+
 o2ksaePVYa56WRJa45luonj20NhGOl45aIjPvd5x62hNGmVHten7uXZfMrtGBwSaXGxiITDDpks
 RmGNkObqUYSvw8GxoCfrHkdOJKfHJdC8DCyPAv0iA2PXh2HGPnU8SAMK3tsirLamVh3vjUdar2d
 voaSCSGahx7ppMENu7muwJKy0Z8a+na1iCPJoMLL+hgVMBdUEoN0KQiY8Gk2MRv15gnoEM0Jl/2
 SRf/v80St3Cp7T3UJz/NKw4fvg5sD3D8vNx93E3NiAsodZVVok9AnI7tq84ykpvhQkUre+nt/Yt
 MxLTTAN5/qWMji6xeELP/JYe1YTxmeDQZzTlybZHDn6+rQIV0bZhDcSdybkTAErHJ5kSfVI4RIK
 kMvLjRzNWS9zNIA==
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
index 84f0e1f0bcd32..d88bad1d07959 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
@@ -529,16 +529,23 @@ led@4 {
 
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
 	qcom,num-strings = <3>;
 	qcom,cabc;
 	status = "okay";
 };

-- 
2.55.0

