From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 08 Apr 2026 14:41:24 -0500
Subject: [PATCH v5 1/6] dt-bindings: vendor-prefixes: Add AYN Technologies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-ayn-qcs8550-v5-1-c90abeb7a152@gmail.com>
References: <20260408-ayn-qcs8550-v5-0-c90abeb7a152@gmail.com>
In-Reply-To: <20260408-ayn-qcs8550-v5-0-c90abeb7a152@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Xilin Wu <wuxilin123@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775677286; l=950;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=gOQhZByrG6tU19fKVlrU7N5RaAgEuR2DnSgZYTk4CCU=;
 b=qHLmbO+XOrMatwGjCrYbwNDhjZtq9AqhQtw4lLAEgY6nT+wuROFu3WyWlFG/61cbnQD/u+mWA
 0DrMcSSWHsQCPvVJTpHvrjCKJB4x3Oqn6h1JLgik+z5UF6GARXC9t0+
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Xilin Wu <wuxilin123@gmail.com>

Add an entry for AYN Technologies (https://www.ayntec.com/)

Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 28784d66ae7ba5..b891d6d41f198a 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -225,6 +225,8 @@ patternProperties:
     description: Axis Communications AB
   "^ayaneo,.*":
     description: Anyun Intelligent Technology (Hong Kong) Co., Ltd
+  "^ayntec,.*":
+    description: AYN Technologies Co., Ltd.
   "^azoteq,.*":
     description: Azoteq (Pty) Ltd
   "^azw,.*":

-- 
2.53.0

