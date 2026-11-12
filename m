From: Asdlerto Korry <korryasdlerto@gmail.com>
Date: Thu, 12 Nov 2026 19:25:49 +0200
Subject: [PATCH net-next v3 1/2] dt-bindings: net: nfc: samsung,s3fwrn5:
 Add pvdd-supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-m52xq-nfc-netdev-v3-1-725a61ce4148@gmail.com>
References: <20261112-m52xq-nfc-netdev-v3-0-725a61ce4148@gmail.com>
In-Reply-To: <20261112-m52xq-nfc-netdev-v3-0-725a61ce4148@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>
Cc: oe-linux-nfc@lists.linux.dev, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Asdlerto Korry <korryasdlerto@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794504348; l=1338;
 i=korryasdlerto@gmail.com; s=20261104; h=from:subject:message-id;
 bh=zH+1as4NCY/dZ65WKSxZl8APKd4N3zG6ELlk34X29Gg=;
 b=vIZTPZ2ceGklPiI/sE2YKq81kKdtCavLG2dRIE+zRC+k6/VMD1hy28l0ND78DrMd0+ePmBBnQ
 1Fs/NGyuOoUC+cHZ0A6YSKgP76v3a0N+2S8psgM+HR99nZo3fAVOukw
X-Developer-Key: i=korryasdlerto@gmail.com; a=ed25519;
 pk=RqttIGkm2XZ8NhLQBzPgpXXawOdVa1uODGsk+sagbxs=
X-Endpoint-Received: by B4 Relay for korryasdlerto@gmail.com/20261104 with auth_id=1411
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PVDD pin of the S3FWRN5 has to be powered before the chip is
enabled. On some boards, like the Samsung Galaxy M52 5G, this supply
is switched by a SoC GPIO. Document it, so that the regulator can be
handed to the driver instead of being kept always on.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Asdlerto Korry <korryasdlerto@gmail.com>
---
 Documentation/devicetree/bindings/net/nfc/samsung,s3fwrn5.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/nfc/samsung,s3fwrn5.yaml b/Documentation/devicetree/bindings/net/nfc/samsung,s3fwrn5.yaml
index 12baee45752c..3c5a579a7108 100644
--- a/Documentation/devicetree/bindings/net/nfc/samsung,s3fwrn5.yaml
+++ b/Documentation/devicetree/bindings/net/nfc/samsung,s3fwrn5.yaml
@@ -34,6 +34,10 @@ properties:
     description:
       Output GPIO pin used to enter firmware mode and sleep/wakeup control
 
+  pvdd-supply:
+    description:
+      Power supply of the PVDD pin
+
   s3fwrn5,en-gpios:
     maxItems: 1
     deprecated: true
@@ -84,6 +88,7 @@ examples:
             wake-gpios = <&gpj0 2 GPIO_ACTIVE_HIGH>;
 
             clocks = <&rpmcc 20>;
+            pvdd-supply = <&nfc_pvdd>;
         };
     };
   # UART example on Raspberry Pi

-- 
2.25.1

