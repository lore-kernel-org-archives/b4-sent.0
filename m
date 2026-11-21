From: David Heidelberg <david@ixit.cz>
Date: Sat, 21 Nov 2026 23:38:00 +0100
Subject: [PATCH v3 06/12] arm64: dts: qcom: pm660: Add node for PMIC VBUS
 booster
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pmi8998-vbus-v3-6-91ba2e61a877@ixit.cz>
References: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
In-Reply-To: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
To: Abel Vesa <abelvesa@kernel.org>, 
 Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Markus Rathgeb <maggu2810@mailbox.org>, Rob Herring <robh@kernel.org>, 
 Robin Snyders <robin@snyders.xyz>, Sebastian Reichel <sre@kernel.org>, 
 Wesley Cheng <quic_wcheng@quicinc.com>
Cc: Richard Acayan <mailingradian@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1176; i=david@ixit.cz;
 h=from:subject:message-id; bh=YJAh5JKxsMmwh1tjGfME9pip1rZ2KokfphW0+tMoGZ0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAh1buHGuUxmoIIzuGDVDXYwd52yGDl0BlJRVk
 yNslinULPKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIdWwAKCRBgAj/E00kg
 cjxaD/950tAIkyPW4qo258AxR9vp7/L7FkyGsj5RyVfHV7xc0yCzkZq3FrR8RoTCTi/xP+S+d84
 Ey4aEJw40nPGL2/1O9AveqW4IftRIq10ppkmziT/UkGtXyyomlrg3kHfdeeCih2SnU977PLvcmc
 SafSfAZkiK4LQrvSnrL435MMHMHd3Ke6j6A3pq+eQciybEjxxg4uVWL1wfWQPzPRGmjEkoWOZCt
 6QjNkYvK+KUMs3M8chU1BkfQRSb5OLfhvq38f5802E4dwnSOMKf004uzsTc/dqwgIPj283LPe2w
 CO98DtuVPxDsV7RBoda6XVqPxhOpxo/lULboNpYcpHusmp80yjaSDSAAXXHVjNASvUX4etDkxXV
 I0wSPgN8vsSd5nQ0V4+aIFMSb7r6JxAVSq7T5j/xTP3lgGawEGWeISs0Ro+xI1jDs6ijkU21sDl
 CVG0cdLITKmOC3EWXxRbuX5DEQlQb/bTTlW61NtXigJ9dEZI+1OHWrzshR45R24lm+gRgaiF+Dk
 jEVD+OMgi5S8bjCbkSLfYqMKBjMJ14SLpAYQT7y74iqj9d9u59c3d/NFo/oodOhYpNdvaVBvxM2
 oDUBInG5bFVoO/NBi+trlA8GgS4+/NUidcGZhOmhmnqfLtecYcfmTL3YpeeC9jUHOppaKxo7WW/
 wtP53V1kEpTZTOw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the required DTS node for the USB VBUS output regulator, which is
available on PM660. This will provide the VBUS source to connected
peripherals.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/pm660.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/pm660.dtsi b/arch/arm64/boot/dts/qcom/pm660.dtsi
index 156b2ddff0dcb..fe9ef304d64e7 100644
--- a/arch/arm64/boot/dts/qcom/pm660.dtsi
+++ b/arch/arm64/boot/dts/qcom/pm660.dtsi
@@ -85,16 +85,23 @@ pm660_charger: charger@1000 {
 
 			io-channels = <&pm660_rradc 3>,
 				      <&pm660_rradc 4>;
 			io-channel-names = "usbin_i", "usbin_v";
 
 			status = "disabled";
 		};
 
+		pm660_vbus: usb-vbus-regulator@1100 {
+			compatible = "qcom,pm660-vbus-reg", "qcom,pmi8998-vbus-reg";
+			reg = <0x1100>;
+
+			status = "disabled";
+		};
+
 		pm660_temp: temp-alarm@2400 {
 			compatible = "qcom,spmi-temp-alarm";
 			reg = <0x2400>;
 			interrupts = <0x0 0x24 0x0 IRQ_TYPE_EDGE_RISING>;
 			io-channels = <&pm660_adc ADC5_DIE_TEMP>;
 			io-channel-names = "thermal";
 			#thermal-sensor-cells = <0>;
 		};

-- 
2.55.0

