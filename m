From: Vincent Jardin <vjardin@free.fr>
Date: Thu, 30 Jul 2026 19:35:35 +0200
Subject: [PATCH v2 1/2] dt-bindings: dpll: zl3073x: ZL30643 is compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-for-upstream-zl30643-v2-1-0ea0bbd03755@free.fr>
References: <20260730-for-upstream-zl30643-v2-0-0ea0bbd03755@free.fr>
In-Reply-To: <20260730-for-upstream-zl30643-v2-0-0ea0bbd03755@free.fr>
To: Ivan Vecera <ivecera@redhat.com>, 
 Prathosh Satish <Prathosh.Satish@microchip.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Vadim Fedorenko <vadim.fedorenko@linux.dev>, 
 Arkadiusz Kubalewski <arkadiusz.kubalewski@intel.com>, 
 Jiri Pirko <jiri@resnulli.us>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785432952; l=1773;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=hxP/Qko0hV2ofmO+jMLSUDHekBmOPqUro1uZGRZYS10=;
 b=cSXPD8AtHdb07rV/UrvxgRHHUHmhna8lo8Fxj+WoyhYSh0ALue5YJCWRAwAko26/llCjzej6G
 29/SCzGVPxFDP3J/QWjfERr23+gTvb6GlqWK5D5MD9bIKrwPSUQUhUf
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Microchip ZL30643 (chip ID 0x0E3B) is a member of the ZL3064x
line card timing family. It is register compatible with the 3-channel
ZL30733 (chip ID 0x0E95) of the ZL3073x family: both datasheets
describe the same register map and use the same chip-ID encoding.

Describe it with a fallback to microchip,zl30733 rather than a new
standalone compatible.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 .../devicetree/bindings/dpll/microchip,zl30731.yaml   | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)

diff --git a/Documentation/devicetree/bindings/dpll/microchip,zl30731.yaml b/Documentation/devicetree/bindings/dpll/microchip,zl30731.yaml
index fa5a8f8e390c..17983e6c3597 100644
--- a/Documentation/devicetree/bindings/dpll/microchip,zl30731.yaml
+++ b/Documentation/devicetree/bindings/dpll/microchip,zl30731.yaml
@@ -14,15 +14,22 @@ description:
   provides up to 5 independent DPLL channels, up to 10 differential or
   single-ended inputs and 10 differential or 20 single-ended outputs.
   These devices support both I2C and SPI interfaces.
+  The ZL3064x line card timing ICs  share the ZL3073x register map
+  and are described with a fallback to the register equivalent ZL3073x
+  part.
 
 properties:
   compatible:
-    enum:
-      - microchip,zl30731
-      - microchip,zl30732
-      - microchip,zl30733
-      - microchip,zl30734
-      - microchip,zl30735
+    oneOf:
+      - enum:
+          - microchip,zl30731
+          - microchip,zl30732
+          - microchip,zl30733
+          - microchip,zl30734
+          - microchip,zl30735
+      - items:
+          - const: microchip,zl30643
+          - const: microchip,zl30733
 
   reg:
     maxItems: 1

-- 
2.43.0

