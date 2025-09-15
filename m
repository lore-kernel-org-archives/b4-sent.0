From: Rohan G Thomas <rohan.g.thomas@altera.com>
Subject: [PATCH net v2 0/2] net: stmmac: Minor fixes for stmmac EST
 implementation
Date: Mon, 15 Sep 2025 16:17:17 +0800
Message-Id: <20250915-qbv-fixes-v2-0-ec90673bb7d4@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAI7Lx2gC/22Myw7CIBQFf6W5azG9pC9c+R+mC2xPLYlCBUI0D
 f8u6drlnJmcnQK8QaBLtZNHMsE4W0CeKppWbR8QZi5MspZtrZjF+57EYj4IotHomhlDB/RU+s3
 jECW/kUWksYyrCdH57/Gf+FB/rhKLWmBgqFb108LLVT8jvD5P7kVjzvkHWuVGd6gAAAA=
X-Change-ID: 20250911-qbv-fixes-4ae64de86ee7
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Jose Abreu <Jose.Abreu@synopsys.com>, 
 Rohan G Thomas <rohan.g.thomas@intel.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757924239; l=899;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=F/X+TtZHooGZVCVdoXlX23gyuHCMQDwSSkVtX3di3Hg=;
 b=bi6AtS44Cm+PAB1TLYBv/5mE8nemeFtjJHyyt2gUpKfTRwLORFKt6gXA8FrQeXWPi9muVBfYJ
 Lh5o/Pnal8SCzk2Xrv11tNs0rwrZbC5HqjijLT6SOGWlDtKX5riau4o
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset includes following minor fixes for stmmac EST
implementation:
   1. Fix GCL bounds checks
   2. Consider Tx VLAN offload tag length for maxSDU

Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
---
Changes in v2:
- Use GENMASK instead of BIT for clarity and consistency
- Link to v1: https://lore.kernel.org/r/20250911-qbv-fixes-v1-0-e81e9597cf1f@altera.com

---
Rohan G Thomas (2):
      net: stmmac: est: Fix GCL bounds checks
      net: stmmac: Consider Tx VLAN offload tag length for maxSDU

 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 25 ++++++++++++++++-------
 drivers/net/ethernet/stmicro/stmmac/stmmac_tc.c   |  4 ++--
 2 files changed, 20 insertions(+), 9 deletions(-)
---
base-commit: 5b5ba63a54cc7cb050fa734dbf495ffd63f9cbf7
change-id: 20250911-qbv-fixes-4ae64de86ee7

Best regards,
-- 
Rohan G Thomas <rohan.g.thomas@altera.com>

