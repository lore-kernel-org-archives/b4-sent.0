From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Thu, 11 Jun 2026 14:55:41 -0700
Subject: [PATCH net v5 4/4] dt-bindings: net: updated interrupt type to be
 active low, level triggered
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260611-level-trigger-v5-4-4533a9e85ce2@onsemi.com>
References: <20260611-level-trigger-v5-0-4533a9e85ce2@onsemi.com>
In-Reply-To: <20260611-level-trigger-v5-0-4533a9e85ce2@onsemi.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>
Cc: Andrew Lunn <andrew@lunn.ch>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>, 
 devicetree@vger.kernel.org, 
 Parthiban Veerasooran <Parthiban.Veerasooran@microchip.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781214947; l=1648;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=5m7Zn2IB4XfdT3/7b+9FZgcVrhjA695d6nE+ghg/fkM=;
 b=DlhK1Ndf40Cd6zkXYQ59FA6gg0g6OXNGMlAKRSka+sCuQWUoP4QnExeAkjHibxRa4TovKMg4w
 ilT57mFnE5oAtFREgF6RrGNjjh2VHAPx3OOXreE8oYAOJ12xuMgHzrx
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to OPEN Alliance 10BASE-T1x MACPHY Serial Interface (TC6)
specification, interrupt type is active low, level triggered interrupt.

Specification calls for when interrupt level will be asserted and what
condition it is de-asserted. By using edge triggered interrupt, there is a
potential chance to miss it, particularly if it is asserted when interrupt
is disabled.

Level triggered interrupt can't be missed as it gets de-asserted only on
interrupt handler taking actions on interrupting conditions.

Fixes: ac49b950bea9 ("dt-bindings: net: add Microchip's LAN865X 10BASE-T1S MACPHY")
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v5
  Added better, descriptive commit message
changes in v4
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

