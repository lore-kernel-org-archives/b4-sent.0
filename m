From: Nicolo Giuliani <nicolo.giuliani6@studio.unibo.it>
Date: Mon, 21 Sep 2026 02:26:42 +0200
Subject: [PATCH v2 2/3] dt-bindings: arm: marvell: Add Sophos XGS 107w NPU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-send-dt-v2-2-fb6b81002ad7@studio.unibo.it>
References: <20260921-send-dt-v2-0-fb6b81002ad7@studio.unibo.it>
In-Reply-To: <20260921-send-dt-v2-0-fb6b81002ad7@studio.unibo.it>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew@lunn.ch>, 
 Gregory Clement <gregory.clement@bootlin.com>, 
 Sebastian Hesselbarth <sebastian.hesselbarth@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Nicolo Giuliani <nicolo.giuliani6@studio.unibo.it>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789950401; l=1394;
 i=nicolo.giuliani6@studio.unibo.it; s=20260919; h=from:subject:message-id;
 bh=lyDMMre6EWQH7CiEprIS9UxuPjln7GFy4OUwneOalSI=;
 b=XH+pUXfYOL6RW3KhZLUS9vw02g1QOZ+Wz32F90LYLT2qMP4KyByADqVmYEIGFa+Qe97WHG1ga
 XawU60uusXPAG7FuzKQHL2L5NiNGzRHI9893tueFqx6qbKkK7RiRPSd
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
 Documentation/devicetree/bindings/arm/marvell/armada-7k-8k.yaml | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/marvell/armada-7k-8k.yaml b/Documentation/devicetree/bindings/arm/marvell/armada-7k-8k.yaml
index 7e77310da6..130128c462 100644
--- a/Documentation/devicetree/bindings/arm/marvell/armada-7k-8k.yaml
+++ b/Documentation/devicetree/bindings/arm/marvell/armada-7k-8k.yaml
@@ -118,6 +118,13 @@ properties:
           - const: marvell,armada-ap807-quad
           - const: marvell,armada-ap807
 
+      - description:
+          Sophos XGS 87/107 network processing unit (Armada CN9130 SoC
+          with an 88E6193X switch)
+        items:
+          - const: sophos,xgs107w-npu
+          - const: marvell,cn9130
+
       - description:
           SolidRun CN9130 SoM based single-board computers
         items:

-- 
2.48.1

