From: Rohan G Thomas <rohan.g.thomas@altera.com>
Subject: [PATCH net v4 0/3] net: stmmac: Fixes for stmmac Tx VLAN insert
 and EST
Date: Tue, 28 Oct 2025 11:18:42 +0800
Message-Id: <20251028-qbv-fixes-v4-0-26481c7634e3@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABI2AGkC/23MTQ7CIBAF4KuYWYvhr9C68h7GBYWpJdFWoSGap
 ncXWZgaXb6Z970ZIgaPEfabGQImH/045CC3G7C9Gc5IvMsZOOUVbRgj9zaRzj8wEmlQSYe1QtS
 Q+7eA5ZHrRxhwglM+9j5OY3iW/cTK689UYoQSrBk2VaNtx7qDuUwYzM6O1zKT+JpWa8rf1DZUa
 dG22skfKj6UUabXVGTqhJEcBVdSmS+6LMsLHTpqzx4BAAA=
X-Change-ID: 20250911-qbv-fixes-4ae64de86ee7
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Jose Abreu <Jose.Abreu@synopsys.com>, 
 Rohan G Thomas <rohan.g.thomas@intel.com>, 
 Boon Khai Ng <boon.khai.ng@altera.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761621544; l=2041;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=6Pkx7EpEceX8AGS9kNb6JSNTph9sXRbaGVrP8ohO+QE=;
 b=h888JNhaD6tt+8BW1WkjUzuWlKSKhGyEh25Z5t6P7ZlUiItvmkAuNr8VSOuHl3pvatHp3vM+L
 MKOtmFc0ofsCBXhuo2MgAO8ib72NbeJxayKeRFNZILGUuxzj5YnXLA8
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset includes following fixes for stmmac Tx VLAN insert and
EST implementations:
   1. Disable STAG insertion offloading, as DWMAC IPs doesn't support
      offload of STAG for double VLAN packets and CTAG for single VLAN
      packets when using the same register configuration. The current
      configuration in the driver is undocumented and is adding an
      additional 802.1Q tag with VLAN ID 0 for double VLAN packets.
   2. Consider Tx VLAN offload tag length for maxSDU estimation.
   3. Fix GCL bounds check

Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
---
Changes in v4:
- Reworked sdu_len check to be done before stmmac_vlan_insert
- Corrected formatting of the if block in the maxSDU check
- Updated variable declarations to follow reverse christmas tree order
- Revised the commit message to clearly reflect the maxSDU requirement
- Link to v3: https://lore.kernel.org/r/20251017-qbv-fixes-v3-0-d3a42e32646a@altera.com

Changes in v3:
- Commit for disabling 802.1AD tag insertion offload is introduced in
  to this patchset
- Add just VLAN_HLEN to sdu_len when 802.1Q tag offload is requested
- Link to v2: https://lore.kernel.org/r/20250915-qbv-fixes-v2-0-ec90673bb7d4@altera.com

Changes in v2:
- Use GENMASK instead of BIT for clarity and consistency
- Link to v1: https://lore.kernel.org/r/20250911-qbv-fixes-v1-0-e81e9597cf1f@altera.com

---
Rohan G Thomas (3):
      net: stmmac: vlan: Disable 802.1AD tag insertion offload
      net: stmmac: Consider Tx VLAN offload tag length for maxSDU
      net: stmmac: est: Fix GCL bounds checks

 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 32 ++++++++++-------------
 drivers/net/ethernet/stmicro/stmmac/stmmac_tc.c   |  4 +--
 drivers/net/ethernet/stmicro/stmmac/stmmac_vlan.c |  2 +-
 3 files changed, 17 insertions(+), 21 deletions(-)
---
base-commit: bfe62db5422b1a5f25752bd0877a097d436d876d
change-id: 20250911-qbv-fixes-4ae64de86ee7

Best regards,
-- 
Rohan G Thomas <rohan.g.thomas@altera.com>

