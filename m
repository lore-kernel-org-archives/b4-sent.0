From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Subject: [PATCH net v5 0/4] MAC-PHY interrupt changed to level triggered
 interrupt
Date: Thu, 11 Jun 2026 14:55:37 -0700
Message-Id: <20260611-level-trigger-v5-0-4533a9e85ce2@onsemi.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANouK2oC/12NywqDMBREf0Xuuil5+Oyq/1G6iOaqFzQpiYQW8
 d8bsmpdzgznzA4BPWGAW7GDx0iBnE2huhQwzNpOyMikDJLLmldKsAUjLmzzNE3oWTv0QrdKj1y
 VkJiXx5He2fcAixs8UzlT2Jz/5I+o8pR1NT/romKcGd0obLhId/LubMCVroNbsyqWv3h3xsuE1
 6NqO90bI7p//DiOLwZj3WLvAAAA
X-Change-ID: 20260531-level-trigger-8cb1a83af034
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781214947; l=2947;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=G8O/fgkg40yzWQsZV7+qSg2DX9SUdeFeRtf+xvaV66c=;
 b=Q7Ins9Yrrl0dk8bb2U2sSVW/lnT974k5lqVNm7Gn8eZR3FMWqKX/E4xuR37i5FbXrecRpOjzT
 K6VyCS9kQOEDM+fBFTje55mc0+k3LiF1fY4xnZ4vLq3z+V1LREywOWH
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to OPEN Alliance 10BASE-T1x MAC-PHY Serial Interface
specification, MAC-PHY interrupt is "active low, level triggered".
The specification mentions about the conditions in which the IRQ
is asserted and deasserted.

Bug is inadvertently introduced by treating the IRQ in the OA TC6
framework driver and in dt-binding YAML file as edge triggered.

With the changes to use level triggered interrupt, use of threaded
irq is more efficient than the current method that has interrupt hander
working with work queue.

This change of interrupt handler mechanism exposed couple of race
conditions due to the fact that interrupts were not masked on protocol
error. And pointers were not initialized with null after skbs are freed.

Changes are done in two files
 - OA TC6 framework Ethernet driver
 - YAML file for the vendor that already uses OA TC6 framework.

Maintainer for this driver is already informed and aware of these
changes. Testing for these changes was done in onsemi's setup and
found to be working.

Changes in v5:
  - Removed the extraneous FCS that came with the frame before passing
    to the stack
  - Base commit was upadted on few patches to ensure that it is pointing
    to the correct commit ID.
  - Commit messages have been updated to be more descriptive and
    gives more detail now.
  - Couple of race conditions pointed out by AI review is fixed.

- Link to v4: https://lore.kernel.org/r/20260609-level-trigger-v4-0-6f389abdd192@onsemi.com

Changes in v4:

- IRQ handler is changed to interrupt handler + wake up thread
  to interrupt handler + threaded irq. Threaded irq mechanism
  is better suited for level triggered interrupt. Because it can
  keep the interrupt disabled until interrupting conditions are 
  handled by a handler thread.
- SPI data handling function is called again on EAGAIN error code
  as it indicates RX buffer overflow error, which requires draining
  the bad data chunks.
 
  - Changed wakeup thread to threaded IRQ 
  - RX buffer overflow is handled before threaded irq returns

- Link to v3: https://lore.kernel.org/r/20260601-level-trigger-v3-0-da73e7010532@onsemi.com

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
---
Selvamani Rajagopal (4):
      net: ethernet: oa_tc6: Interrupt is active low, level triggered.
      net: ethernet: oa_tc6: mdiobus->parent initialized with NULL
      net: ethernet: oa_tc6: Remove FCS size in RX frame
      dt-bindings: net: updated interrupt type to be active low, level triggered

 .../devicetree/bindings/net/microchip,lan8650.yaml |   2 +-
 drivers/net/ethernet/oa_tc6.c                      | 140 +++++++++++++--------
 2 files changed, 89 insertions(+), 53 deletions(-)
---
base-commit: 22e2036479cb77df6281ebbd376ae6c330774790
change-id: 20260531-level-trigger-8cb1a83af034

Best regards,
--  
Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

