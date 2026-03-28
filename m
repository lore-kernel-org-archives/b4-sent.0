From: =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
Date: Sat, 28 Mar 2026 23:49:15 +0100
Subject: [PATCH 2/3] arm64: dts: qcom: sdm670: add debug uart soc node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v1-2-0babf584acdb@postmarketos.org>
References: <20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v1-0-0babf584acdb@postmarketos.org>
In-Reply-To: <20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v1-0-0babf584acdb@postmarketos.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1225;
 i=pabloyoyoista@postmarketos.org; h=from:subject:message-id;
 bh=L1100JIpppZkEIE9KsBz4sU5OJaPhYVcFrm/i+/xKLw=;
 b=owEBbQKS/ZANAwAKAXo0JWX/Y195AcsmYgBpyFrrXUDnvwlheDZ+2hKu3twU3X75u12vBwfwQ
 Ue01ImBC9SJAjMEAAEKAB0WIQS9CheUSi6o/ykTCaJ6NCVl/2NfeQUCacha6wAKCRB6NCVl/2Nf
 edABD/9aqMSORu2P0cDJ2ZuBG55trNlwe2J+pMjrZIgTmr2gWZxj36RvEZ11a4rh+kcXfi1jr9N
 DDxKEC9baYhU1tc9o3DqcMqlV5I1hsZuHfJ5+RHFtbO06VenbcAqH/mciUVe5lQMdKtqqXImJ8m
 uB22mRXGmgBsTmumqYmVqMbM5JGwPfuqgMry6rd/0cGvVC7cA4YbP9LIRdOl1Z0juDrMkDvBmk8
 heVkHAHdoAoMQgAQuBmc9gQjEEBIgxOV9p1iMwcoOaK5pLiGphnVPKJBPJhfAoUg79Y5TI9glwq
 gFTB/9yah9qumsLbr0jiqDyD1Fxp7M1BZpcBCQLY8fauMOzsRFOYMXXkpABsPtmZTY0GYOAXWlM
 dHHQoM5gHSkJNTTMsMfQ6n5i4pmTCaTSutqGVDP3Ibzffj8UQYP3BUVrBfJpbz7ez3g9aL/Vi4N
 zh3LwbJB6nnyUr/4E+jHDffGqOWEhRQbaYbMmCIY7hMEp6cZ5yjIIZJjIjjWFf+4wkoBqj8gyx8
 f84JjIujJejG/cIAPS/GILd1MC56Io2rtPzSHuJbAyxmec+o8HGkPT2wX7cWmZyABOSN6WUnnYd
 VujlKnlU45BBjgOKhzpggl/nda47chqsBD2GOG9VFrLtQ+HgHtqjVGhJN3slyOodbcITevdX+AM
 ZCztYpWiwNMGKcw==
X-Developer-Key: i=pabloyoyoista@postmarketos.org; a=openpgp;
 fpr=BD0A17944A2EA8FF291309A27A342565FF635F79
X-Endpoint-Received: by B4 Relay for pabloyoyoista@postmarketos.org/default with auth_id=698
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Values are taken from the other geni nodes

Signed-off-by: Pablo Correa Gómez <pabloyoyoista@postmarketos.org>
---
 arch/arm64/boot/dts/qcom/sdm670.dtsi | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm670.dtsi b/arch/arm64/boot/dts/qcom/sdm670.dtsi
index 3e60ab527a42..25cf21c57b7d 100644
--- a/arch/arm64/boot/dts/qcom/sdm670.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm670.dtsi
@@ -1069,6 +1069,21 @@ i2c12: i2c@a90000 {
 				status = "disabled";
 			};
 
+			uart12: serial@a90000 {
+				compatible = "qcom,geni-debug-uart";
+				reg = <0 0x00a90000 0 0x4000>;
+				clock-names = "se";
+				clocks = <&gcc GCC_QUPV3_WRAP1_S4_CLK>;
+				pinctrl-names = "default";
+				pinctrl-0 = <&qup_uart12_default>;
+				interrupts = <GIC_SPI 357 IRQ_TYPE_LEVEL_HIGH>;
+				power-domains = <&rpmhpd SDM670_CX>;
+				interconnects = <&aggre2_noc MASTER_BLSP_2 0 &config_noc SLAVE_BLSP_2 0>,
+						<&gladiator_noc MASTER_AMPSS_M0 0 &config_noc SLAVE_BLSP_2 0>;
+				interconnect-names = "qup-core", "qup-config";
+				status = "disabled";
+			};
+
 			i2c13: i2c@a94000 {
 				compatible = "qcom,geni-i2c";
 				reg = <0 0x00a94000 0 0x4000>;

-- 
2.53.0

