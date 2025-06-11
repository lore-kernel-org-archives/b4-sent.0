From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 11 Jun 2025 09:12:45 +0400
Subject: [PATCH v11 1/2] dt-bindings: thermal: qcom-tsens: make ipq5018
 tsens standalone compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250611-ipq5018-tsens-v11-1-266566bfd16a@outlook.com>
References: <20250611-ipq5018-tsens-v11-0-266566bfd16a@outlook.com>
In-Reply-To: <20250611-ipq5018-tsens-v11-0-266566bfd16a@outlook.com>
To: Amit Kucheria <amitk@kernel.org>, 
 Thara Gopinath <thara.gopinath@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749618782; l=1207;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=dHBmhXwIxbyNN1gtQFZSEd0dq6VfiMuKbDQhkACE3hE=;
 b=eOanNQKqA5mVLoWHxpGyHdTUExNDjlY5q6Cm6ZAM0bKV64d8K0VVhClEIjKjZ/X0LvfsDBHjw
 ITS+KWnt2q7COW7SuzxNoOw6/SBBd6hD3h04FMuTyCRxxVBOBijkHpT
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPQ5018 tsens should not use qcom,tsens-v1 as fallback since it has no RPM
and, as such, deviates from the standard v1 init routine in the driver.
So let's make qcom,ipq5018-tsens a standalone compatible in the bindings.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 Documentation/devicetree/bindings/thermal/qcom-tsens.yaml | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml b/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
index 0e653bbe9884953b58c4d8569b8d096db47fd54f..73d722bda8adc2c930edfc3373e6011f19c7c491 100644
--- a/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
+++ b/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
@@ -36,10 +36,13 @@ properties:
               - qcom,msm8974-tsens
           - const: qcom,tsens-v0_1
 
+      - description: v1 of TSENS
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

