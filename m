From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Thu, 20 Feb 2025 09:22:10 +0100
Subject: [PATCH v2 1/2] dt-bindings: can: fsl,flexcan: add transceiver
 capabilities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250220-flexcan-add-transceiver-caps-v2-1-a81970f11846@liebherr.com>
References: <20250220-flexcan-add-transceiver-caps-v2-0-a81970f11846@liebherr.com>
In-Reply-To: <20250220-flexcan-add-transceiver-caps-v2-0-a81970f11846@liebherr.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740039736; l=981;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=rYXmxFzExtgpILQ/SNCUYYIlRALmdQAqdKj3Yq2bYU8=;
 b=bMg+Z7zb4hahUp3welT22AvMxrxFl9jVH0LXHi4p6pT5A4Nwi1nCQfrGenyaQQclBomRQPeAS
 rh6On+1+bGfB8QErThTvlrNALaIY0NnwRN1TtmU+YmqBUlQjyZlsRKI
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the flexcan driver does only support adding PHYs by using the
"old" regulator bindings. Add support for CAN transceivers as a PHY.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 Documentation/devicetree/bindings/net/can/fsl,flexcan.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/can/fsl,flexcan.yaml b/Documentation/devicetree/bindings/net/can/fsl,flexcan.yaml
index 73252fe56fe6c8e9fd19142208bb655dc86d47cd..a7b9ae2b2546b801623117179e16c4ffc11a234e 100644
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

-- 
2.39.5

