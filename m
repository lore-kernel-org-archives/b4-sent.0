From: Andrew Gigena <mail@andrewgigena.dev>
Date: Wed, 04 Nov 2026 20:54:14 +0000
Subject: [PATCH 1/4] dt-bindings: i2c: qcom-cci: Document SM8150 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sm8150-v7-4-rc1-camss-v1-1-7a9534a9a22f@andrewgigena.dev>
References: <20261104-sm8150-v7-4-rc1-camss-v1-0-7a9534a9a22f@andrewgigena.dev>
In-Reply-To: <20261104-sm8150-v7-4-rc1-camss-v1-0-7a9534a9a22f@andrewgigena.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793825658; l=824;
 i=mail@andrewgigena.dev; s=20261104; h=from:subject:message-id;
 bh=XVSLS9H6xwSBH2lGXYB71v3KO52SQ4m6el0XgpZLD1k=;
 b=Z915qNsq3qCvxOBE7gkhR7XJf/ioLSll1yK9FC+POQEjF9HH38j/ZL/3XvZmMy3EqAWQRS3Sq
 vBZ0NOuYh+8D+nx8hRof2+J7yfsHzCJI4BizwxBUV+DJJAxS5hMabsH
X-Developer-Key: i=mail@andrewgigena.dev; a=ed25519;
 pk=OMhlYIBaOEC8g4mJ4JCKy7kbg+lrwRxuujieZF8Ne6U=
X-Endpoint-Received: by B4 Relay for mail@andrewgigena.dev/20261104 with auth_id=1402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add qcom,sm8150-cci as a CCI v2 compatible, with qcom,msm8996-cci as
the fallback.

Signed-off-by: Andrew Gigena <mail@andrewgigena.dev>
---
 Documentation/devicetree/bindings/i2c/qcom,i2c-cci.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/i2c/qcom,i2c-cci.yaml b/Documentation/devicetree/bindings/i2c/qcom,i2c-cci.yaml
index 1e8def25ec0e..b545fd2378da 100644
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

-- 
2.56.0

