From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Nov 2025 15:11:36 +0100
Subject: [PATCH 2/3] arm64: dts: qcom: sdm845-oneplus: Don't keep panel
 regulator always on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-dts-oneplus-regulators-v1-2-79fb2f0f253b@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=831; i=david@ixit.cz;
 h=from:subject:message-id; bh=fSwmAdAODVY3a5d8qwwfw9ZcbtoqAA/tA2uqDntufkQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHH6YOyXwIcpUQpnj4K3a3ZhIFRPBzu5KIsbrS
 WLpQ7R4FtOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRx+mAAKCRBgAj/E00kg
 coZaD/912SaSI4kHNtF+1bWXzh8FR1R2aLvkTetShH97LGXknswcn4fvvnR0QxromIb5KBMx/Jp
 RIIxunxebJ8dbaqMkLdDdpLPCRivKUknLQcwqLpVnXE7hzCMot1FJPYb4CjZ0jtxbjPN7EdP8BW
 IFBV7pOVmkvGaFJBDGcl98jZ4JaVb2hu4hcSFiAw10L7mItvjmkmmXMDoSRg+BoklrBXcFzc5Tt
 /AaKXxUNfOLzlld5OgqaDI6/yI1Z2kuNc+KY0I46xBHyLxBKAsJzXWNBQVr98HswcyJ+FxO0yKa
 rEnWVUnICd9CSeS5fzyYsupO+LSH07aYh+kXQJaYSPM46uw5rb/OBTiEH9MHCPiQUgUdxAgMXHS
 kUMVWHO0BZ8q5MrqgtaQjvG2x3OvHqgVf8M9inT+vfcG3UcZPXaid/Mmf1ZEInBDo84xuy/EgJf
 nSLtHLNhEqsFcwbyO0jxcB2tUfJxhByi+RBLb1obJM7WW+7HAnUkGGXnCMcXDyVoTkpLAzKt+dl
 LOOxVrT/wox1CKrj0YqsibFVcULNUA+bBRxLQBmUAFNDqKQwZWsMM6poEvgxCo6iNJVm5yawqPY
 raxuTgKp4XT413XlCc/IziMUpPlpmjX0qvyKUTIuSpkpEjyAj4dN/nj1PRiMuFz/uO6lAdOiqgO
 8jDk0kJm6KLW3ZQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

The panel regulator doesn't need to be always on, so remove this
property.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index ee62adfa6af0b..5845bc3bb80b2 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -272,7 +272,6 @@ vreg_l14a_1p88: ldo14 {
 			regulator-min-microvolt = <1800000>;
 			regulator-max-microvolt = <1800000>;
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
-			regulator-always-on;
 		};
 
 		vreg_l17a_1p3: ldo17 {

-- 
2.51.0

