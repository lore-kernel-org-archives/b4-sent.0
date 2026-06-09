From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Subject: [PATCH net v4 0/4] MAC-PHY interrupt changed to level triggered
 interrupt
Date: Tue, 09 Jun 2026 12:50:23 -0700
Message-Id: <20260609-level-trigger-v4-0-6f389abdd192@onsemi.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH9uKGoC/12NywrDIBREfyXcdS0+0iR01f8oWVhzYy4kWlSkJ
 fjvFZddzgxzzgkRA2GEe3dCwEyRvKuhv3RgNu0sMlpqBsnlwG9KsB0z7iwFshYDm8xL6Enplas
 e6ucdcKVP4z3BYYK5lhvF5MO3ObJqU8MN/B+XFeNs0aPCkYuqkw/vIh50Nf6AuZTyA7OOn7+wA
 AAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781034634; l=2779;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=fEc6RgFqgArsWG6l+smx1XCQosDlspRNYDFL91PwLD0=;
 b=wrNsvzyOigtKx2OTV9speqae9RVqFkm2T1m5PXBBjQ6ub6iumIQb78jQrnNSTDwsxFOrDyWW9
 EV6Xl8JpGg2Atk8rK6xRLfCR0bzXl0RCB5WN9x+A0iJfaJAtDZpBTqD
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

Changes are done in two files
 - OA TC6 framework Ethernet driver
 - YAML file for the vendor that already uses OA TC6 framework.

Maintainer for this driver is already informed and aware of these
changes. Testing for these changes was done in onsemi's setup and
found to be working.

To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>
To: David S. Miller <davem@davemloft.net>
To: Eric Dumazet <edumazet@google.com>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: Piergiorgio Beruto <pier.beruto@onsemi.com>
Cc: Andrew Lunn <andrew@lunn.ch>
Cc: netdev@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: Conor Dooley <conor.dooley@microchip.com>
Cc: devicetree@vger.kernel.org
Cc: Parthiban Veerasooran <Parthiban.Veerasooran@microchip.com>
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

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

---
Selvamani Rajagopal (4):
      net: ethernet: oa_tc6: Interrupt is active low, level triggered.
      net: ethernet: oa_tc6: No return on rx buffer overflow error
      net: ethernet: oa_tc6: mdiobus->parent initialized with NULL
      dt-bindings: net: updated interrupt type to be active low, level triggered

 .../devicetree/bindings/net/microchip,lan8650.yaml |  2 +-
 drivers/net/ethernet/oa_tc6.c                      | 66 +++++++---------------
 2 files changed, 21 insertions(+), 47 deletions(-)
---
base-commit: 0aa05daef7848a5ac11158949dc73cd741995dc1
change-id: 20260531-level-trigger-8cb1a83af034

Best regards,
-- 
Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

