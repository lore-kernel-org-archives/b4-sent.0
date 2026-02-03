From: Carl Lee <carl.lee@amd.com>
Date: Tue, 03 Feb 2026 16:15:18 +0800
Subject: [PATCH] dt-bindings: hwmon: pmbus: mpq8785: add MPQ8786 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260203-dt-bindings-hwmon-pmbus-mpq8785-add-mpq8786-support-v1-1-67b041e2f762@amd.com>
X-B4-Tracking: v=1; b=H4sIAJWugWkC/y2Nyw6CMBAAf4Xs2U3aWrH6K8YD2AX20IddEBLCv
 9sYbzOXmR2ECpPAvdmh0IeFU6yiTw28pi6OhOyrg1GmVUad0c/Yc/QcR8FpDSliDv0iGPLbXd0
 FO+//3KIsOacy42CdsjdyVmuCWs6FBt5+18fzOL5zrGO9hQAAAA==
X-Change-ID: 20260203-dt-bindings-hwmon-pmbus-mpq8785-add-mpq8786-support-f48049e8411e
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Charles Hsu <ythsu0511@gmail.com>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, carl.lee@amd.com, peter.shen@amd.com, 
 colin.huang2@amd.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770106533; l=1150;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=m6rFz0ihAnzLuhISl1ijaSTJgrFoG6AoFOau5DfN0xY=;
 b=Q3T/THY9jMnJWZZUerK7LkVKjNZo9m6jjU16kd36W/fczr5Ft9LpqayK80e9Q0SCemSwp+8v7
 Nl/ODBKfYT8C6gYlXr6xmhbXjowUpfgPA+Y3gwI+mP8Ayy00GaidKSz
X-Developer-Key: i=carl.lee@amd.com; a=ed25519;
 pk=pyq7QaQvoxMg806KVkRwpCbiah+7ncWr4MBpK1AEyjA=
X-Endpoint-Received: by B4 Relay for carl.lee@amd.com/20260203 with auth_id=623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device type support for MPQ8786

Signed-off-by: Carl Lee <carl.lee@amd.com>
---
 Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml b/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml
index 90970a0433e9..aec7397a29f9 100644
--- a/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml
+++ b/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml
@@ -19,6 +19,7 @@ properties:
       - mps,mpm3695-25
       - mps,mpm82504
       - mps,mpq8785
+      - mps,mpq8786
 
   reg:
     maxItems: 1
@@ -52,7 +53,9 @@ allOf:
   - if:
       properties:
         compatible:
-          const: mps,mpq8785
+          enum:
+            - mps,mpq8785
+            - mps,mpq8786
     then:
       properties:
         mps,vout-fb-divider-ratio-permille:

---
base-commit: 4c87cdd0328495759f6e9f9f4e1e53ef8032a76f
change-id: 20260203-dt-bindings-hwmon-pmbus-mpq8785-add-mpq8786-support-f48049e8411e

Best regards,
-- 
Carl Lee <carl.lee@amd.com>

