From: David Heidelberg <david@ixit.cz>
Date: Sat, 13 Dec 2025 13:00:20 +0100
Subject: [PATCH 1/2] arm64: qcom: sdm845: Introduce camera master clock
 pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251213-sdm845-mclk-v1-1-197bc947d4c6@ixit.cz>
References: <20251213-sdm845-mclk-v1-0-197bc947d4c6@ixit.cz>
In-Reply-To: <20251213-sdm845-mclk-v1-0-197bc947d4c6@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1674; i=david@ixit.cz;
 h=from:subject:message-id; bh=uiiq2Mic+x+DbSSB9OvLTBg10YTIOXvynitnln45aLk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpPVVVWKfTbtgcJIewa2IfTh2XKygUwnuNJGKA5
 5eYfz/GN9eJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaT1VVQAKCRBgAj/E00kg
 cj2TD/91EXzwitxuPe/Jh13JyhhwBF9x1xsAxlMrHt3uT9UXfKJP5zinawtJH4/xSyRl9DtnERm
 i7v0CxGvmiqwC2n9Fx7RUaaXrwMaVAhO/IbM1M1PL6GX/kQUcuxW3/YfMRH5YTnr64itPQza0g5
 mJ6k4LiIIzjxw5SM6hjqGhF4/UQMlfbYFnoFwqDFsEESevZTimMFftKdipQIT3/mQs0PcC+AXZx
 aQAt0c4uRzef4Im+Dl3YNMjFarLJf6vMbbraD2ijFrUSu2RGNouT4HU6AJkGKF9kYo2eKrmvmhh
 gwDJDOp8OQ4eyKLv2yzWdzL2BU/Izku7mgkouqG9JDyUqmwgTwXcBl2Fn/R8zNiVFIxmuKjGKRy
 gP8+hfCrSsZTeWWwp4gcLLzy0TzzgZsY4WxMoBkKmjD0Gv5//XkIfyPWbYvSV4ZZKgdl1VGlBIQ
 gveI6a0jnRS2WsXqushNLApaj5ZtZltvL8Vbd7HdqLQKNxQGnNFi3TAJfV5pBvWEYUHpQCWkRTd
 S4IWP9xPxAmEv8UKUh0mNgN1uPkG9b2mYayyYJqEB2YrltU/XlSW4JENvutsFLle1DT0UUgBTky
 CeJX1/FXVMzU18t+uzpIKcqcgRtyJszm5tD8BitR7l+QJFTYwtcIS8mi1vRjzYIunZOl2BG4NGH
 TW9nAk0gjsw4jlA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are shared for the whole architecture, so let's define these in
proper place.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845.dtsi | 43 ++++++++++++++++++++++++++++++++++++
 1 file changed, 43 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845.dtsi b/arch/arm64/boot/dts/qcom/sdm845.dtsi
index bf2f9c04adba7..97bd9513b011b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845.dtsi
@@ -2805,6 +2805,49 @@ tlmm: pinctrl@3400000 {
 			gpio-ranges = <&tlmm 0 0 151>;
 			wakeup-parent = <&pdc_intc>;
 
+			cam_mclk0_default: cam-mclk0-default-state {
+				pins = "gpio13";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-disable;
+			};
+
+			cam_mclk0_sleep: cam-mclk0-sleep-state {
+				pins = "gpio13";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+
+			cam_mclk1_default: cam-mclk1-default-state {
+				pins = "gpio14";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-disable;
+			};
+
+			cam_mclk1_sleep: cam-mclk1-sleep-state {
+				pins = "gpio14";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+
+			cam_mclk2_default: cam-mclk2-default-state {
+				pins = "gpio15";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-disable;
+			};
+
+			cam_mclk2_sleep: cam-mclk2-sleep-state {
+				pins = "gpio15";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+
+
 			cci0_default: cci0-default-state {
 				/* SDA, SCL */
 				pins = "gpio17", "gpio18";

-- 
2.51.0

