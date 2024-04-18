From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH net-next v3 0/2] Read PHY address of switch from device
 tree on MT7530 DSA subdriver
Date: Thu, 18 Apr 2024 08:35:29 +0300
Message-Id: <20240418-b4-for-netnext-mt7530-phy-addr-from-dt-and-simplify-core-ops-v3-0-3b5fb249b004@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACGxIGYC/63OwW7DIBAE0F+JOHcrDATsnPofVQ4YlhqpBmtBV
 qzI/x7Kref2OBpp3jxZQYpY2O3yZIR7LDGnFuTbhbnFpi+E6FtmggvFpVAwKwiZIGFN+KiwVnO
 VHLblAOs9QaC8gq9gk4cS1+07hgNcJoS8FdBKGX0dR5zRskZshCE+Ov/J2iT8bLJ7a5ZYaqaj/
 9qH3vcLavjjhX0ADjMfJ6l9EMbwD0sxuend5bXLu/hPTTRtsEarySkvZ/1LO8/zBZ9kUQ+BAQA
 A
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: Bartel Eerdekens <bartel.eerdekens@constell8.be>, 
 mithat.guner@xeront.com, erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>, 
 Florian Fainelli <florian.fainelli@broadcom.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713418557; l=1603;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=SzDN9toTqBr0GiH5AKRvQI5qpmgWxF0RN8hrv7mhvnE=;
 b=oYU7F2zcwRLKpqjIwaaYIv+FBg9Jih3CavG5flzWyPS1k6apLTqz0Y1UOsntLB/8cVvMOAasm
 iE3qA9yTmSxAtZ+Nw8KeF+4mwHYGT/qJAS+1Ao0ErK4w62bFF3IXT6t
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series makes the driver read the PHY address the switch listens
on from the device tree which, in result, brings support for MT7530
switches listening on a different PHY address than 31. And the patch series
simplifies the core operations.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Changes in v3:
- Patch 1
  - Whilst compiling, GCC suggests parentheses around '+' in operand of
    '&'. Address that on the MT753X_CTRL_PHY_ADDR macro.
  - Instead of storing the PHY address in the mt7530_priv structure, store
    the MDIO device pointer as suggested by Florian.
- Link to v2: https://lore.kernel.org/r/20240414-b4-for-netnext-mt7530-phy-addr-from-dt-and-simplify-core-ops-v2-0-1a7649c4d3b6@arinc9.com

Changes in v2:
- Patch 1
  - Use a more efficient definition for the MT753X_CTRL_PHY_ADDR macro
    provided by Daniel.
- Link to v1: https://lore.kernel.org/r/20240414-b4-for-netnext-mt7530-phy-addr-from-dt-and-simplify-core-ops-v1-0-b08936df2770@arinc9.com

---
Arınç ÜNAL (2):
      net: dsa: mt7530-mdio: read PHY address of switch from device tree
      net: dsa: mt7530: simplify core operations

 drivers/net/dsa/mt7530-mdio.c |  28 +++++-----
 drivers/net/dsa/mt7530.c      | 127 +++++++++++++++++++-----------------------
 drivers/net/dsa/mt7530.h      |   4 +-
 3 files changed, 75 insertions(+), 84 deletions(-)
---
base-commit: 2bd99aef1b19e6da09eff692bc0a09d61d785782
change-id: 20240324-b4-for-netnext-mt7530-phy-addr-from-dt-and-simplify-core-ops-64476588ebea

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

