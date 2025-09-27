From: David Heidelberg <david@ixit.cz>
Date: Sat, 27 Sep 2025 13:20:28 +0200
Subject: [PATCH] arm64: dts: qcom: sdm845-oneplus: Correct gpio used for
 slider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250927-slider-correct-v1-1-fb8cc7fdcedf@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAHvI12gC/x3MQQqAIBBA0avIrBPMFLOrRIvQqQaiYowIxLsnL
 d/i/wwJmTDBIDIwPpToPCraRkDY5mNFSbEatNJWee1k2ikiy3AyY7hl7Izxqjcuegs1uhgXev/
 hOJXyAXsVlF5gAAAA
X-Change-ID: 20250927-slider-correct-d34490847d95
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Gergo Koteles <soyer@irl.hu>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1235; i=david@ixit.cz;
 h=from:subject:message-id; bh=khpBYuHNK3gqhl7+t9U8Ea2FmJkEV2t39lvpmJj2DM0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo18h+p2HI2zxKPnvC/Vj6ayFsg9PhzbcgnfCyI
 TFmmuL+5veJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaNfIfgAKCRBgAj/E00kg
 cleBD/4t8nv6PNKKJ1R1a3L3W7GPVE7NqprA07qLI982TV1KecZ5oxkT+HXQm+Z9EJrqipWeoPZ
 3SFjlZdclKIN+R3PQSu24LQ7+KLy+MfC6CZ1bvECPod50WGMqprigBp9j0YnUv3dwZdEUUI+5JR
 5KwaDwJ/nZCqMKYP2HekCaJpRbLc4KrH97O12BR8Ggkuhochlfv4ONxNtlGIV8sd5u55NZCbo6a
 R3CyacztpUNWS6ySoz31a7jrqSjv37kXespgkYTEuwqKXQIKHFf72crp62dTnKLlt9qZsYIdEFT
 Sk5pl6Hp78BpbkOimGE8KBDRjEBuvgzg1rV19Rmno1Jl+peO0st59ApSHnV2xlgbU1w7Qqpxoqz
 /6czPfGmSi9Fy3BrknzPbBpPsIWTdQNZ2aDLWx1DZJqDCfprgK07TY+H3UCGykdF+CxZzi895jG
 eBVbw3j8UiE2vgXflxsjvsnhLcatsh/y8weh5V7f0xHBJ6s/G7JCkLvKMEvL9e08WHCC5jmJ8cO
 JC5BazebyAhfbmkg6veg0Buwtie1o43m28TOlNIK4XUwTK5mJGbP8/tvJ7Ac6lC5717WORe37mZ
 W72KrWl4q8LCCYrROE/kRgrU4aQgdzAKydNP+GmZGmnKLDVsITP8nKhAZTNmgN5opyEVgkWY4rk
 L3+2ys3vbS2rQbg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Gergo Koteles <soyer@irl.hu>

The previous GPIO numbers were wrong. Update them to the correct
ones and fix the label.

Fixes: 288ef8a42612 ("arm64: dts: sdm845: add oneplus6/6t devices")
Signed-off-by: Gergo Koteles <soyer@irl.hu>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index dcfffb271fcf3146aeabda8fc19e61b456b76887..51a9a276399ac7de42f4269ace257120236fa81a 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -803,8 +803,8 @@ hall_sensor_default: hall-sensor-default-state {
 		bias-disable;
 	};
 
-	tri_state_key_default: tri-state-key-default-state {
-		pins = "gpio40", "gpio42", "gpio26";
+	alert_slider_default: alert-slider-default-state {
+		pins = "gpio126", "gpio52", "gpio24";
 		function = "gpio";
 		drive-strength = <2>;
 		bias-disable;

---
base-commit: 262858079afde6d367ce3db183c74d8a43a0e83f
change-id: 20250927-slider-correct-d34490847d95

Best regards,
-- 
David Heidelberg <david@ixit.cz>

