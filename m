From: =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
Date: Sat, 28 Mar 2026 23:58:41 +0100
Subject: [PATCH v2 2/3] arm64: dts: qcom: sdm670: add debug uart soc node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v2-2-53abd9db8f0a@postmarketos.org>
References: <20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v2-0-53abd9db8f0a@postmarketos.org>
In-Reply-To: <20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v2-0-53abd9db8f0a@postmarketos.org>
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
 b=owEBbQKS/ZANAwAKAXo0JWX/Y195AcsmYgBpyF0iwB/xXRhz8L+4jRjNqXpXSXx9QDCNjJ8An
 LuCy+B2y+iJAjMEAAEKAB0WIQS9CheUSi6o/ykTCaJ6NCVl/2NfeQUCachdIgAKCRB6NCVl/2Nf
 eX9AD/9zmEu8SAarJ0+mCQo4cq3vPVVFuf7ZF8F/1vLWKmFMlfzqP0qpsam4Xr3x99bB2W19DKJ
 v+R1TX2w4aINZ5RyufvhQRDElwle0+bVXGJxPLZ9fv6cuouXDlO2vclcKoJ8SX1DzXboAMl+Uxs
 YC2y4KaDOL1H7Oo1JgBqWIWvc7UxGkezVBf2vsr8Ca6uTL6kKYf1Z/Q13y3sFISBv3Wg2OWAyhy
 4xYUex7wTIJ12oVJ7RqEQ8oBuw7BA1lLGTmbD6bFaM7d+ynvJu+9LweWeHEINe9AjbWi4iga8BQ
 2ho/goNBPrcMJfek33MhbWD01NJRK99+lAH6ysAIyA2Gxm1SfzmXdgURAX+TRGunkn50k9en2ax
 jnA5wfASR0z1EMx9wOtPgz07gSCBg51oojlvvazLtEV/TR8dLbUYSRGQV+zq+wamNLTAXq6QneB
 LIP12CZYuUcN+W/RB6Fb6KVWXod+smZ53m9HY73R/5qAFOMXcM8ir6q3TI+4WFhMiKLzOgfYzUz
 ka6JB6abKAwO6YisMdKu4b8UyBc6tMrS1wtz3fK5dunTn5qk2Lp3yBmGZV+NSTJ5ArPVe52g5eO
 BOup3l33DZTXLJf3HPuUWY+hzGrd2imEplEg+irbIzsizqjJaqM/vo1MF9hkuG4bo6ukI3aJ7/X
 tIdkvw6Vo0J2D5Q==
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

