From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Tue, 11 Feb 2025 14:12:33 +0100
Subject: [PATCH 1/2] dt-bindings: can: fsl,flexcan: add transceiver
 capabilities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250211-flexcan-add-transceiver-caps-v1-1-c6abb7817b0f@liebherr.com>
References: <20250211-flexcan-add-transceiver-caps-v1-0-c6abb7817b0f@liebherr.com>
In-Reply-To: <20250211-flexcan-add-transceiver-caps-v1-0-c6abb7817b0f@liebherr.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739279554; l=952;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=+ZZYio4M7OHFLaxgdm65MWmmCFRzyUpLb+CpAcuf2Co=;
 b=2lUyXGvYMswKVuxLmcLHTeHYnSaLQrqe9UTnCD3nA64B4F+12qVf+RJtFCJ7beJU3/Sjb+mYI
 vOK8s12mH4KCMdG39+YqM8Xkum6WYtyDgyDbaFqv82wgZ+woCwHupEe
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the flexcan driver does not support adding PHYs. Add the
capability to ensure that the PHY is in operational state when the link
is set to an "up" state.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 Documentation/devicetree/bindings/net/can/fsl,flexcan.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/can/fsl,flexcan.yaml b/Documentation/devicetree/bindings/net/can/fsl,flexcan.yaml
index 97dd1a7c5ed26bb7f1b2f78c326d91e2c299938a..397957569588a61111a313cf9107e29dacc9e667 100644
--- a/Documentation/devicetree/bindings/net/can/fsl,flexcan.yaml
+++ b/Documentation/devicetree/bindings/net/can/fsl,flexcan.yaml
@@ -70,6 +70,9 @@ properties:
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

