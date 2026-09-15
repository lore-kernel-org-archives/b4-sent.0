From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 15 Sep 2026 22:20:23 +0200
Subject: [PATCH 1/3] dt-bindings: vendor-prefixes: add Vision Components
 GmbH
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-vc-mipi-ctrl-v1-1-8a42b693d889@linux.dev>
References: <20260915-vc-mipi-ctrl-v1-0-8a42b693d889@linux.dev>
In-Reply-To: <20260915-vc-mipi-ctrl-v1-0-8a42b693d889@linux.dev>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: Alexander Stein <alexander.stein@ew.tq-group.com>, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789503653; l=978;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=cy6NnsJcH0jNfhQsnNyLRIM3THjaYMss2IiZOPpYDUs=;
 b=Nq5t2AjUH7qMg4geKgmTyocO81gMyO8ukMpX6uhC4wfyNVte5YYuI52grFHXffNPo9ioy5wl3
 3XzREEVAISPD85LMzhwNKeJ658UQKGpkaewdQ5btcosPN8fWenA9xPU
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add vendor prefix for Vision Components GmbH, a manufacturer of camera
modules. The prefix will be used in the Vision Components MIPI Camera
Controller driver.

Link: https://www.vision-components.com
Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index ba20029693734..b853fb9338527 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1845,6 +1845,8 @@ patternProperties:
     description: Vishay Intertechnology, Inc
   "^visionox,.*":
     description: Visionox
+  "^vision-components,.*":
+    description: Vision Components GmbH
   "^vitesse,.*":
     description: Vitesse Semiconductor Corporation
   "^vivante,.*":

-- 
2.53.0

