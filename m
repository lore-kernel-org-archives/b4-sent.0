From: =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
Date: Mon, 01 Jun 2026 18:55:37 +0200
Subject: [PATCH v4 2/3] arm64: dts: qcom: sdm670: add debug uart soc node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v4-2-c5d51dd96ca0@postmarketos.org>
References: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v4-0-c5d51dd96ca0@postmarketos.org>
In-Reply-To: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v4-0-c5d51dd96ca0@postmarketos.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1353;
 i=pabloyoyoista@postmarketos.org; h=from:subject:message-id;
 bh=PKWUit6YaDLgMvBcmHsB+WvICXOjhQdpimwGRlG8xpo=;
 b=owEBbQKS/ZANAwAKAXo0JWX/Y195AcsmYgBqHbmUCLYggOFkMCTXQ0wYBdLc819CRcZPTqLgY
 7oHxZINky+JAjMEAAEKAB0WIQS9CheUSi6o/ykTCaJ6NCVl/2NfeQUCah25lAAKCRB6NCVl/2Nf
 eVsQEACrECCW94nloXYFpEm0NV4xmamMUONm1jvXlEEfxC1Ro87zxy0zbGEblDhJAxzKhm7fGxC
 1QnFURUtywGdLlGlm3E5TUAv+dDmtLO/Cv5+QypEl9j35oalN7KxdZqwVAJS9OCLKM2bzRpnS3F
 hjOd404yIgcmJvymEqEk5bU82Wz1rQQQBd1ql8c+N99tWA+6U5/db8ySZm/RpXg+5EUlfDPeSk2
 OOmtptzVR576LPfyhgzrfPvpbktEji13Mha8kQO4I1qMuWk3Q8yCyeTUJtM00+aPruzH3vQWDyR
 YGXESUhuDJe9q6e0XvCE/tidBUVT6qPwhj5TmoPPi7VTFUKTkDK2IjnCzI6AQ5XsXkB+a8TlTZ0
 PhKDEpccAjXaaLL2lXyH/R4BU+jGSnBgjBFCmMqK4VIqqm2Nldqp3CHCZkaCJbez7c92qS8Eufk
 jtB/vK6huGTEYb+vVpOpVRfWVIYjMfoIHRcbgeksH0B5uRotvlQGuW1fg7aJdl6BEvBaLpOqroN
 PrFvR6amliX0a9fzD2ZmVXZNCNRfEXlQ+YQHxRAzK67wFIs6+Nfj5AYplPUq0fDfJ/gyE3dY/y0
 1+iROmh9WFK8fl1Cq4iH6ChtYihOapj8NX/b9tN8x0oU1GOObEk7NaKPQocYnvSnCi94NrZsGJz
 vlV5HJLD9HQ2uEw==
X-Developer-Key: i=pabloyoyoista@postmarketos.org; a=openpgp;
 fpr=BD0A17944A2EA8FF291309A27A342565FF635F79
X-Endpoint-Received: by B4 Relay for pabloyoyoista@postmarketos.org/default with auth_id=698
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Values are taken from the other geni nodes

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: Pablo Correa Gómez <pabloyoyoista@postmarketos.org>
---
 arch/arm64/boot/dts/qcom/sdm670.dtsi | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm670.dtsi b/arch/arm64/boot/dts/qcom/sdm670.dtsi
index 1c6c18a913a0..400d5d8ef9fa 100644
--- a/arch/arm64/boot/dts/qcom/sdm670.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm670.dtsi
@@ -1060,6 +1060,21 @@ i2c12: i2c@a90000 {
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
2.54.0

