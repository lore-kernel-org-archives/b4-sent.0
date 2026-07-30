From: Andy Chung <Andy.Chung@amd.com>
Date: Thu, 30 Jul 2026 17:07:56 +0800
Subject: [PATCH linux dev-6.18 1/4] dt-bindings: Add vendor prefix for
 Kandou
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-kb9002-backport-v1-1-41f472e52215@amd.com>
References: <20260730-kb9002-backport-v1-0-41f472e52215@amd.com>
In-Reply-To: <20260730-kb9002-backport-v1-0-41f472e52215@amd.com>
To: openbmc@lists.ozlabs.org, joel@jms.id.au, andrew@codeconstruct.com.au
Cc: Andy Chung <Andy.Chung@amd.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785402478; l=955;
 i=Andy.Chung@amd.com; s=20260327; h=from:subject:message-id;
 bh=Vip+y4zyOOeo3fWhSWkyV8pwofoZryEMIXrs0tGBVZg=;
 b=x4Gtydnffs9wctOQ8ycmZzPolmLhKwVH0hvPH04jA1UuM8nSyvMkd6KihqevVToFf04wCwHyQ
 uAzPcybyHwLAs0YWz5EqdllQ44aPeQD7DaDv4FkYrSxM5UtfLHrLOOv
X-Developer-Key: i=Andy.Chung@amd.com; a=ed25519;
 pk=X2gaHRnhU2q5hvMjkC6xmIcC03vKNvHY9CQRdsj9ecM=
X-Endpoint-Received: by B4 Relay for Andy.Chung@amd.com/20260327 with auth_id=696
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Kandou AI is the vendor of the KB9002 PCIe retimer.

Signed-off-by: Andy Chung <Andy.Chung@amd.com>
Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Link: https://lore.kernel.org/r/20260724-kb9002-upstream-v5-1-9523c3ffe83a@amd.com
Signed-off-by: Guenter Roeck <linux@roeck-us.net>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index a9cf85fd6fbe..4e1fa0104f5d 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -839,6 +839,8 @@ patternProperties:
     description: JTY
   "^kam,.*":
     description: Kamstrup A/S
+  "^kandou,.*":
+    description: Kandou AI
   "^karo,.*":
     description: Ka-Ro electronics GmbH
   "^keithkoep,.*":

-- 
2.34.1

