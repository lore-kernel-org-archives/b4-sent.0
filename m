From: Rohan G Thomas <rohan.g.thomas@altera.com>
Subject: [PATCH net v3 0/3] net: stmmac: xgmac: Minor fixes
Date: Mon, 25 Aug 2025 12:36:51 +0800
Message-Id: <20250825-xgmac-minor-fixes-v3-0-c225fe4444c0@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGPoq2gC/33NTQrDIBAF4KuEWdeikz/TVe9RuhAzJkKjRYOkh
 Ny94qYUSpdvHu+bHSIFSxEu1Q6Bko3WuxzqUwV6Vm4iZsecATm2vBcN26ZFabZY5wMzdqPIGo6
 yN4hi1AR59wxUijy7gaMV7vk427j68Cp/kijVHzIJxpmuGz6gklL1eFWPlYI6a78ULuGHkKL7R
 WAmumFoW9QmE+aLOI7jDdEnumv7AAAA
X-Change-ID: 20250714-xgmac-minor-fixes-40287f221dce
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Jose Abreu <Jose.Abreu@synopsys.com>, 
 Romain Gantois <romain.gantois@bootlin.com>, 
 Serge Semin <fancer.lancer@gmail.com>, 
 Ong Boon Leong <boon.leong.ong@intel.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>, Andrew Lunn <andrew@lunn.ch>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756096627; l=1399;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=qbmrznk8y3bTUpjqPLSvWYU8OwN7QufMMM55Yj86Gkw=;
 b=wb6durDNB7EBHq2OkiLCdW7vqZM17yyaQFwyVzxklzowPsTG1zA8RPFzfe0pjDOg89l4lAE/C
 O0US6x4B5ujDW1ogpumfCPQOh67cwwuBN4pPnWn+WnqvUqBeK5LdVC5
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series includes following minor fixes for stmmac
dwxgmac driver:

    1. Disable Rx FIFO overflow interrupt for dwxgmac
    2. Correct supported speed modes for dwxgmac
    3. Check for coe-unsupported flag before setting CIC bit of
       Tx Desc3 in the AF_XDP flow

Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
---
Changes in v3:
- Keep variable declaration smallest to largest.
- Link to v2: https://lore.kernel.org/r/20250816-xgmac-minor-fixes-v2-0-699552cf8a7f@altera.com

Changes in v2:
- Added Fixes: tags to relevant commits.
- Added a check for synopsys version to enable 10Mbps, 100Mbps support.
- Link to v1: https://lore.kernel.org/r/20250714-xgmac-minor-fixes-v1-0-c34092a88a72@altera.com

---
Rohan G Thomas (3):
      net: stmmac: xgmac: Do not enable RX FIFO Overflow interrupts
      net: stmmac: xgmac: Correct supported speed modes
      net: stmmac: Set CIC bit only for TX queues with COE

 drivers/net/ethernet/stmicro/stmmac/dwxgmac2_core.c | 13 +++++++++++--
 drivers/net/ethernet/stmicro/stmmac/dwxgmac2_dma.c  |  9 +++++----
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c   |  6 ++++--
 3 files changed, 20 insertions(+), 8 deletions(-)
---
base-commit: b1c92cdf5af3198e8fbc1345a80e2a1dff386c02
change-id: 20250714-xgmac-minor-fixes-40287f221dce

Best regards,
-- 
Rohan G Thomas <rohan.g.thomas@altera.com>

