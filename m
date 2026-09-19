From: Nicolo Giuliani <nicolo.giuliani6@studio.unibo.it>
Date: Sat, 19 Sep 2026 21:44:18 +0200
Subject: [PATCH 2/3] dt-bindings: arm: marvell: Add Sophos XGS 107w NPU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-send-dt-v1-2-365615a74ef3@studio.unibo.it>
References: <20260919-send-dt-v1-0-365615a74ef3@studio.unibo.it>
In-Reply-To: <20260919-send-dt-v1-0-365615a74ef3@studio.unibo.it>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew@lunn.ch>, 
 Gregory Clement <gregory.clement@bootlin.com>, 
 Sebastian Hesselbarth <sebastian.hesselbarth@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Nicolo Giuliani <nicolo.giuliani6@studio.unibo.it>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789847056; l=1405;
 i=nicolo.giuliani6@studio.unibo.it; s=20260919; h=from:subject:message-id;
 bh=y6YYIBXvEGJH8GoEFsgQ5cuo4swCennTIRdUH242hhU=;
 b=GQWGJk6JAc+bnFpLomU6YmOR4xCP05ObW/ztx++Epil5oUxUZYiCJVhDkAp3xu229+AffPwlP
 5HCFyvyFB+2Cnb+6gTaeNXUoLJlWmfQ7EDjRBkCRgnG5pdhRqI3zIBD
X-Developer-Key: i=nicolo.giuliani6@studio.unibo.it; a=ed25519;
 pk=D652ecdT01GkA1eoFWNFNX85xIg5ZnFwUWyjfestgQw=
X-Endpoint-Received: by B4 Relay for nicolo.giuliani6@studio.unibo.it/20260919 with auth_id=1040
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Sophos XGS 87/107 desktop firewalls combine an AMD x86 host with a
separate network processing unit (NPU). The NPU is a Marvell Armada CN9130
SoC with its own eMMC and SPI NOR flash, connected to the x86 host over
PCIe. It serves the front panel ports through a Marvell 88E6193X switch.

Document the compatible string of the NPU board, with the CN9130 SoC
compatibles as fallbacks.

Assisted-by: LLM
Signed-off-by: Nicolo Giuliani <nicolo.giuliani6@studio.unibo.it>
---
 Documentation/devicetree/bindings/arm/marvell/armada-7k-8k.yaml | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/marvell/armada-7k-8k.yaml b/Documentation/devicetree/bindings/arm/marvell/armada-7k-8k.yaml
index 7e77310da6..2e114139f1 100644
--- a/Documentation/devicetree/bindings/arm/marvell/armada-7k-8k.yaml
+++ b/Documentation/devicetree/bindings/arm/marvell/armada-7k-8k.yaml
@@ -136,4 +136,13 @@ properties:
           - const: solidrun,cn9132-sr-cex7
           - const: marvell,cn9130
 
+      - description:
+          Sophos XGS 87/107 network processing unit (Armada CN9130 SoC
+          with an 88E6193X switch)
+        items:
+          - const: sophos,xgs107w-npu
+          - const: marvell,cn9130
+          - const: marvell,armada-ap807-quad
+          - const: marvell,armada-ap807
+
 additionalProperties: true

-- 
2.48.1

