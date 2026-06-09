From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Tue, 09 Jun 2026 12:50:27 -0700
Subject: [PATCH net v4 4/4] dt-bindings: net: updated interrupt type to be
 active low, level triggered
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260609-level-trigger-v4-4-6f389abdd192@onsemi.com>
References: <20260609-level-trigger-v4-0-6f389abdd192@onsemi.com>
In-Reply-To: <20260609-level-trigger-v4-0-6f389abdd192@onsemi.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Parthiban Veerasooran <Parthiban.Veerasooran@microchip.com>, 
 Andrew Lunn <andrew@lunn.ch>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>, 
 devicetree@vger.kernel.org, Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781034634; l=1207;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=bMsW8U5V7GkXjBltoUBoX9kv1yVBsDFF/rrSFoglK5M=;
 b=N8mr1STIqO4eTYBJILLVX/hqFhKUZCTVDRyE5t0HXhobVyJaj/26YlIwDePI8G3Tf8HHLYeuS
 aGh6Zn3e2KUDXQOYz1t3ypYZD/o5FrWTcS1NYrg1YYvWhd1YUfSqcUH
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to OPEN Alliance 10BASE-T1x MACPHY Serial Interface (TC6)
specification, interrupt type is active low, level triggered interrupt.

Fixes: ac49b950bea9 ("dt-bindings: net: add Microchip's LAN865X 10BASE-T1S MACPHY")
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

changes in v4:
  no change
changes in v3
  interrupts entry changed to level triggered from edge triggered
---
 Documentation/devicetree/bindings/net/microchip,lan8650.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/net/microchip,lan8650.yaml b/Documentation/devicetree/bindings/net/microchip,lan8650.yaml
index 61e11d4a07c4..766ff58147ae 100644
--- a/Documentation/devicetree/bindings/net/microchip,lan8650.yaml
+++ b/Documentation/devicetree/bindings/net/microchip,lan8650.yaml
@@ -67,7 +67,7 @@ examples:
         pinctrl-names = "default";
         pinctrl-0 = <&eth0_pins>;
         interrupt-parent = <&gpio>;
-        interrupts = <6 IRQ_TYPE_EDGE_FALLING>;
+        interrupts = <6 IRQ_TYPE_LEVEL_LOW>;
         local-mac-address = [04 05 06 01 02 03];
         spi-max-frequency = <15000000>;
       };

-- 
2.43.0

