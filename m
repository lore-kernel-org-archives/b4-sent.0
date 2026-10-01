From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Thu, 01 Oct 2026 18:55:36 +0200
Subject: [PATCH v4 3/3] arm64: dts: amlogic: a1-c3-s4-t7: Add bus clock to
 PWM controller nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-add-t7-sys-pwm-clk-v4-3-8ed2b1e0cdfe@aliel.fr>
References: <20261001-add-t7-sys-pwm-clk-v4-0-8ed2b1e0cdfe@aliel.fr>
In-Reply-To: <20261001-add-t7-sys-pwm-clk-v4-0-8ed2b1e0cdfe@aliel.fr>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=10307;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=0noFD4QaLLZlEqbQPJmnIuc/5yYJNcuXmbeBKVxdegY=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9a+CdutD7Q6Pzq7s+L5l+Z916enJt3jtyj0M3jnffF7+
 r4OQWOmjlIWBjEuBlkxRZb+uZYn3l0+eubrHvUUmDmsTCBDGLg4BWAimhIM/0w/zX55Ku7Z3pzf
 +srntZZsW8r5+w3Pms22hS+Zunv6Ns5hZGg6WlPkpSKyY0bH5PBAE5mn53RnaFhwrGU5kLiuVEV
 ajhEA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the system clock of each PWM controller as a third clock,
and add the clock-names property expected by the updated binding:
"channel-a", "channel-b" and "bus".

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi | 28 +++++++++++++++++++++-------
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi | 28 +++++++++++++++++++++-------
 arch/arm64/boot/dts/amlogic/meson-a1.dtsi   | 12 +++++++++---
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi   | 20 +++++++++++++++-----
 4 files changed, 66 insertions(+), 22 deletions(-)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi
index 4e6757a57fb9a..2de68d2a2fb53 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi
@@ -824,7 +824,9 @@ pwm_mn: pwm@54000 {
 					     "amlogic,meson-s4-pwm";
 				reg = <0x0 0x54000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_M>,
-					 <&clkc_periphs CLKID_PWM_N>;
+					 <&clkc_periphs CLKID_PWM_N>,
+					 <&clkc_periphs CLKID_SYS_PWM_MN>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -843,7 +845,9 @@ pwm_ab: pwm@58000 {
 					     "amlogic,meson-s4-pwm";
 				reg = <0x0 0x58000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_A>,
-					 <&clkc_periphs CLKID_PWM_B>;
+					 <&clkc_periphs CLKID_PWM_B>,
+					 <&clkc_periphs CLKID_SYS_PWM_AB>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -853,7 +857,9 @@ pwm_cd: pwm@5a000 {
 					     "amlogic,meson-s4-pwm";
 				reg = <0x0 0x5a000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_C>,
-					 <&clkc_periphs CLKID_PWM_D>;
+					 <&clkc_periphs CLKID_PWM_D>,
+					 <&clkc_periphs CLKID_SYS_PWM_CD>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -863,7 +869,9 @@ pwm_ef: pwm@5c000 {
 					     "amlogic,meson-s4-pwm";
 				reg = <0x0 0x5c000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_E>,
-					 <&clkc_periphs CLKID_PWM_F>;
+					 <&clkc_periphs CLKID_PWM_F>,
+					 <&clkc_periphs CLKID_SYS_PWM_EF>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -873,7 +881,9 @@ pwm_gh: pwm@5e000 {
 					     "amlogic,meson-s4-pwm";
 				reg = <0x0 0x5e000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_G>,
-					 <&clkc_periphs CLKID_PWM_H>;
+					 <&clkc_periphs CLKID_PWM_H>,
+					 <&clkc_periphs CLKID_SYS_PWM_GH>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -883,7 +893,9 @@ pwm_ij: pwm@60000 {
 					     "amlogic,meson-s4-pwm";
 				reg = <0x0 0x60000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_I>,
-					 <&clkc_periphs CLKID_PWM_J>;
+					 <&clkc_periphs CLKID_PWM_J>,
+					 <&clkc_periphs CLKID_SYS_PWM_IJ>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -893,7 +905,9 @@ pwm_kl: pwm@62000 {
 					     "amlogic,meson-s4-pwm";
 				reg = <0x0 0x62000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_K>,
-					 <&clkc_periphs CLKID_PWM_L>;
+					 <&clkc_periphs CLKID_PWM_L>,
+					 <&clkc_periphs CLKID_SYS_PWM_KL>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
diff --git a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
index 8f3f1c0579a0f..92fd7e6e6a84f 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
@@ -692,7 +692,9 @@ pwm_ao_ef: pwm@30000 {
 				compatible = "amlogic,t7-pwm", "amlogic,meson-s4-pwm";
 				reg = <0x0 0x30000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_AO_E>,
-					 <&clkc_periphs CLKID_PWM_AO_F>;
+					 <&clkc_periphs CLKID_PWM_AO_F>,
+					 <&clkc_periphs CLKID_SYS_PWM_AO_EF>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -701,7 +703,9 @@ pwm_ao_gh: pwm@32000 {
 				compatible = "amlogic,t7-pwm", "amlogic,meson-s4-pwm";
 				reg = <0x0 0x32000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_AO_G>,
-					 <&clkc_periphs CLKID_PWM_AO_H>;
+					 <&clkc_periphs CLKID_PWM_AO_H>,
+					 <&clkc_periphs CLKID_SYS_PWM_AO_GH>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -715,7 +719,9 @@ pwm_ab: pwm@58000 {
 				compatible = "amlogic,t7-pwm", "amlogic,meson-s4-pwm";
 				reg = <0x0 0x58000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_A>,
-					 <&clkc_periphs CLKID_PWM_B>;
+					 <&clkc_periphs CLKID_PWM_B>,
+					 <&clkc_periphs CLKID_SYS_PWM_AB>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -724,7 +730,9 @@ pwm_cd: pwm@5a000 {
 				compatible = "amlogic,t7-pwm", "amlogic,meson-s4-pwm";
 				reg = <0x0 0x5a000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_C>,
-					 <&clkc_periphs CLKID_PWM_D>;
+					 <&clkc_periphs CLKID_PWM_D>,
+					 <&clkc_periphs CLKID_SYS_PWM_CD>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -733,7 +741,9 @@ pwm_ef: pwm@5c000 {
 				compatible = "amlogic,t7-pwm", "amlogic,meson-s4-pwm";
 				reg = <0x0 0x5c000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_E>,
-					 <&clkc_periphs CLKID_PWM_F>;
+					 <&clkc_periphs CLKID_PWM_F>,
+					 <&clkc_periphs CLKID_SYS_PWM_EF>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -742,7 +752,9 @@ pwm_ao_ab: pwm@5e000 {
 				compatible = "amlogic,t7-pwm", "amlogic,meson-s4-pwm";
 				reg = <0x0 0x5e000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_AO_A>,
-					 <&clkc_periphs CLKID_PWM_AO_B>;
+					 <&clkc_periphs CLKID_PWM_AO_B>,
+					 <&clkc_periphs CLKID_SYS_PWM_AO_AB>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -751,7 +763,9 @@ pwm_ao_cd: pwm@60000 {
 				compatible = "amlogic,t7-pwm", "amlogic,meson-s4-pwm";
 				reg = <0x0 0x60000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_AO_C>,
-					 <&clkc_periphs CLKID_PWM_AO_D>;
+					 <&clkc_periphs CLKID_PWM_AO_D>,
+					 <&clkc_periphs CLKID_SYS_PWM_AO_CD>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
diff --git a/arch/arm64/boot/dts/amlogic/meson-a1.dtsi b/arch/arm64/boot/dts/amlogic/meson-a1.dtsi
index 6f6a6145cba12..a224cbc959e45 100644
--- a/arch/arm64/boot/dts/amlogic/meson-a1.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-a1.dtsi
@@ -544,7 +544,9 @@ pwm_ab: pwm@2400 {
 				reg = <0x0 0x2400 0x0 0x24>;
 				#pwm-cells = <3>;
 				clocks = <&clkc_periphs CLKID_PWM_A>,
-					 <&clkc_periphs CLKID_PWM_B>;
+					 <&clkc_periphs CLKID_PWM_B>,
+					 <&clkc_periphs CLKID_PWM_AB>;
+				clock-names = "channel-a", "channel-b", "bus";
 				power-domains = <&pwrc PWRC_I2C_ID>;
 				status = "disabled";
 			};
@@ -555,7 +557,9 @@ pwm_cd: pwm@2800 {
 				reg = <0x0 0x2800 0x0 0x24>;
 				#pwm-cells = <3>;
 				clocks = <&clkc_periphs CLKID_PWM_C>,
-					 <&clkc_periphs CLKID_PWM_D>;
+					 <&clkc_periphs CLKID_PWM_D>,
+					 <&clkc_periphs CLKID_PWM_CD>;
+				clock-names = "channel-a", "channel-b", "bus";
 				power-domains = <&pwrc PWRC_I2C_ID>;
 				status = "disabled";
 			};
@@ -655,7 +659,9 @@ pwm_ef: pwm@5400 {
 				reg = <0x0 0x5400 0x0 0x24>;
 				#pwm-cells = <3>;
 				clocks = <&clkc_periphs CLKID_PWM_E>,
-					 <&clkc_periphs CLKID_PWM_F>;
+					 <&clkc_periphs CLKID_PWM_F>,
+					 <&clkc_periphs CLKID_PWM_EF>;
+				clock-names = "channel-a", "channel-b", "bus";
 				power-domains = <&pwrc PWRC_I2C_ID>;
 				status = "disabled";
 			};
diff --git a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
index 2a6fbd5308362..537e269642905 100644
--- a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
@@ -685,7 +685,9 @@ pwm_ab: pwm@58000 {
 				compatible = "amlogic,meson-s4-pwm";
 				reg = <0x0 0x58000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_A>,
-					 <&clkc_periphs CLKID_PWM_B>;
+					 <&clkc_periphs CLKID_PWM_B>,
+					 <&clkc_periphs CLKID_PWM_AB>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -694,7 +696,9 @@ pwm_cd: pwm@5a000 {
 				compatible = "amlogic,meson-s4-pwm";
 				reg = <0x0 0x5a000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_C>,
-					 <&clkc_periphs CLKID_PWM_D>;
+					 <&clkc_periphs CLKID_PWM_D>,
+					 <&clkc_periphs CLKID_PWM_CD>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -703,7 +707,9 @@ pwm_ef: pwm@5c000 {
 				compatible = "amlogic,meson-s4-pwm";
 				reg = <0x0 0x5c000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_E>,
-					 <&clkc_periphs CLKID_PWM_F>;
+					 <&clkc_periphs CLKID_PWM_F>,
+					 <&clkc_periphs CLKID_PWM_EF>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -712,7 +718,9 @@ pwm_gh: pwm@5e000 {
 				compatible = "amlogic,meson-s4-pwm";
 				reg = <0x0 0x5e000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_G>,
-					 <&clkc_periphs CLKID_PWM_H>;
+					 <&clkc_periphs CLKID_PWM_H>,
+					 <&clkc_periphs CLKID_PWM_GH>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};
@@ -721,7 +729,9 @@ pwm_ij: pwm@60000 {
 				compatible = "amlogic,meson-s4-pwm";
 				reg = <0x0 0x60000 0x0 0x24>;
 				clocks = <&clkc_periphs CLKID_PWM_I>,
-					 <&clkc_periphs CLKID_PWM_J>;
+					 <&clkc_periphs CLKID_PWM_J>,
+					 <&clkc_periphs CLKID_PWM_IJ>;
+				clock-names = "channel-a", "channel-b", "bus";
 				#pwm-cells = <3>;
 				status = "disabled";
 			};

-- 
2.49.0

