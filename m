From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Sat, 22 Feb 2025 08:43:13 +0100
Subject: [PATCH v4 1/2] dt-bindings: can: fsl,flexcan: add transceiver
 capabilities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250222-flexcan-add-transceiver-caps-v4-1-a38dfadab763@liebherr.com>
References: <20250222-flexcan-add-transceiver-caps-v4-0-a38dfadab763@liebherr.com>
In-Reply-To: <20250222-flexcan-add-transceiver-caps-v4-0-a38dfadab763@liebherr.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740210200; l=1240;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=62w1D1rpX0pQNS5ptfX/YuY6csaGTzAr13ql41pZT30=;
 b=3WQsjjRLq1qmsSqQn1ymItbHsijT3UMwRseDCr6TGzSEUFdPeWyKO6S12bXBstobD6S13ZK0m
 0NG98sr2XVkDVPC4Ym6Ee5RbUjNyKAGJ+7TjsC4lmMLlwBo/35FX0LF
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the flexcan driver does only support adding PHYs by using the
"old" regulator bindings. Add support for CAN transceivers as a PHY.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 Documentation/devicetree/bindings/net/can/fsl,flexcan.yaml | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/can/fsl,flexcan.yaml b/Documentation/devicetree/bindings/net/can/fsl,flexcan.yaml
index 73252fe56fe6c8e9fd19142208bb655dc86d47cd..37e3e4f487629f4df427dd8f711dc632f8dc5a2a 100644
--- a/Documentation/devicetree/bindings/net/can/fsl,flexcan.yaml
+++ b/Documentation/devicetree/bindings/net/can/fsl,flexcan.yaml
@@ -77,6 +77,9 @@ properties:
   xceiver-supply:
     description: Regulator that powers the CAN transceiver.
 
+  phys:
+    maxItems: 1
+
   big-endian:
     $ref: /schemas/types.yaml#/definitions/flag
     description: |
@@ -171,6 +174,12 @@ allOf:
         interrupts:
           maxItems: 1
         interrupt-names: false
+  - if:
+      required:
+        - xceiver-supply
+    then:
+      properties:
+        phys: false
 
 additionalProperties: false
 

-- 
2.39.5

