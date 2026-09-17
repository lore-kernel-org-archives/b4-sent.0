From: Andy Chung <Andy.Chung@amd.com>
Date: Thu, 17 Sep 2026 17:49:21 +0800
Subject: [PATCH linux dev-6.18 v2 1/4] dt-bindings: Add vendor prefix for
 Kandou
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260917-kb9002-backport-v2-1-71d46021f051@amd.com>
References: <20260917-kb9002-backport-v2-0-71d46021f051@amd.com>
In-Reply-To: <20260917-kb9002-backport-v2-0-71d46021f051@amd.com>
To: openbmc@lists.ozlabs.org, andrew@codeconstruct.com.au, 
 tan.siewert@9elements.com
Cc: joel@jms.id.au
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789638570; l=1073;
 i=Andy.Chung@amd.com; s=20260327; h=from:subject:message-id;
 bh=qUQrv9Vi48+dBm8YOvp+wO0b7eEAtNZSoMhDKTzaVWQ=;
 b=G3DYEULriRNF63QKB+Zrp1vUKPCXBfzmNCYSQ03cPKK3gehH81yh1QpAMvz3zcCpiSR2I2o5j
 sBodIz1fgtRDw1Jq8gMUdLasyLZtX2k20WJNkj0PyHR2L8YlwgEhkGQ
X-Developer-Key: i=Andy.Chung@amd.com; a=ed25519;
 pk=X2gaHRnhU2q5hvMjkC6xmIcC03vKNvHY9CQRdsj9ecM=
X-Endpoint-Received: by B4 Relay for Andy.Chung@amd.com/20260327 with auth_id=696
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Kandou AI is the vendor of the KB9002 PCIe retimer.

Signed-off-by: Andy Chung <Andy.Chung@amd.com>
Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Link: https://lore.kernel.org/r/20260724-kb9002-upstream-v5-1-9523c3ffe83a@amd.com
Signed-off-by: Guenter Roeck <linux@roeck-us.net>
(cherry picked from commit 1d687d863c43ca60564136b34cbf4632f89b8aeb)
Signed-off-by: Andy Chung <Andy.Chung@amd.com>
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

