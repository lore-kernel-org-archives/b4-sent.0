From: David Heidelberg <david@ixit.cz>
Date: Wed, 04 Feb 2026 18:03:41 +0100
Subject: [PATCH] testing! arm64: dts: qcom: decrease WiFi antenna regulator
 minimum to 3.0V
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260204-oneplus6-wifi-voltage-v1-1-ee6fd47f9d02@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAOx7g2kC/x2MWwqAIBAAryL7nZBCIl0l+pBtrYVQ0V4Q3j3pc
 2BmXiiUmQqM4oVMFxeOoYHqBODmwkqSl8agez0orYyMgdJ+FiNv9iyvuB+uSZYQLXpryCO0NmX
 y/Pzfaa71A3I3h2hnAAAA
X-Change-ID: 20251216-oneplus6-wifi-voltage-8ecc8cf86efc
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1386; i=david@ixit.cz;
 h=from:subject:message-id; bh=MU24/0EIkkFW4iVo90u34fUl4tbYSjVYYtHCLcNmzhI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpg3vttL5pwPV+sq8S27yyE9ZGek38daFoKqtkz
 lcccZPXB4mJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaYN77QAKCRBgAj/E00kg
 chLDEACm+c5AjJwx7etuRiWKrMxuYeqaDczPtr9XUafue2acCLjH4sFSi7MDwui3i6b4vYwg8ah
 zv7H47yGtLtKCeGA3QWhW52UouDimzbEjePwexkfRspE4by+RN4VjCvvEY8f3+2WQwllKv4wpw4
 T6DqU7isqI9u8z5U4Wf3NA/xk1WfFlhT2kAL74OviaxxJ0PN6gij8Ipoubfg042c5bMtiVxUvTY
 edxOycNeMzkXeBejtt6whLYaQwrnaOqL65pizd5YweFFYjRbDu0OF2dVoMpDYARBvnVamV8bdrY
 MkmVwI7aFa6FRtdpHfgROP2fFjhfOxk9cmmoqWQ4dDTGWIbVaFFXGkAzrM6EcsIDiOMsK7+204s
 aOOJSANkOi6FQMZDbdcRrtx53kwSns74qL6HIezwcvmGQo+eY/SBDokMb7Cxc/4Bd1dEONSESDi
 gJ+XAD1Fq/OYjBKcSSDq+MxVZVO6HFWhe6XcVfDmU0+1iQ1n5UOVFPBVRkm6KGn8DKW9v+9OrGm
 DVwCOsEZqv04i7UJ55HEkI4KV+f+pXTwJOmNnZJ11OrZ1lK0w2DmQZIOpjm/LMHhPa9HfblR45R
 4MnzfqiuQzQkKCd16qOaXxazh7Bt+MkdaQpgjC5ZRsVUw/QNargNUKZAF6ubwQ36HOE9snjVCRV
 vtmO7glK6idZy+g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Downstream defines minimal voltage as 3.0 V, while when OnePlus 6 was
introduced to Linux mainline, the value was fixed to maximum 3.3V.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Tested for ~ 1 month. Seems to work well, no visible issues anywhere.
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 5b121ea5520f5..e950db41ce25a 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -307,7 +307,7 @@ vreg_l20a_2p95: ldo20 {
 		};
 
 		vreg_l23a_3p3: ldo23 {
-			regulator-min-microvolt = <3300000>;
+			regulator-min-microvolt = <3000000>;
 			regulator-max-microvolt = <3312000>;
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
 		};
@@ -320,7 +320,7 @@ vreg_l24a_3p075: ldo24 {
 		};
 
 		vreg_l25a_3p3: ldo25 {
-			regulator-min-microvolt = <3300000>;
+			regulator-min-microvolt = <3000000>;
 			regulator-max-microvolt = <3312000>;
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
 		};

---
base-commit: 5c009020744fe129e4728e71c44a6c7816c9105e
change-id: 20251216-oneplus6-wifi-voltage-8ecc8cf86efc

Best regards,
-- 
David Heidelberg <david@ixit.cz>

