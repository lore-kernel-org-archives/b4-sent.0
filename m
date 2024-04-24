From: Xilin Wu <wuxilin123@gmail.com>
Date: Wed, 24 Apr 2024 23:29:11 +0800
Subject: [PATCH 06/10] arm64: dts: qcom: sm8550: Add UART15
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240424-ayn-odin2-initial-v1-6-e0aa05c991fd@gmail.com>
References: <20240424-ayn-odin2-initial-v1-0-e0aa05c991fd@gmail.com>
In-Reply-To: <20240424-ayn-odin2-initial-v1-0-e0aa05c991fd@gmail.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Junhao Xie <bigfoot@classfun.cn>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, Sam Ravnborg <sam@ravnborg.org>, 
 David Airlie <airlied@gmail.com>, Daniel Vetter <daniel@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Tengfei Fan <quic_tengfan@quicinc.com>, 
 Molly Sophia <mollysophia379@gmail.com>, Junhao Xie <bigfoot@classfun.cn>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-arm-msm@vger.kernel.org, Xilin Wu <wuxilin123@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713972563; l=1572;
 i=wuxilin123@gmail.com; s=20240424; h=from:subject:message-id;
 bh=OFzbypiVPytW4zM7r7H6VNiMNFxsnAj0i8lBbxZUWk8=;
 b=tQq4dufCVktTutlbsclvej4fOdX/xDLlbF43Jmj8yh8O2UYPrLVmE/j5VMRLoF9xN9P9u7ToH
 8xN5wY7sFBaCOU/0mIlgdQJD5X1zB0GGgNJcIwMJgMmy2rfyknDtryu
X-Developer-Key: i=wuxilin123@gmail.com; a=ed25519;
 pk=vPnxeJnlD/PfEbyQPZzaay5ezxI/lMrke7qXy31lSM8=
X-Endpoint-Received: by B4 Relay for wuxilin123@gmail.com/20240424 with auth_id=157
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add uart15 node for UART bus present on sm8550 SoC.

Signed-off-by: Molly Sophia <mollysophia379@gmail.com>
Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index bc5aeb05ffc3..b8bbe88e770f 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -1122,6 +1122,20 @@ spi15: spi@89c000 {
 				#size-cells = <0>;
 				status = "disabled";
 			};
+
+			uart15: serial@89c000 {
+				compatible = "qcom,geni-uart";
+				reg = <0 0x89c000 0 0x4000>;
+				clock-names = "se";
+				clocks = <&gcc GCC_QUPV3_WRAP2_S7_CLK>;
+				pinctrl-names = "default";
+				pinctrl-0 = <&qup_uart15_default>;
+				interrupts = <GIC_SPI 462 IRQ_TYPE_LEVEL_HIGH>;
+				interconnects = <&clk_virt MASTER_QUP_CORE_2 0 &clk_virt SLAVE_QUP_CORE_2 0>,
+						<&gem_noc MASTER_APPSS_PROC 0 &config_noc SLAVE_QUP_2 0>;
+				interconnect-names = "qup-core", "qup-config";
+				status = "disabled";
+			};
 		};
 
 		i2c_master_hub_0: geniqup@9c0000 {
@@ -3856,6 +3870,14 @@ qup_uart14_cts_rts: qup-uart14-cts-rts-state {
 				bias-pull-down;
 			};
 
+			qup_uart15_default: qup-uart15-default-state {
+				/* TX, RX */
+				pins = "gpio74", "gpio75";
+				function = "qup2_se7";
+				drive-strength = <2>;
+				bias-pull-up;
+			};
+
 			sdc2_sleep: sdc2-sleep-state {
 				clk-pins {
 					pins = "sdc2_clk";

-- 
2.44.0

