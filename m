From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Nov 2025 15:52:27 +0100
Subject: [PATCH v2 3/3] arm64: dts: qcom: sdm845-oneplus: Mark l14a
 regulator as boot-on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-dts-oneplus-regulators-v2-3-3e67cea1e4e7@ixit.cz>
References: <20251118-dts-oneplus-regulators-v2-0-3e67cea1e4e7@ixit.cz>
In-Reply-To: <20251118-dts-oneplus-regulators-v2-0-3e67cea1e4e7@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=956; i=david@ixit.cz;
 h=from:subject:message-id; bh=asJlnClcHp0fv4e2caydGSPUa8vKn55oet229kJb8As=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHIgrc2s9azOkHbeJ9bWIEeEKidzuyXXHEvmhr
 fruRkFAYveJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRyIKwAKCRBgAj/E00kg
 ctr9D/9OI2nJX0LotRDlNe6zih50k2xZBeDe/8TLxHJvoECawKClZD0W09j1xPnskFCHVykSXA+
 qnjMm4EoVAt3JxhcTgsAy+jPILS2lPS42NsTa/VCBiJV16g1WfzOor3yZ4I4ECmcQ3xijwIw3RW
 VCqcSSLpmD50vdLHH0XI6twkslt6Ujz0mrewwCyoAY8K+8Cu1SZN/k+MA6E3rBSMVS60xWQTDiN
 O7MCW/+8Jkv0ffXyXHa4/LbFUg6dhol3lXlO6ODk1G2sujV0Bj1gP6l+3SIoS7T2ky6M/vfCClv
 NmSWRaqeuGxf1u5c69qYxepe3wGbtWD/ooSvEYRAxppmMGqOELiQ29rh6UKLT8VEttq6EaG+ry6
 107naSm3AGgVv4wltzOaCOMN9mkkvXytYoOFhA93FrZlQ3dCIDSBV+O0QIwkiRP7PlKVuQEqT56
 KHxw+pG+LGaGPE4R+/VhaXiSUbDV4oVu5kpiyqRlbnf+ssjYdJCU8VhLSCrSkHfs1Z+ZTvOONB7
 qFAkueHsYAQMIJGJO/oe+aOVeXO3Wa0tH8ihQVOMKhh+pbBp+BbaIFa6IqFvGXgZyyPcrZGwtyr
 ar2lfznzfipF2rvrQqUByaJqOjAPdMOdSdgkek6Ma7S62bYYqECVZL7UxzTpHaEVHzA+hgRW363
 VvwcZ1Wkn8Kcslw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

This regulator is used only for the display, which is enabled by the
bootloader and left on for continuous splash. Mark it as such.

Fixes: 288ef8a42612 ("arm64: dts: sdm845: add oneplus6/6t devices")
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

