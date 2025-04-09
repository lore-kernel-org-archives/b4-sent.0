From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 09 Apr 2025 17:57:22 -0500
Subject: [PATCH v3 1/4] media: dt-bindings: Document Tegra186 and Tegra194
 cec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250409-tegra-cec-v3-1-91640131dfa2@gmail.com>
References: <20250409-tegra-cec-v3-0-91640131dfa2@gmail.com>
In-Reply-To: <20250409-tegra-cec-v3-0-91640131dfa2@gmail.com>
To: Hans Verkuil <hverkuil@xs4all.nl>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744239446; l=1294;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=OKxF0kfZG4y0m8GxH7XJEPDEjS3nCDGshb6+1TkJSyA=;
 b=3Aq4MzVSdrZgI2CPGWCtMlp1Ksyfq5iPuzURj732chI+PPU/YpKFFSPq0frjZGKnNqs3nocfa
 m8hCRLQ1e+EBcHCi8lhVWD4xENPYiAJcspTq/dTIYX561AaTdMA2j8b
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These are already used in device trees, so describe them here. As the
driver only declares up through Tegra210, these must use a fallback
compatible of tegra210-cec.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 .../bindings/media/cec/nvidia,tegra114-cec.yaml           | 15 +++++++++++----
 1 file changed, 11 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml b/Documentation/devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml
index a6b73498bc217a2e884e31af91e9d8845c9b1d76..3637fe2dfbd0dbb1baf265d7c128954df8faf740 100644
--- a/Documentation/devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml
+++ b/Documentation/devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml
@@ -14,10 +14,17 @@ allOf:
 
 properties:
   compatible:
-    enum:
-      - nvidia,tegra114-cec
-      - nvidia,tegra124-cec
-      - nvidia,tegra210-cec
+    oneOf:
+      - items:
+          - enum:
+              - nvidia,tegra114-cec
+              - nvidia,tegra124-cec
+              - nvidia,tegra210-cec
+      - items:
+          - enum:
+              - nvidia,tegra186-cec
+              - nvidia,tegra194-cec
+          - const: nvidia,tegra210-cec
 
   clocks:
     maxItems: 1

-- 
2.48.1

