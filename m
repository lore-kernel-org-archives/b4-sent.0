From: David Heidelberg <david@ixit.cz>
Date: Wed, 18 Nov 2026 18:25:40 +0100
Subject: [PATCH v2 07/12] arm64: dts: qcom: sdm845-google: Enable vbus
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-pmi8998-vbus-v2-7-3c77a72b280a@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=892; i=david@ixit.cz;
 h=from:subject:message-id; bh=VkOTwwbUirh5SMOgzMhWbBAJrp1wguqG0ymDT4qYW/I=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/d+XZSFQwxLzTmFjB1NHz/hEX3XHI77Ygrdl2
 Prlq7NZiyqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCav3flwAKCRBgAj/E00kg
 cjGmD/sEaSEdMyQLmSgXhBuZ12FqpHWGOIFl8ctW1iDbvRKqVBAU7LZfvq9YvbYd5+THnoXnb3s
 JMMUUJEAOSWgjrMR4zz6FAird4bh2JY/h6gqof/G/1eteZcL5cUAcBS4NUHy9hzTocW7n45QrBZ
 nlb95iDdPyqD9NxU2H9fAAdM53V4SsLqxWS4MtnBZCaAutEpo6hOMbBZ6p/DmUq3nufRKnWxspi
 aVX3JmlJ3F8sl59L9CUp0M3ce8fCuP/BExdpEv9xSfcCUSW1uPy6C3AXBFeO4rbF9YmhSiOMz19
 QBYEx/RJ8O4CY3JUeHmVSQTii2Zw0Bz7FdYVBD4ebqfz6TICGevxcDLSowbPsjGg31FX3VgQad6
 NuuTceMoqtQBlmgFB8p9x6/L/1YmBxcwSAzYbn9KgaudEaHLe/WTKYTGRgJ2apy/5lRt0vz8FL3
 JpPwfmBBWMEWfLbII1QemNAPSHAILj0sIQrVaFOD2UhkeHbo7GKZqnk9AbKt2N+o3wfjUAzBgNJ
 yVNQceX5iY936IVsm38JZ4/AT4Ot14Qk29BtFNjo2DmDe3JcNSdWJ87LD6Se1Sydkp7BwypKxj4
 NGF+VIoh1ZMOppI06UguG5Zz94SMWMZ4qm1Z1Lk9IPKjgCxiNgTdNMBv5f6wTz0mOS31TDxwvhK
 Y8vQXaXp6GAVKYg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On this device, vbus was setup and switched off by the charger driver.
Enable proper driver.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 3c9656b88b696..417c767a1821d 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -451,16 +451,23 @@ &pm8998_resin {
 };
 
 &pmi8998_charger {
 	monitored-battery = <&battery>;
 
 	status = "okay";
 };
 
+&pmi8998_vbus {
+	regulator-min-microamp = <500000>;
+	regulator-max-microamp = <1500000>;
+
+	status = "okay";
+};
+
 &qupv3_id_0 {
 	status = "okay";
 };
 
 &qupv3_id_1 {
 	status = "okay";
 };
 

-- 
2.55.0

