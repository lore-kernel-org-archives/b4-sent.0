From: David Heidelberg <david@ixit.cz>
Date: Sat, 21 Nov 2026 23:37:59 +0100
Subject: [PATCH v3 05/12] arm64: dts: qcom: pmi8998: Add node for PMIC VBUS
 booster
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pmi8998-vbus-v3-5-91ba2e61a877@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1153; i=david@ixit.cz;
 h=from:subject:message-id; bh=Vml5iGmLl1DRnRJN3EG4LOdQ6VYHu9Isno8WfrbJtu0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAh1aKQWMjhZcoN9y6hROnpzIFiqFXlRsbz9e2
 1MpJAixkXyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIdWgAKCRBgAj/E00kg
 chskD/94I/rdP84yvgfbaab9bWAmakCcY8OYFSbMDRGom0caO91AVEAs3JSNQ1+PTfcDbFbIi9K
 /ACpKXVq7zSIbRE4Ybr+4NkrMShnKgt2KrbGN0m4xsz9fo1OdDEzDmEBXJH1LzG6dySkD4wS6oF
 DFVhjNsF3qcPiSUKRSeejICpsIiRLLpK+Uyu2LYY8f459PWaQklilhfvGUuNcw/nyE7Z0ldXGpJ
 mgTpFgJ/Y3SHb67B3lH3tMvOxFsiKCPdEdw0Vygra40qUULPSoP/wR5em+jkAsKj35DGcdj5n31
 ya/+7rzuFqdt8eOir5fw9Y4ow7Z4GGwVNERPxs21Ra+JvblYzp3bFOT4PUPE81ZFXXZfRdAkBw2
 QpqPjAN/SpeVLW38qPmddUJe6d2MeQoz+czQ5nXWpmwbP7VUlL/1at0UAkq4/Bwyf04tZGvzIW3
 /g1vSeQwdvo/JdkJmEbSeqaxrP0kikKWQTocxDQ9lMWPzM9EBFf3t1xGttBXpLRXr5E7Hf10GQ1
 TaWipOdoO11wbMBkFvn3JS4QB6I9MX0tnLEjWvOGVzzpbLMBXTxV6jWJHMIN2bD5teQLVaR0U8Q
 saRmOR4LalqH0Ux67UgzPMVmQBFQmExfU7mpvdWwdX58Qa11NvuPc8ENzbdfDdBTGWPYcAQn6VX
 szNOXLmmN4orZ9A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the required DTS node for the USB VBUS output regulator, which is
available on PMI8998. This will provide the VBUS source to connected
peripherals.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/pmi8998.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/pmi8998.dtsi b/arch/arm64/boot/dts/qcom/pmi8998.dtsi
index cd3f0790fd420..9d65dd4abcdbb 100644
--- a/arch/arm64/boot/dts/qcom/pmi8998.dtsi
+++ b/arch/arm64/boot/dts/qcom/pmi8998.dtsi
@@ -24,16 +24,23 @@ pmi8998_charger: charger@1000 {
 
 			io-channels = <&pmi8998_rradc 3>,
 				      <&pmi8998_rradc 4>;
 			io-channel-names = "usbin_i", "usbin_v";
 
 			status = "disabled";
 		};
 
+		pmi8998_vbus: usb-vbus-regulator@1100 {
+			compatible = "qcom,pmi8998-vbus-reg";
+			reg = <0x1100>;
+
+			status = "disabled";
+		};
+
 		pmi8998_gpios: gpio@c000 {
 			compatible = "qcom,pmi8998-gpio", "qcom,spmi-gpio";
 			reg = <0xc000>;
 			gpio-controller;
 			gpio-ranges = <&pmi8998_gpios 0 0 14>;
 			#gpio-cells = <2>;
 			interrupt-controller;
 			#interrupt-cells = <2>;

-- 
2.55.0

