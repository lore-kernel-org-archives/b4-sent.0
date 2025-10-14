From: David Heidelberg <david@ixit.cz>
Date: Tue, 14 Oct 2025 11:20:34 +0200
Subject: [PATCH v7 2/3] arm64: dts: qcom: sdm845-oneplus: Correct gpio used
 for slider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251014-op6-tri-state-v7-2-938a6367197b@ixit.cz>
References: <20251014-op6-tri-state-v7-0-938a6367197b@ixit.cz>
In-Reply-To: <20251014-op6-tri-state-v7-0-938a6367197b@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Jonathan Corbet <corbet@lwn.net>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>
Cc: linux-input@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 Gergo Koteles <soyer@irl.hu>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1029; i=david@ixit.cz;
 h=from:subject:message-id; bh=Fy4PwTgZvRdYveoZogmk4XGDDnQX034Xshv7R9LeAto=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo7hXnVtZyU+BU1XwQlxjwwEQzHM0S6LKsSP5a3
 YnGpj7V9GuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaO4V5wAKCRBgAj/E00kg
 ckxUEACCEpaS2GuZHqdFoMiC8g4Wech97ZeEBvgAU13nEdycgo0tiDkM1mU1ecdZRZ7NhoctCup
 mHJlKQuJOqhZeeEwBBmUzh8NAzBCxLh2Kv03UXQ2KU/x6EW7f/Spc0WXYDZvVhNiUODHNaRtXg5
 xXolPRiELMRDB1UDa2oTE9tEgxk7mKQytwQGnAPnLvj/Xa9sF/3E00dlKe+Q9tmbVgnhaoaUd0W
 D8DpofNZ1qxTNDhg8hEN+b+6QYSCVhccZlZ0KVAJgSiMWlc/tGdhNi0kTbD3eILhPhYU8YcQxec
 aW8gX7H+nTlEXvveqEqvu6sql6PGNA+2TkzlZMyfdszymryTBK/drXGvA7uX6CYfZc2BOj3pOEP
 ayhlvbirSkcZILGidCc8Iqqv0kQcqUE1sKaXNHmxFy3ADP0a19SbmebJZA7cF5PdkT3BhnVFrui
 mV4eOuf/7opACpJXkI1If0V7VXtoqsDSCA+KTYpaPASZVh+Hv2ppnGJUY6FTBkyzUUgePmNP7ca
 c6AESRDT8nFSQRlXkEXxYodWLLSjl/Q3A1Ucukgek5RAPNa0C/RCqHpPuJ1zWmIzFcTDGXNs9Ec
 PMASXC0eZNMSluaoLnb/7B4VVClF8bTlV6UZBcCuqM0Ol4XsVHd/56lVm3BUfMl3Bs3D52+gDpj
 gyeQgw5V8U6+4CA==
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
index dcfffb271fcf3..51a9a276399ac 100644
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

-- 
2.51.0

