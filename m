From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Sun, 10 May 2026 23:05:56 +0700
Subject: [PATCH 1/2] dt-bindings: arm: qcom: document the Ayaneo Pocket DS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260510-pocketds-v1-1-cf05acec06af@gmail.com>
References: <20260510-pocketds-v1-0-cf05acec06af@gmail.com>
In-Reply-To: <20260510-pocketds-v1-0-cf05acec06af@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778429157; l=948;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=vJKMcLbHKxPCtNvUiI9RU+V6jt5nuzR57sFHWslUAcM=;
 b=RC9TXt9OXg1qh+cv96ZFu3FDWL1JZlYjmo1/77Y9RUT+iUe6gVuycIhnLA3cBaHfLfn3seo84
 mAtXjIrxpynBMHI3oVI4d/Q339qMBUMoOt1+lt3pVeQ5HbrLZg2026I
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Teguh Sobirin <teguh@sobir.in>

Document the Qualcomm QCS8550 based Ayaneo Pocket DS gaming console.

Co-developed-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
Signed-off-by: Teguh Sobirin <teguh@sobir.in>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 2741c07e9f41..f130a6b092b9 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1107,6 +1107,12 @@ properties:
           - const: qcom,qcs8550
           - const: qcom,sm8550
 
+      - items:
+          - enum:
+              - ayaneo,pocketds
+          - const: qcom,qcs8550
+          - const: qcom,sm8550
+
       - items:
           - enum:
               - ayaneo,pocket-s2

-- 
2.54.0

