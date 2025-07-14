From: Rohan G Thomas <rohan.g.thomas@altera.com>
Subject: [PATCH net-next 0/3] net: stmmac: xgmac: Minor fixes
Date: Mon, 14 Jul 2025 15:59:16 +0800
Message-Id: <20250714-xgmac-minor-fixes-v1-0-c34092a88a72@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANS4dGgC/x3LQQqDMBBG4auEWTuQDBZLr1K6CPHXzsKxJCIBy
 d0NXX483kUFWVHo5S7KOLXobh1hcJS+0Vawzt0kXh5+CiPXdYuJN7U986IVhUcvz2kRCXMC9e+
 X8Q99e5PhYEM96NPaDauDp35tAAAA
X-Change-ID: 20250714-xgmac-minor-fixes-40287f221dce
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Serge Semin <fancer.lancer@gmail.com>, 
 Romain Gantois <romain.gantois@bootlin.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752480026; l=990;
 i=rohan.g.thomas@altera.com; s=20250415; h=from:subject:message-id;
 bh=x7tBS5TJxVqQ22cB02A2Vi0xzr6SLrJTnF6VPCHBuUc=;
 b=eOyvh3AjlRrzHzO8kmZyoZOWk31VG+/F2coZiafOWwdLSJAK9xzmHqHbMMCpIaCjoQYXDcbwX
 o0FxciB5jAlCR/+aFZH/hv6+9wY3JRJfY2tV2ejIrqE2psmZwydwODO
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=TLFM1xzY5sPOABaIaXHDNxCAiDwRegVWoy1tP842z5E=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250415 with auth_id=460
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series includes following minor fixes for stmmac
dwxgmac driver:

    1. Disable Rx FIFO overflow interrupt for dwxgmac
    2. Correct supported speed modes for dwxgmac
    3. Check for coe-unsupported flag before setting CIC bit of
       Tx Desc3 in the AF_XDP flow

Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
---
Rohan G Thomas (3):
      net: stmmac: xgmac: Disable RX FIFO Overflow interrupts
      net: stmmac: xgmac: Correct supported speed modes
      net: stmmac: Set CIC bit only for TX queues with COE

 drivers/net/ethernet/stmicro/stmmac/dwxgmac2_core.c | 14 ++++++++++++--
 drivers/net/ethernet/stmicro/stmmac/dwxgmac2_dma.c  |  5 +----
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c   |  6 ++++--
 3 files changed, 17 insertions(+), 8 deletions(-)
---
base-commit: b06c4311711c57c5e558bd29824b08f0a6e2a155
change-id: 20250714-xgmac-minor-fixes-40287f221dce

Best regards,
-- 
Rohan G Thomas <rohan.g.thomas@altera.com>

