From: David Heidelberg <david@ixit.cz>
Date: Sat, 21 Nov 2026 23:38:06 +0100
Subject: [PATCH v3 12/12] arm64: dts: qcom: sdm670-google: Enable vbus
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pmi8998-vbus-v3-12-91ba2e61a877@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=946; i=david@ixit.cz;
 h=from:subject:message-id; bh=0IbEStSfLNSM1QUREHqUTMJimPJpvyfXyF3g24sL/vk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAh1bwPzO73tYJW9ij8DdCUY7TsPYtcbxhIJ/S
 urrl9Jcit2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIdWwAKCRBgAj/E00kg
 chO9D/95HNsmg7vFye2zP53Jaq+wUUNLeTZQV6SxXZNuNWTJS+f4ztho4b46eDk0EUxVdppNjQt
 8OQcpFIdo6eu9K2htn1LeQYKZVGnIEcuXPYxkQo1EB1W1a0c+TcEcgEilBjbGj+rk6JneyXxdE9
 JGmQJHUVQG/KQPEeMp0QoITvRkLoUtunmO1Kr8nE3atAvrmYajCbx1WSQK0OIj2RaNZe/DMdl+1
 qBznvzWl1SHySvfbxCDM6Jv94r5fCEL/E4OBttX4Cv/H7hknrAisdx6KZMPn1fpgjwrCbHhsrns
 iGGwAF84ASiVKN7Y0jWe7xZGjtOVisgl8NlsqlBRkmcsA3oKVIlHeAHWvQ9px76u9I9ymV70Xw2
 aT0z7HssjONp/uEcmAe8TFZo8W2/RFqkpQTUnLIZyE4fLdWeiVL7vt6x9cTkzuKhKuqu3xVYLMr
 Y+hP+UWH4Ij1gwv52dyzuR95kX43HVk91k38sMMWXq+0Kn5k+TCNJlIBRRWjW9VOJGpvbUjeLPs
 RwPOwme0n5fTfq8vIjF3N0gPy+SpycDkf8Bj4kvFprYbU753fJ8wpvhk0JfH1FNHpLfoIe3W6jt
 Vqx9jEtJAZ/qQwnFyZ4EFQVV+XiYRkV+69OxtkVLrl8NW5K0qBkZidPtIls/VtUmrXu1NtO8kgl
 8Fra5C6wkjF0qqA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PM660 VBUS regulator on Pixel 3a and 3a XL.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
index 8f91faf8a9cc5..9c95855b56e7b 100644
--- a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
@@ -604,16 +604,23 @@ cam_vio_pin: cam-vio-state {
 		power-source = <0>;
 	};
 };
 
 &pm660_rradc {
 	status = "okay";
 };
 
+&pm660_vbus {
+	regulator-min-microamp = <500000>;
+	regulator-max-microamp = <1500000>;
+
+	status = "okay";
+};
+
 &pm660l_flash {
 	status = "okay";
 
 	led-0 {
 		function = LED_FUNCTION_FLASH;
 		color = <LED_COLOR_ID_WHITE>;
 		led-sources = <1>, <2>;
 		led-max-microamp = <500000>;

-- 
2.55.0

