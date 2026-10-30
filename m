From: Ramses de Norre <ramses@well-founded.dev>
Date: Fri, 30 Oct 2026 15:51:15 +0100
Subject: [PATCH net v5 1/2] bonding: fix initial last_rx vs ARP-monitor
 slack window
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-bonding-last-rx-v5-1-0b9b653f2f94@well-founded.dev>
References: <20261030-bonding-last-rx-v5-0-0b9b653f2f94@well-founded.dev>
In-Reply-To: <20261030-bonding-last-rx-v5-0-0b9b653f2f94@well-founded.dev>
To: Jay Vosburgh <jv@jvosburgh.net>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Jiri Bohac <jbohac@suse.cz>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikolay Aleksandrov <razor@blackwall.org>, 
 Hangbin Liu <hangbin.liu@linux.dev>, 
 Ramses de Norre <ramses@well-founded.dev>, 
 Hangbin Liu <liuhangbin@kylinos.cn>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793371876; l=4064;
 i=ramses@well-founded.dev; s=20260817; h=from:subject:message-id;
 bh=9c6Pugc3oHAUY5z5+KeFXjevrZwDeEo26HSsv07oE+o=;
 b=fX9IIktJKWRmAE5dl9+jG4WB/pqWL8pQi14+evrodqwCjGehZdYU5IixUuGD/g6AFo6ilRo/B
 tUzrxsjA/PAAQLgxP5BGg017OzZ3no88Guws0fjBh4y9P/NEINtcNZu
X-Developer-Key: i=ramses@well-founded.dev; a=ed25519;
 pk=1vBXHBVeJBMaC+2Zuonl0QQhEgGIQHERyF5RZNnrCmw=
X-Endpoint-Received: by B4 Relay for ramses@well-founded.dev/20260817 with auth_id=957
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bond_enslave() seeds a new slave's last_rx so that the ARP monitor does
not report it UP before it receives traffic, see commit f31c7937c254
("bonding: start slaves with link down for ARP monitor").

The seed is one arp_interval (plus a tick) in the past. That was old
enough when the up test was "jiffies <= last_rx + arp_interval". Commit
da210f559019 ("bonding: add some slack to arp monitoring time limits")
added arp_interval/2 of slack to that test without moving the seed, so
the seed now falls inside the up window. For the first half interval
after enslavement, bond_ab_arp_inspect() proposes a slave that starts
DOWN as UP although it has received nothing. The up test always uses a
single interval, so this does not depend on primary_reselect or
arp_missed_max.

If that slave is the configured primary, force_primary makes it the
active slave. ARP validation fails it shortly after (on SFP+ ports the
PHY is often still negotiating) and the bond falls back to the backup.
With primary_reselect=always the bond recovers once the port really
comes up, but drops traffic until then. With primary_reselect=failure,
force_primary is spent and the bond stays on the backup.

Reproducer:

  ip link add bond0 type bond mode active-backup arp_interval 1000 \
      arp_validate all arp_ip_target 192.0.2.1 \
      primary eth0 primary_reselect failure
  # eth0: SFP+ (slow link-up), eth1: RJ45 (fast link-up)
  ip link set eth0 master bond0
  ip link set eth1 master bond0
  ip link set bond0 up
  # bond0 lands on eth0 via force_primary, ARP-fails it before the
  # SFP+ has carrier, falls to eth1, and stays there.

Move the seed below the initial link state and seed a slave that starts
DOWN two intervals in the past, outside the up window. A slave that
starts UP keeps its current seed: the up test does not apply to it, and
an older seed would only bring its down deadline forward by one
interval. The initial link state is unchanged.

Fixes: da210f559019 ("bonding: add some slack to arp monitoring time limits")
Reviewed-by: Hangbin Liu <liuhangbin@kylinos.cn>
Signed-off-by: Ramses de Norre <ramses@well-founded.dev>
---
 drivers/net/bonding/bond_main.c | 24 ++++++++++++++++--------
 1 file changed, 16 insertions(+), 8 deletions(-)

diff --git a/drivers/net/bonding/bond_main.c b/drivers/net/bonding/bond_main.c
index 7019e5d8fdc8e..2f5638f4d3a78 100644
--- a/drivers/net/bonding/bond_main.c
+++ b/drivers/net/bonding/bond_main.c
@@ -2122,13 +2122,6 @@ int bond_enslave(struct net_device *bond_dev, struct net_device *slave_dev,
 	if (res && bond_needs_speed_duplex(bond))
 		new_slave->link = BOND_LINK_DOWN;
 
-	new_slave->last_rx = jiffies -
-		(msecs_to_jiffies(bond->params.arp_interval) + 1);
-	for (i = 0; i < BOND_MAX_ARP_TARGETS; i++)
-		new_slave->target_last_arp_rx[i] = new_slave->last_rx;
-
-	new_slave->last_tx = new_slave->last_rx;
-
 	/* check for initial state */
 	new_slave->link = BOND_LINK_NOCHANGE;
 	if (bond->params.miimon) {
@@ -2157,8 +2150,23 @@ int bond_enslave(struct net_device *bond_dev, struct net_device *slave_dev,
 					  BOND_SLAVE_NOTIFY_NOW);
 	}
 
-	if (new_slave->link != BOND_LINK_DOWN)
+	/* The ARP monitor's up test includes arp_interval/2 of slack, see
+	 * bond_time_in_interval(). Seed a slave that starts DOWN outside
+	 * that window, so it stays DOWN until it receives traffic.
+	 */
+	if (new_slave->link == BOND_LINK_DOWN) {
+		new_slave->last_rx = jiffies -
+			(2 * msecs_to_jiffies(bond->params.arp_interval) + 1);
+	} else {
 		new_slave->last_link_up = jiffies;
+		new_slave->last_rx = jiffies -
+			(msecs_to_jiffies(bond->params.arp_interval) + 1);
+	}
+	for (i = 0; i < BOND_MAX_ARP_TARGETS; i++)
+		new_slave->target_last_arp_rx[i] = new_slave->last_rx;
+
+	new_slave->last_tx = new_slave->last_rx;
+
 	slave_dbg(bond_dev, slave_dev, "Initial state of slave is BOND_LINK_%s\n",
 		  new_slave->link == BOND_LINK_DOWN ? "DOWN" :
 		  (new_slave->link == BOND_LINK_UP ? "UP" : "BACK"));

-- 
2.56.0

