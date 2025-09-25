From: Rohan G Thomas <rohan.g.thomas@altera.com>
Subject: [PATCH net-next v3 0/2] net: stmmac: Drop frames causing HLBS
 error
Date: Thu, 25 Sep 2025 22:06:12 +0800
Message-Id: <20250925-hlbs_2-v3-0-3b39472776c2@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFRM1WgC/12OQQ6CMBBFr0JmbQ0dLFBW3sMY08IgTbCYtmkwh
 LvbdGHU5c+f9/5s4MkZ8tAVGziKxpvFplAdCugnZe/EzJAyYImilJyzadb+hkyMwyDo1FZjiZC
 On45Gs2bRBSwFZmkNcE3NZHxY3CsvRJ77f1nkjLNe10JQK6XQzVnNgZw69ssjOyJ+c+LDYeKww
 brWqNJD8ofb9/0NjG7N9t8AAAA=
X-Change-ID: 20250911-hlbs_2-5fdd5e483f02
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758809186; l=1247;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=JZaRkLJomBSdsRDEvpNByeOgtyybOCR1lGmXJvP8BFY=;
 b=cjIvuKTzoFGnXBwe3ISNMpVhnpZwew0JHYG4Cg3JIILuwsqz/31E73x5REcfTS+HOiIBAxP40
 5LpEvSW8hGRBsW89XRb0Ndgdh0Hd8lnVPVPYxTf5ljE4KsOiQFCMIH5
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset consists of following patchset to avoid netdev watchdog
reset due to Head-of-Line Blocking due to EST scheduling error.
 1. Drop those frames causing HLBS error
 2. Add HLBS frame drops to taprio stats

Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
---
Changes in v3:
- Split commit into 2 and add this cover letter
- Updated the commit messages with expansion for HLBS and DFBS
- Link to v2: https://lore.kernel.org/r/20250915-hlbs_2-v2-1-27266b2afdd9@altera.com

Changes in v2:
- Removed unnecessary parantheses
- Link to v1: https://lore.kernel.org/r/20250911-hlbs_2-v1-1-cb655e8995b7@altera.com

---
Rohan G Thomas (2):
      net: stmmac: est: Drop frames causing HLBS error
      net: stmmac: tc: Add HLBS drop count to taprio stats

 drivers/net/ethernet/stmicro/stmmac/common.h     | 1 +
 drivers/net/ethernet/stmicro/stmmac/stmmac_est.c | 9 ++++++---
 drivers/net/ethernet/stmicro/stmmac/stmmac_est.h | 1 +
 drivers/net/ethernet/stmicro/stmmac/stmmac_tc.c  | 7 +++++--
 4 files changed, 13 insertions(+), 5 deletions(-)
---
base-commit: 12de5f0f6c2d7aad7e60aada650fcfb374c28a5e
change-id: 20250911-hlbs_2-5fdd5e483f02

Best regards,
-- 
Rohan G Thomas <rohan.g.thomas@altera.com>

