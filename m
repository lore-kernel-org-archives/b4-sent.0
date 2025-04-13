From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 13 Apr 2025 14:35:32 -0500
Subject: [PATCH v4 1/4] media: dt-bindings: Document Tegra186 and Tegra194
 cec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250413-tegra-cec-v4-1-b6337b66ccad@gmail.com>
References: <20250413-tegra-cec-v4-0-b6337b66ccad@gmail.com>
In-Reply-To: <20250413-tegra-cec-v4-0-b6337b66ccad@gmail.com>
To: Hans Verkuil <hverkuil@xs4all.nl>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744572933; l=1325;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=YVLzTrqjDbAvBpxX5/oSBtHgNAH8jFfg0U2e5NvPa4o=;
 b=CbsDPDI+SmLCLbWp8Gq2YDwlS4c7C2ntk92cjYP6qni2kavzT5i3g5d3zgCc85y/oPhov4rwY
 Q7WdL8YoEYLBspsxK44Z9teyjE8qEoKGU02+DVejuaXBoFZ9z5ItoR0
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These are already used in device trees, so describe them here. As the
driver only declares up through Tegra210, these must use a fallback
compatible of tegra210-cec.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 .../devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml | 14 ++++++++++----
 1 file changed, 10 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml b/Documentation/devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml
index a6b73498bc217a2e884e31af91e9d8845c9b1d76..4b46aa755ccd31d0ca8b2004a1d6345c27ed330d 100644
--- a/Documentation/devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml
+++ b/Documentation/devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml
@@ -14,10 +14,16 @@ allOf:
 
 properties:
   compatible:
-    enum:
-      - nvidia,tegra114-cec
-      - nvidia,tegra124-cec
-      - nvidia,tegra210-cec
+    oneOf:
+      - enum:
+          - nvidia,tegra114-cec
+          - nvidia,tegra124-cec
+          - nvidia,tegra210-cec
+      - items:
+          - enum:
+              - nvidia,tegra186-cec
+              - nvidia,tegra194-cec
+          - const: nvidia,tegra210-cec
 
   clocks:
     maxItems: 1

-- 
2.48.1

