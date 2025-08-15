From: Rohan G Thomas <rohan.g.thomas@altera.com>
Subject: [PATCH net-next v2 0/3] net: stmmac: xgmac: Minor fixes
Date: Sat, 16 Aug 2025 00:55:22 +0800
Message-Id: <20250816-xgmac-minor-fixes-v2-0-699552cf8a7f@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHpmn2gC/32NQQqDMBBFryKz7pRkatF25T2KixBHHahJSYKki
 HdvyAG6fDze/wdEDsIRns0BgXeJ4l0BujRgV+MWRpkKAym6q063mJfNWNzE+YCzZI7YKuq7mUh
 PlqF0n8BVlOwFjhM6zgnGYlaJyYdvPdt19X92d40K7a1VDzJ9bzoazDtxMFfrNxjP8/wBtwHLZ
 70AAAA=
X-Change-ID: 20250714-xgmac-minor-fixes-40287f221dce
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Serge Semin <fancer.lancer@gmail.com>, 
 Romain Gantois <romain.gantois@bootlin.com>, 
 Jose Abreu <Jose.Abreu@synopsys.com>, 
 Ong Boon Leong <boon.leong.ong@intel.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>, Andrew Lunn <andrew@lunn.ch>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755276924; l=1234;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=zl87QclcDa3DKTevz342RWsdUkmKZ3kWOu2bPgZotaQ=;
 b=e07IJKlqLpRHehRFXDj41qKkESxMxzz5NMzfNCTXpgPDuowY+O4sUC/gPBXEZ9NWseGEfNinm
 rkO9woTy9UxBhgwURhP+g6fPGdtebSJAlvhGr6DwzbJJ1lwj9/FqhuN
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
base-commit: 88250d40ed59d2b3c2dff788e9065caa7eb4dba0
change-id: 20250714-xgmac-minor-fixes-40287f221dce

Best regards,
-- 
Rohan G Thomas <rohan.g.thomas@altera.com>

