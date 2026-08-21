From: Markuss Broks <markuss.broks@gmail.com>
Date: Sat, 22 Aug 2026 00:30:13 +0300
Subject: [PATCH 1/5] dt-bindings: input: touchscreen: imagis: add
 compatible for IST4050
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260822-imagis-40xx-v1-1-73e6d6cdf110@gmail.com>
References: <20260822-imagis-40xx-v1-0-73e6d6cdf110@gmail.com>
In-Reply-To: <20260822-imagis-40xx-v1-0-73e6d6cdf110@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Markuss Broks <markuss.broks@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787347843; l=1341;
 i=markuss.broks@gmail.com; s=20260803; h=from:subject:message-id;
 bh=ahOo7S90s3tZfiW1uCTczaPqe2x3GvRSghoncYd1BfU=;
 b=vij2L/ojde48sCdrTdTqRx9Vk5WGLeJURfP5sA9sTzQU9NVGMgvd4KKIYi24vqjcwuXf3bRHr
 ZawcK2b2VMlB9AkTk/VqlAkWfnGQqgDJ9CSz7rRHYf4eUv8RRpac0As
X-Developer-Key: i=markuss.broks@gmail.com; a=ed25519;
 pk=oKzGUTm30BCDqinRMpiHQqByOx1mp2mwmhg80Mv7Zg4=
X-Endpoint-Received: by B4 Relay for markuss.broks@gmail.com/20260803 with auth_id=911
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IST4050 is a touchscreen IC of the Imagis IST40xx family. It shares
the register interface with IST3038C, but uses a different, event-based
touch reporting format and does not have touch keys.

The binding no longer covers only the IST30XXC family, so generalize its
title as well.

Signed-off-by: Markuss Broks <markuss.broks@gmail.com>
---
 .../devicetree/bindings/input/touchscreen/imagis,ist3038c.yaml         | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/imagis,ist3038c.yaml b/Documentation/devicetree/bindings/input/touchscreen/imagis,ist3038c.yaml
index dfaffbc398d3..a4f3e2f0cf45 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/imagis,ist3038c.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/imagis,ist3038c.yaml
@@ -4,7 +4,7 @@
 $id: http://devicetree.org/schemas/input/touchscreen/imagis,ist3038c.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
-title: Imagis IST30XXC family touchscreen controller
+title: Imagis touchscreen controller
 
 maintainers:
   - Markuss Broks <markuss.broks@gmail.com>
@@ -20,6 +20,7 @@ properties:
       - imagis,ist3038b
       - imagis,ist3038c
       - imagis,ist3038h
+      - imagis,ist4050
 
   reg:
     maxItems: 1

-- 
2.55.0

