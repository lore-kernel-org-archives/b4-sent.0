From: David Heidelberg <david@ixit.cz>
Date: Mon, 10 Nov 2025 16:37:47 +0100
Subject: [PATCH 2/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Add ath10k
 calibration variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251110-sdm845-calibration-variants-v1-2-2c536ada77c2@ixit.cz>
References: <20251110-sdm845-calibration-variants-v1-0-2c536ada77c2@ixit.cz>
In-Reply-To: <20251110-sdm845-calibration-variants-v1-0-2c536ada77c2@ixit.cz>
To: Dylan Van Assche <me@dylanvanassche.be>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1088; i=david@ixit.cz;
 h=from:subject:message-id; bh=rYwdSJ6cHAzDm8PURpNylwInOTgz1iatN8QT60N4njI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpEgbKldre6WlnIZ9OS9ViAetuS84ikzOLErwqT
 9IL8w1HG7mJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRIGygAKCRBgAj/E00kg
 crK8D/4q+w5OLGCyysdHrA4Fbt8lO+rpBPT8trhCJgguL9VilUs6elkdCKwlEAZPPfqh3kRypPr
 pUTb1ObhFWBjC3Daq8/WjrTDFWYpUa4TY25VECpxwZfLqYyIKtEbgjW+2jxhFp36aV0upzedB9s
 iNVETBgWhScnPuUhL50M3xWW4cikiKrPxSspGajAg8yIlON7kx0+GS3RIjIl7wYN7HNcad8aWAH
 +OWhykHalU6gWky8J/iJjawDqbB2RvulYw/PBVIPB84tR8hZQkjwYDB2e+P7C3E+yGxd0DU3Iw7
 jmb9pyIxUI6O9t6MyX5N/BZWBnMVAf3D9CCBe8mfo2Kgod4ESYnZzcMtJoijGx6+Es4SADSmPt0
 i++s6aoEvWyJNRh9gZi+hSlw5C7trFHy41Bh5e3k+03XqIQCjwMZKsuVrjo2u8d8eWqbdN7KSt0
 H5hlaTMpNgfpjDbuFR+y6I39Fncr4v38B8BEhYpKdyQHL9g5MdGpvRneXdiogrmpAcOgckJtQFE
 5W6gfvm+rK6QBxgxKmIMnp2o+CywQvCMpl1DqG4IQ8bBS0QTmXTfwbDmBJyclMN4iPbdDjmZTwv
 sVxJTUlSNw8hzsPN/NyiX3PnnJ9F4BUUqICOQxdQBM3wjtJQ7s9dOSq3lVvQ2i613sfI/nGzRaP
 6wh8WUJFptqDNbg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Dylan Van Assche <me@dylanvanassche.be>

SDM845-based Xiaomi POCOPHONE F1 has its own calibration files
for the WCN3990 WiFi/Bluetooth radio with the ath10k driver.
Add the calibration variant name to the DTS to reflect this to
allow using the calibration files from linux-firmware.

[David] Adjust the compatible as ath10k-calibration-variant is deprecated
Signed-off-by: Dylan Van Assche <me@dylanvanassche.be>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 785006a15e979..ebcd01477f05d 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -636,4 +636,7 @@ &wifi {
 	vdd-1.3-rfa-supply = <&vreg_l17a_1p3>;
 	vdd-3.3-ch0-supply = <&vreg_l25a_3p3>;
 	vdd-3.3-ch1-supply = <&vreg_l23a_3p3>;
+
+	qcom,calibration-variant = "xiaomi_beryllium";
 };
+

-- 
2.51.0

