From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Subject: [PATCH net v3 0/2] Resubmitting with cover-letter and threaded
 patch series.
Date: Mon, 01 Jun 2026 09:07:17 -0700
Message-Id: <20260601-level-trigger-v3-0-da73e7010532@onsemi.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADWuHWoC/x3MQQqAIBBG4avErBMsK6SrRAurPxsQizEiiO6et
 PwW7z2UIIxEffGQ4OLEe8wwZUHz5qKH4iWbal13ujWVCrgQ1CnsPUTZeaqcNW7VpqHcHIKV7/8
 3UMRJ4/t+M1JklWQAAAA=
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Andrew Lunn <andrew@lunn.ch>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>, 
 devicetree@vger.kernel.org, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780330051; l=1287;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=kw2fWl3/kggl+8QoaAiMjksNRBNP+AfA83rL8vln0fk=;
 b=SS/YfqGoPg9wOTPHlmfv/m8D1xooz6roiF1ub99TrzArgzjzL5VxnIisRzP3B7LTiInntQGS4
 2NyLmUlB7iaA3sLOMe7S8Ly4Y0yK93snp81QnuKCJZxIk1bnHf2Ot5i
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

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
---
Selvamani Rajagopal (2):
      net: ethernet: oa_tc6: Interrupt is active low, level triggered.
      dt-bindings: net: updated interrupt type to be active low, level triggered

 Documentation/devicetree/bindings/net/microchip,lan8650.yaml | 2 +-
 drivers/net/ethernet/oa_tc6.c                                | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
---
base-commit: 02896a7fa4cd3ec61d60ba30136841e4f04bdeac
change-id: 20260531-level-trigger-8cb1a83af034

Best regards,
-- 
Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

