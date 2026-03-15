From: David Heidelberg <david@ixit.cz>
Date: Sun, 15 Mar 2026 19:52:47 +0100
Subject: [PATCH WIP v2 11/11] arm64: dts: qcom: sdm845-google: Add STM FTS
 touchscreen support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260315-stmfts5-v2-11-70bc83ee9591@ixit.cz>
References: <20260315-stmfts5-v2-0-70bc83ee9591@ixit.cz>
In-Reply-To: <20260315-stmfts5-v2-0-70bc83ee9591@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-input@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1222; i=david@ixit.cz;
 h=from:subject:message-id; bh=GLiD2nULc18ENMziPB9JyYEPA1R8XKpCMXaNSc0DKdU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBptv/6OhC8SocPmih7wGnZLPlUoktbgC3LKcDkk
 rb7jDcfKtuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabb/+gAKCRBgAj/E00kg
 cjyAEACecNgd/QeeVImpnVd0/qO9+NmYGuaGVLUdkOlwiR1azyYsPURJ0BoyOPVPUtW2SARrkbp
 /8y+IyIkP6AfVP++jl5EJ6Yb7RANAZofa7WRVNE7EPvM+AinjYj7tk5DCxmS+XbjjG+2fsOZL4n
 Dl0gV1yktFmywT+QT8MjjBZDsgbfZpLBjqJxQmtL4QLcK4bgb78wF0XiWrL4LRdHzKAU6OlpJaI
 LLZhvv4S1aZDfByji/VpDBP7wd78ADZmLqgk1qJrkzJGUpvMdkBWuNNy0ShAPwPQ/6qBCLxBMfi
 KGv68gmommlUQfPd6LWmEX9MRo8aVQloJoeJsr59cRpxKhqYzVENlAF0F2K02rH+CYwz+L1mrER
 z0r96/B3M1MbE3+C2x0pQaXCgiROmD9uWKcQdaURbtuTU7ZPh8a2o/HyfGotrhpkp7dpHd+gaW6
 nWbiiAQACYEfnCaawvKmRL5nX4eUXAN95YFnE9twgQpyQDKJjRMmpAmPpjqF97P3p7LTMpuutth
 cGBOEnjMVoyfpjhAt1qL3bw8zlbnbds2TzfEgRV7jZTAC5o+q6oR4UwDc7HpU3jorAULWVBzD+h
 T88D7ApzdQs8qIaVXoxc9Tf55Dwv6W/74Eed+xnAqYOhVLlW1Knj7K8nSzP+kO6QAFxtb8DY0I4
 yXJg9gbgW+l2ccw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

Basic touchscreen connected to second i2c bus.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts | 20 +++++++++++++++++++-
 1 file changed, 19 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
index fa89be500fb85..48d7e7f83c285 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
@@ -26,7 +26,25 @@ &i2c2 {
 
 	status = "okay";
 
-	/* ST,FTS @ 49 */
+	touchscreen@49 {
+		compatible = "st,stmfts5";
+		reg = <0x49>;
+
+		pinctrl-0 = <&touchscreen_pins &touchscreen_reset>;
+		pinctrl-names = "default";
+
+		interrupt-parent = <&tlmm>;
+		interrupts = <125 IRQ_TYPE_LEVEL_LOW>;
+
+		switch-gpios = <&tlmm 136 GPIO_ACTIVE_HIGH>;
+		reset-gpios = <&tlmm 99 GPIO_ACTIVE_LOW>;
+
+		avdd-supply = <&vreg_l14a_1p8>;
+		vdd-supply = <&vreg_l19a_3p3>;
+
+		touchscreen-size-x = <1080>;
+		touchscreen-size-y = <2160>;
+	};
 };
 
 &mdss_dsi0 {

-- 
2.53.0

