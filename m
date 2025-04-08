From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 08 Apr 2025 15:29:58 -0500
Subject: [PATCH v2 1/4] media: dt-bindings: Document Tegra186 and Tegra194
 cec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250408-tegra-cec-v2-1-2f004fdf84e8@gmail.com>
References: <20250408-tegra-cec-v2-0-2f004fdf84e8@gmail.com>
In-Reply-To: <20250408-tegra-cec-v2-0-2f004fdf84e8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744144221; l=1268;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=SBYzrweVVHLN9la+8OOVglqXjFrZuIt0vhyqD1iWVzg=;
 b=c/Vwe4H1CX5ETUdsgR85HAxn13r302DIxxMZB8i6lEvx6Us0UXfEeqEXDKvJg+EQxc6dsxPN0
 AOwS25krisOAEiJ9xrZedblBCP6j4yEnQVdweo4DHva7rRea6m8qyjG
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
index a6b73498bc217a2e884e31af91e9d8845c9b1d76..20d8eb975c2bf67acd407a4683a698b2bfb7c5f8 100644
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
+        - enum:
+          - nvidia,tegra114-cec
+          - nvidia,tegra124-cec
+          - nvidia,tegra210-cec
+      - items:
+        - enum:
+          - nvidia,tegra186-cec
+          - nvidia,tegra194-cec
+        - const: nvidia,tegra210-cec
 
   clocks:
     maxItems: 1

-- 
2.48.1

