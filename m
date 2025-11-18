From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Nov 2025 15:11:37 +0100
Subject: [PATCH 3/3] arm64: dts: qcom: sdm845-oneplus: Mark l14a regulator
 as boot-on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-dts-oneplus-regulators-v1-3-79fb2f0f253b@ixit.cz>
References: <20251118-dts-oneplus-regulators-v1-0-79fb2f0f253b@ixit.cz>
In-Reply-To: <20251118-dts-oneplus-regulators-v1-0-79fb2f0f253b@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, 
 Casey Connolly <casey.connolly@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=887; i=david@ixit.cz;
 h=from:subject:message-id; bh=Ta5X0H3ltp/2yAQWkY/Fdyk+Qj+G9KOs3FeZkTC/U5s=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHH6YcfF51/xBAeogwUNzgphE1Yy20ZD2ET90k
 +1NWhhPMP6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRx+mAAKCRBgAj/E00kg
 ctXXD/9LEYvaE0K1FzUiwLuIWfYcw/VTW8WR/cKXOVllao1s06aXjdtuWREjaBnxrLx3LpHGnEw
 RAuSD9z6+R32xWd0UWHPs7J2SrZfpfVZG9/FzeSHy3plaYZw/0InpNwIoEXZaWBBOzk/ZMJnzBA
 aj230OscC2bv4nDI0kQGRWa1WLD6l1UKpJX3SNrAADEUJxczRhZFBCJdqfvxStCqSkzACSgYrne
 9DgG2CqpV5INxVD8A1tEUBBPl5Msfa1nAFb0TU8TQhaJoZnT8E88KpWeKi3vyrJpUB9L5EMymT3
 6ozX0ynZct0Krvf0/TQ/suNxlhDoikJvkUJmSQ2rcVXNN1UroYp3oV22ifsSfT6vOgtin+vPOpk
 9uPWaWccwwkbh0/H/3yWO2Nzxu5G/XUbr9tfN/nCw+qaoQDtYpBKIPgBvt86Zn1Rdh6TlFSUrBY
 1p/MOYo6cW7nFL6HX1L8d6ILaJ1xhoYS18W+6TGmAdYGQEnci+dbvmDS6DtMK6WEeMWJzFyhpBh
 hmhzCxybtK93MpogboBoRjFAo6TErEU24Lc8j/Vn2JtiZtNdt4ZC8Rbwsl3If7CVLYB6U2MfaUn
 DbZm1Pg6yLFb2U3bRt4qNIhxi72nR46xT+9tcWL2579iLjxJuHRfJfOyZCgpJm6qUFOTYGjQKts
 oM31uLMCPU+Q1Ow==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

This regulator is used only for the display, which is enabled by the
bootloader and left on for continuous splash. Mark it as such.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 5845bc3bb80b2..8251f5a2f9475 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -272,6 +272,7 @@ vreg_l14a_1p88: ldo14 {
 			regulator-min-microvolt = <1800000>;
 			regulator-max-microvolt = <1800000>;
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+			regulator-boot-on;
 		};
 
 		vreg_l17a_1p3: ldo17 {

-- 
2.51.0

