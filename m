From: David Heidelberg <david@ixit.cz>
Date: Sun, 30 Nov 2025 00:22:39 +0100
Subject: [PATCH] arm64: dts: qcom: oneplus-enchilada: Specify i2c4 clock
 frequency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251130-enchilada-i2c-freq-v1-1-2932480a0261@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAD6AK2kC/x3MQQqAIBBA0avErBtQI4SuEi2GccyBsFKIILp70
 vIt/n+gSlGpMHUPFLm06p4bbN8BJ8qroIZmcMaN1g4GJXPSjQKhOsZY5ERi8pHEsjcRWngUiXr
 /03l53w+3sAF1ZAAAAA==
X-Change-ID: 20251130-enchilada-i2c-freq-aca7fae1c70f
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1148; i=david@ixit.cz;
 h=from:subject:message-id; bh=ReqOoZR6+itmM36ehLoW61mYST+VhDMpNFMsVslQ+Q8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpK4BDigd2kU+6OyzeCvnrAaf/24n9+rMDNj4yM
 EIfKKjAipuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaSuAQwAKCRBgAj/E00kg
 chrKEACQtzXZBAt0JWqvwythGdzHmGcWesX03W8+6/rbLK0qc9qrDoKF6YKVQDXGC6yCrH6TCzM
 9qcxM78oEc0x0uC5ek6JgiPzNy7qJM31jtNXCu5nGuddY4wSRADDYdcTnI29jMAu0Rl2Tn3725b
 VFoPCq6bp5azKKDkzZxo+/TH6SJNTdUDbAFCjLg3yYlb1G1AMPgbUOevnIXLoCiJkj0SF3g4A9N
 1OLnLa1TKzq7Kpt2tA96wsROR2PeRUBHgGP1YmgjC2Jmvu1eO/7Bx0hu9lPT24HAZwZSKjQtcmw
 G5ps5lIdFBofr90xPTVPCbGB9755Iag/VzPb2ZlPfw1Tcfenbvq8NWrqKKqNO/6xXYB8L/16mR+
 HDrJksP3AfNPri6Kj6i8JzfvEdquknF9tmNYTTeR5ny85D04iRiYOpHhvym8BLFlZ7OLedPTO6j
 lb43z/VGmZCsyOlO2bXez0GQ0NhQBeVo2I+8oQ4seQrZu3qU7cZijoEDaYP03p4D3zh9deWyeua
 /TL7KfpsRnkoTBF+8rCyNi2NXs66CYLrg+HgheYQfXv5qskKa+ZpROjzqqtCtk64qD7UdZSWEAE
 VvVrZTTWWzC52KLY3Bgfl+lJ3M5X1klODvZEfjCBTOIZYIBSE4L4dDf3NeMxQQkMq8XxazX67Su
 cQ7P3FrnZmtgZEA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Per the binding, omitting the clock frequency from a Geni I2C controller
node defaults the bus to 100 kHz. But at least in Linux, a friendly info
print highlights the lack of explicitly defined frequency in the
DeviceTree.

Specify the frequency, to give it an explicit value, and to silence the
log print in Linux.

Downstream doesn't define any frequency, thus also using 100 kHz.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
index a259eb9d45ae0..881d0f3ebca31 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
@@ -41,6 +41,8 @@ &bq27441_fg {
 };
 
 &i2c4 {
+	clock-frequency = <100000>;
+
 	status = "okay";
 
 	max98927_codec: max98927@3a {

---
base-commit: 7d31f578f3230f3b7b33b0930b08f9afd8429817
change-id: 20251130-enchilada-i2c-freq-aca7fae1c70f

Best regards,
-- 
David Heidelberg <david@ixit.cz>

