From: David Heidelberg <david@ixit.cz>
Date: Mon, 24 Nov 2025 22:53:38 +0100
Subject: [PATCH RFC 5/8] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251124-pmi8998_fuel_gauge-v1-5-dd3791f61478@ixit.cz>
References: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
In-Reply-To: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Casey Connolly <casey@connolly.tech>, Joel Selvaraj <foss@joelselvaraj.com>, 
 Yassine Oudjana <y.oudjana@protonmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 =?utf-8?q?Barnab=C3=A1s_Cz=C3=A9m=C3=A1n?= <barnabas.czeman@mainlining.org>, 
 Richard Acayan <mailingradian@gmail.com>, 
 Alexey Minnekhanov <alexeymin@postmarketos.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=864; i=david@ixit.cz;
 h=from:subject:message-id; bh=Re+K+Vl4ZWKmEaGB1PbuYTeVVGS0LWdIYqQ7l+1dIAI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpJNPgfC0P7L5HwD7n3cXr0nX8wAQIe/gu8Sdt7
 OSfwTLO7yaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaSTT4AAKCRBgAj/E00kg
 cqOVEACA6gKbkiaPb7CMA/iUgj6STdqPRAi/V9BHUqxSlKcWhjlcnzSqhhNWe0SzqqFeSmi5Zoa
 yt17IyjfPUm+SLoWvtCklMerADVx7pIrEq8gVf1dWwVKNtAoz3IHr6v0Z2DHMNtYcSmrhWZaaB3
 DZ9/y3itT1ew+3eICVmS3+CtrELd7MeZ19dwFfmIXbpnpBtpWeeLo+sCREzlbWDNx8Jlq3Nk1qO
 BylNY1pwf/4v8R5NnMnHsHYMEQyzOwZKUv28e6afb37Bnmptng6+WcTUUSyyIE/08n3g+pkince
 yNtCJADoNXolSNGXHM6pF64BX9G5iQoC8yQdP9zoqck2PyvLhQnVzoIU+L5tfb4lofile53BpGS
 oIBj6Qzaz5zMNImMaIr28ykDwQ/0nThRDk0VhZkSY7BIIvFiES/sX3YE5daeCbJ3W/S8TySupKs
 GQeaKxjy51vSHu6dFauPL1vKMi/JeSacJGzKiPzqTitQK+QDWsJMiIJNUfy1q69TUP9ZdBPe6ea
 WplkSMec+9a5hb3zIxvFllZ2Ve8qhwDuRX1kaoqnx6PzutPbOctUMs2HUswVOrfVVn/PPH6qCbF
 hpeMUDWkFaD4c2APyPQ7asaf9T1K6XHbi+uBOfFKsts5kJOfXAie5IueYfI1f/3F23o3Q8VCiCb
 sPmizpjdlI0Wgcw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Joel Selvaraj <foss@joelselvaraj.com>

Enable the fuel gauge and configure the associated charger and battery.

Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 785006a15e979..bb6448f4e036b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -377,6 +377,13 @@ led-1 {
 	};
 };
 
+&pmi8998_fg {
+	power-supplies = <&pmi8998_charger>;
+	monitored-battery = <&battery>;
+
+	status = "okay";
+};
+
 &pm8998_resin {
 	linux,code = <KEY_VOLUMEDOWN>;
 	status = "okay";

-- 
2.51.0

