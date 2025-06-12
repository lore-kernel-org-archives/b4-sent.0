From: George Moussalem <george.moussalem@outlook.com>
Date: Thu, 12 Jun 2025 10:46:13 +0400
Subject: [PATCH v13 1/2] dt-bindings: thermal: qcom-tsens: make ipq5018
 tsens standalone compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250612-ipq5018-tsens-v13-1-a210f3683240@outlook.com>
References: <20250612-ipq5018-tsens-v13-0-a210f3683240@outlook.com>
In-Reply-To: <20250612-ipq5018-tsens-v13-0-a210f3683240@outlook.com>
To: Amit Kucheria <amitk@kernel.org>, 
 Thara Gopinath <thara.gopinath@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Sricharan Ramabadhran <quic_srichara@quicinc.com>, 
 George Moussalem <george.moussalem@outlook.com>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <lumag@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749710807; l=1481;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=RrfwkZTGbLqY30+ytKz/HO9wG4uq1c9Mr1ofBKoxP4E=;
 b=JV4vzYOVMEIqr1xXu025PPhabPOfCtJ1SC7TXbHKhq0PCqcAu4KcyCyjyInoueJj9mJePaAwW
 0pYxKTEN0orAeImbzFYNwtkRK1F939eKoBNEtmtBbSqTmATjJnRu5iZ
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPQ5018 tsens should not use qcom,tsens-v1 as fallback since it has no RPM
and, as such, must deviates from the standard v1 init routine in the
driver as this version of tsens needs to be explicitly reset and enabled
in the driver.

So let's make qcom,ipq5018-tsens a standalone compatible in the bindings.

Fixes: 77c6d28192ef ("dt-bindings: thermal: qcom-tsens: Add ipq5018 compatible")
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 Documentation/devicetree/bindings/thermal/qcom-tsens.yaml | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml b/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
index 0e653bbe9884953b58c4d8569b8d096db47fd54f..3cf16f6734fcfee20735d3da2cfb0f708a11bca4 100644
--- a/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
+++ b/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
@@ -36,10 +36,15 @@ properties:
               - qcom,msm8974-tsens
           - const: qcom,tsens-v0_1
 
+      - description:
+          v1 of TSENS without RPM which requires to be explicitly reset
+          and enabled in the driver.
+        enum:
+          - qcom,ipq5018-tsens
+
       - description: v1 of TSENS
         items:
           - enum:
-              - qcom,ipq5018-tsens
               - qcom,msm8937-tsens
               - qcom,msm8956-tsens
               - qcom,msm8976-tsens

-- 
2.49.0

