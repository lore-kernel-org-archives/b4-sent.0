From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 18 Aug 2025 15:33:46 +0400
Subject: [PATCH 1/2] dt-bindings: thermal: qcom-tsens: make ipq5018 tsens
 standalone compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250818-ipq5018-tsens-fix-v1-1-0f08cf09182d@outlook.com>
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
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755516829; l=1557;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=h6GA/ttuT5bOVLTfp0krHWJVqoQSwvPud4lHYllswcw=;
 b=Jz8rZ8j0SE3OH7xPW3fuaGbzqG1ZtX07jgsJ254EVi9k1/G3+YpCotI53W7PKERBFReUjY38r
 Eh9gtlGjDw6BbcodGpLI6WBxE1mqtSlwkeMv2azigjmy30tOdUtu4nO
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The tsens IP found in the IPQ5018 SoC should not use qcom,tsens-v1 as
fallback since it has no RPM and, as such, must deviate from the
standard v1 init routine as this version of tsens needs to be explicitly
reset and enabled in the driver.

So let's make qcom,ipq5018-tsens a standalone compatible in the bindings.

Fixes: 77c6d28192ef ("dt-bindings: thermal: qcom-tsens: Add ipq5018 compatible")
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 Documentation/devicetree/bindings/thermal/qcom-tsens.yaml | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml b/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
index 94311ebd7652d42eb6f3ae0dba792872c90b623f..9f342e63bdb1d27bd12373fb4c7611964bfd8d4b 100644
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
2.50.1

