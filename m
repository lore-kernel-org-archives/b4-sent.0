From: Rohan G Thomas <rohan.g.thomas@altera.com>
Subject: [PATCH net-next 0/4] net: stmmac: socfpga: Add Agilex5 platform
 support and enhancements
Date: Wed, 29 Oct 2025 16:06:12 +0800
Message-Id: <20251029-agilex5_ext-v1-0-1931132d77d6@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPXKAWkC/x2MUQqAIBAFrxL7nZBCSF0lIkxftRAWKiFId0/6H
 JiZQhGBEWlsCgU8HPnyFWTbkD2M3yHYVSbVqV52ahBm5xO5X5CTsFKvTuvBOmxUiztg4/zfJvJ
 IwleL5vf9AEtpE2pnAAAA
X-Change-ID: 20251029-agilex5_ext-c17bd779cdef
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Steffen Trumtrar <s.trumtrar@pengutronix.de>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761725182; l=1154;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=lJ1JcnHdvyDKrgvkF/InxR6fht7QWyd7w3ZrjqQQ9h8=;
 b=DlJCfseSUGZMDjXBw1VVh0mpCeu7xVTb3IZNFGwtIb2gtoPFVZd7U5fHRN6pO+qAd5Jjj6orE
 q/SIliAdApzAhEVmXtDQZjhmvj49K5KPSkeCRRyKCOfz2udKbhDaMSb
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for the Agilex5 EMAC platform to the
dwmac-socfpga driver.

The series includes:
   - Platform configuration for Agilex5 EMAC
   - Enabling Time-Based Scheduling (TBS) for Tx queues 6 and 7
   - Enabling TCP Segmentation Offload(TSO)
   - Adding hardware-supported cross timestamping using the SMTG IP,
     allowing precise synchronization between MAC and system time via
     PTP_SYS_OFFSET_PRECISE.

Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
---
Rohan G Thomas (4):
      net: stmmac: socfpga: Agilex5 EMAC platform configuration
      net: stmmac: socfpga: Enable TBS support for Agilex5
      net: stmmac: socfpga: Enable TSO for Agilex5 platform
      net: stmmac: socfpga: Add hardware supported cross-timestamp

 .../net/ethernet/stmicro/stmmac/dwmac-socfpga.c    | 194 +++++++++++++++++++--
 drivers/net/ethernet/stmicro/stmmac/dwxgmac2.h     |   5 +
 2 files changed, 189 insertions(+), 10 deletions(-)
---
base-commit: a8abe8e210c175b1d5a7e53df069e107b65c13cb
change-id: 20251029-agilex5_ext-c17bd779cdef

Best regards,
-- 
Rohan G Thomas <rohan.g.thomas@altera.com>

