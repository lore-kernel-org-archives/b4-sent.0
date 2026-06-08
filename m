From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 08 Jun 2026 11:22:08 +0400
Subject: [PATCH v3] net: dsa: qca8k: fix led devicename when using external
 mdio bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-qca8k-leds-fix-v3-1-a915bb2f37ae@outlook.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/03MywrCMBCF4Vcps3YkpmkdXPke4iKXiQ29pCa1C
 KXvbhAEl/+B822QOQXOcKk2SLyGHOJUoj5UYDs9PRiDKw1SyFa0gvBpNfU4sMvowxuZjHLk2ai
 zgXKaE5f5C97upX2KIy5dYv1jGqFk88+sEk9o2pq8q4kaq6/xtQwx9kcbR9j3Dy1x+lqkAAAA
X-Change-ID: 20260608-qca8k-leds-fix-e8b4d8feb47b
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Christian Marangi <ansuelsmth@gmail.com>, 
 Florian Fainelli <f.fainelli@gmail.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780903338; l=2408;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=HiUw3Q504F5hs2do7v6tmrj/sdstwjc54LpITglorVY=;
 b=6akJitugOoduxzekxXr8wUyxaunTXPSPvklTHqMbAzdPnSbxEeFFnt0i8kmIwCy8NxlIWVsL1
 UFb4R/AmSnvDsmCKI1yyVbZUYEV0weZfCN2/aOR1uGK2stn129rnQ5T
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The qca8k dsa switch can use either an external or internal mdio bus.
This depends on whether the mdio node is defined under the switch node
itself. Upon registering the internal mdio bus, the internal_mdio_bus
of the dsa switch is assigned to this bus. When an external mdio bus is
used, the driver still uses the internal_mdio_bus id which is used to
create the device names of the leds.
This leads to the leds being prefixed with '(efault)' as the
internal_mii_bus is null. So let's fix this by adding a null check and
use the devicename of the external bus instead when an external bus is
configured.

Fixes: 1e264f9d2918 ("net: dsa: qca8k: add LEDs basic support")
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
Resending this patch as v3 with an updated commit message. There was a
discussion on removing the notion of having an external and internal
bus which was never followed up on, yet the issue is still there.
Link: https://patchwork.kernel.org/project/netdevbpf/patch/20250425151309.30493-1-kabel@kernel.org/

Changed in v3:
- Rebased on top of tree
- Updated commit message to reflect renaming of slave_mii_bus to
  internal_mdio_bus
- Link to v2: https://lore.kernel.org/r/20250425-qca8k-leds-v2-1-b638fd3885ca@outlook.com
Changes in v2:
- Fixed c/p error from older kernel version: slave_mii_bus was renamed
  to internal_mdio_bus
- Link to v1: https://lore.kernel.org/r/20250425-qca8k-leds-v1-1-6316ad36ad22@outlook.com
---
 drivers/net/dsa/qca/qca8k-leds.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/net/dsa/qca/qca8k-leds.c b/drivers/net/dsa/qca/qca8k-leds.c
index 43ac68052baf..ef496e345a4e 100644
--- a/drivers/net/dsa/qca/qca8k-leds.c
+++ b/drivers/net/dsa/qca/qca8k-leds.c
@@ -429,7 +429,8 @@ qca8k_parse_port_leds(struct qca8k_priv *priv, struct fwnode_handle *port, int p
 		init_data.fwnode = led;
 		init_data.devname_mandatory = true;
 		init_data.devicename = kasprintf(GFP_KERNEL, "%s:0%d",
-						 priv->internal_mdio_bus->id,
+						 priv->internal_mdio_bus ?
+						 priv->internal_mdio_bus->id : priv->bus->id,
 						 port_num);
 		if (!init_data.devicename) {
 			fwnode_handle_put(led);

---
base-commit: 6e845bcb78c95af935094040bd4edc3c2b6dd784
change-id: 20260608-qca8k-leds-fix-e8b4d8feb47b

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

