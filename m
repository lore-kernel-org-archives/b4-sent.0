From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 18 Aug 2025 15:33:47 +0400
Subject: [PATCH 2/2] arm64: dts: qcom: ipq5018: Remove tsens v1 fallback
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250818-ipq5018-tsens-fix-v1-2-0f08cf09182d@outlook.com>
References: <20250818-ipq5018-tsens-fix-v1-0-0f08cf09182d@outlook.com>
In-Reply-To: <20250818-ipq5018-tsens-fix-v1-0-0f08cf09182d@outlook.com>
To: Amit Kucheria <amitk@kernel.org>, 
 Thara Gopinath <thara.gopinath@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sricharan Ramabadhran <quic_srichara@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755516829; l=972;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=HJcOgtw7oiilIyh0aWOOzNZ2iln5P6lSb3GMC6Gave0=;
 b=uR1EVwZAX79JKZzxxM9N7TA/hO1CtlDORhZ/FGhSsA68dLhwH953wdmIPFDj4vfeWpsTsB3Bh
 4W66WWUho9RBMALQ66he3JtRH90AzRDuzcypOj7GRnzE6ehzDO8Gl3R
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove qcom,tsens-v1 as fallback compatible since this IP has no RPM
and, as such, must use its own init routine available in the driver.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 4ddb56d63f8f9a963cb49bc20e0a78b2d3490344..db7051a659221d45949cda93472e52c49815531f 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -340,7 +340,7 @@ prng: rng@e3000 {
 		};
 
 		tsens: thermal-sensor@4a9000 {
-			compatible = "qcom,ipq5018-tsens", "qcom,tsens-v1";
+			compatible = "qcom,ipq5018-tsens";
 			reg = <0x004a9000 0x1000>,
 			      <0x004a8000 0x1000>;
 

-- 
2.50.1

