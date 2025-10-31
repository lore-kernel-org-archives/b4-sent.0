From: Rohan G Thomas <rohan.g.thomas@altera.com>
Subject: [PATCH net-next v2 0/4] net: stmmac: socfpga: Add Agilex5 platform
 support and enhancements
Date: Sat, 01 Nov 2025 01:27:06 +0800
Message-Id: <20251101-agilex5_ext-v2-0-a6b51b4dca4d@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGrxBGkC/22NwQqDMBBEf0X23JRsxEp66n8UKWmy6oKNkgRJk
 fx7g+cehzfz5oBIgSnCvTkg0M6RV1+DujRgZ+MnEuxqBiVVh1JpYSZeKHcvyklY7N+u77V1NEJ
 dbIFGzqftCZ6S8LUFQyUzx7SG73mz48n/GncUUqBuEVtVze72MEuiYK52/cBQSvkBxwC0UbEAA
 AA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761931634; l=1421;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=t4zIx4Z11X9zS02u+s0yDHEllOpDAKEqSMdLm4SCIRU=;
 b=8tiYGEzN7w19aqajaofQRjkGf2F3m3eiOWWkDj28bjUqjQj6UIaO4zBm5kbVZIxDz1VNq8w2i
 dSp1UujxJ92AuHoJwtCC4A5HU1kp3nuDde1lw7H3PS28n7NfeQi3Q6x
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
Changes in v2:
- Fixed reduntant leftover tsis irq and use_ns changes from smtg_crosststamp
- Keep common platform config for socfpga platforms in socfpga_dwmac_probe
- Link to v1: https://lore.kernel.org/r/20251029-agilex5_ext-v1-0-1931132d77d6@altera.com

---
Rohan G Thomas (4):
      net: stmmac: socfpga: Agilex5 EMAC platform configuration
      net: stmmac: socfpga: Enable TBS support for Agilex5
      net: stmmac: socfpga: Enable TSO for Agilex5 platform
      net: stmmac: socfpga: Add hardware supported cross-timestamp

 .../net/ethernet/stmicro/stmmac/dwmac-socfpga.c    | 166 ++++++++++++++++++++-
 drivers/net/ethernet/stmicro/stmmac/dwxgmac2.h     |   5 +
 2 files changed, 168 insertions(+), 3 deletions(-)
---
base-commit: 0d0eb186421d0886ac466008235f6d9eedaf918e
change-id: 20251029-agilex5_ext-c17bd779cdef

Best regards,
-- 
Rohan G Thomas <rohan.g.thomas@altera.com>

