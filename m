From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 18:51:24 +0100
Subject: [PATCH 10/10] arm64: dts: qcom: sdm845-google: Add STM FTS
 touchscreen support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-stmfts5-v1-10-22c458b9ac68@ixit.cz>
References: <20260301-stmfts5-v1-0-22c458b9ac68@ixit.cz>
In-Reply-To: <20260301-stmfts5-v1-0-22c458b9ac68@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1269; i=david@ixit.cz;
 h=from:subject:message-id; bh=4/lfzEYYZjUSxYP/aTkLrRQ2VN8Psoxavi/IstIzuL0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppHyVaCX9KjhoeEmo7YHELzM8zuZw6Mbc4G6o0
 VIq1w9OLZWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaR8lQAKCRBgAj/E00kg
 ciBFD/41NrAOanfs7cx7e+2sECckL6NCNiYD4+R7Ez7hXveR0nbWJxveRy3dbRvMv6/MSxR/3M7
 9xyS9sWp24g3qnPNugFmVr5Sw7L5EXuW0dq7N56JBE9aAEab3D8E5CDyqqoNxYItk5Liv1oCvke
 oG2ZF6RO4fAEIdfScDi179tNE050cB3ddgWCm7kxwIh98oxNSUfVdYzXY2X3zDOeCyqs1xOrK1c
 JBRKed9j+vcJ22XL/nPZvN30P5EaD/yzbDJALiBdcZInagRoYRYrDLm/NIr09Kx85a5c/wQNqaA
 TTG6kv+SNNF/w3wuxb86eDrEegWJFhztfew5zKha8AQP/ikCnUwOT5OG8G9tyPkiG3YlMX861MG
 e9EYqc/JPDmpR0g3V/6FNqfO+nrfQb72T3n2ZgnRq/Q//+G+waw+uroFZuPEQRpb4lXqtJmZK6w
 cv74HQ8VTmTjzlGHOAeWPZuPyOKxZSmo1zIGlYRy9idGqNvkx+D8a5TGkDJXrqO+zXvXy1BuPLk
 LNU5vQm8hXUcmWFuIScQvTeeXX4B6Ucp27RDqM0fykYu6kWLj5mBUVk+C+Xy5jFQU/ZHLZIMhEx
 ZyAreXzqU3StjwAJx69dWraCNBF4HfZH8aB+r9LYuWOYOaLrra6j6FgOSYjx+Zxi3BID/E88zIL
 RvFppiUpphwbgLA==
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
 arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts | 21 ++++++++++++++++++++-
 1 file changed, 20 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
index fa89be500fb85..2501104b06e1b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
@@ -26,7 +26,26 @@ &i2c2 {
 
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
+		irq-gpios = <&tlmm 125 GPIO_ACTIVE_HIGH>;
+		switch-gpios = <&tlmm 136 GPIO_ACTIVE_HIGH>;
+		reset-gpios = <&tlmm 99 GPIO_ACTIVE_LOW>;
+
+		avdd-supply = <&vreg_l14a_1p8>;
+		vdd-supply = <&vreg_l19a_3p3>;
+
+		touchscreen-size-x = <1079>;
+		touchscreen-size-y = <2159>;
+	};
 };
 
 &mdss_dsi0 {

-- 
2.51.0

