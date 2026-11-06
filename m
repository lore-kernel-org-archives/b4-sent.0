From: Andrew Gigena <mail@andrewgigena.dev>
Date: Fri, 06 Nov 2026 03:24:52 +0000
Subject: [PATCH v2 1/5] dt-bindings: i2c: qcom-cci: Document SM8150
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-sm8150-v7.4-rc1-camss-v2-1-39ee37787b00@andrewgigena.dev>
References: <20261106-sm8150-v7.4-rc1-camss-v2-0-39ee37787b00@andrewgigena.dev>
In-Reply-To: <20261106-sm8150-v7.4-rc1-camss-v2-0-39ee37787b00@andrewgigena.dev>
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Robert Foss <rfoss@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, Andrew Gigena <mail@andrewgigena.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793935531; l=1044;
 i=mail@andrewgigena.dev; s=20261104; h=from:subject:message-id;
 bh=sa4H+sId6xjwTKga9V2ilYs1U4cIetnjPZQJfvPUFeM=;
 b=zKSBOehskHj8OCCfbZWVn/cYD5BlWB0dn8wN4oS57cGNV0bVlKjCgwg8PLDrx3yGpjagItAce
 58dtYbm8R/IA3K39QgxQfB/j3KfOrb5oiaIsYSw0IjSX3tKSrfwRWzh
X-Developer-Key: i=mail@andrewgigena.dev; a=ed25519;
 pk=OMhlYIBaOEC8g4mJ4JCKy7kbg+lrwRxuujieZF8Ne6U=
X-Endpoint-Received: by B4 Relay for mail@andrewgigena.dev/20261104 with auth_id=1402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add qcom,sm8150-cci as a CCI v2 compatible, with qcom,msm8996-cci as
the fallback.

Signed-off-by: Andrew Gigena <mail@andrewgigena.dev>
---
 Documentation/devicetree/bindings/i2c/qcom,i2c-cci.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/i2c/qcom,i2c-cci.yaml b/Documentation/devicetree/bindings/i2c/qcom,i2c-cci.yaml
index 1e8def25ec0e..1e7a8efaa398 100644
--- a/Documentation/devicetree/bindings/i2c/qcom,i2c-cci.yaml
+++ b/Documentation/devicetree/bindings/i2c/qcom,i2c-cci.yaml
@@ -39,6 +39,7 @@ properties:
               - qcom,shikra-cci
               - qcom,sm6150-cci
               - qcom,sm6350-cci
+              - qcom,sm8150-cci
               - qcom,sm8250-cci
               - qcom,sm8450-cci
               - qcom,sm8550-cci
@@ -218,6 +219,7 @@ allOf:
           contains:
             enum:
               - qcom,sc7280-cci
+              - qcom,sm8150-cci
               - qcom,sm8250-cci
               - qcom,sm8450-cci
     then:

-- 
2.56.0

