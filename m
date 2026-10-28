From: Ramses de Norre <ramses@well-founded.dev>
Date: Wed, 28 Oct 2026 12:48:08 +0100
Subject: [PATCH net v4 2/2] bonding: give a slave that starts UP a full
 arp_missed_max window
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-bonding-last-rx-v4-2-4d8e4cd47467@well-founded.dev>
References: <20261028-bonding-last-rx-v4-0-4d8e4cd47467@well-founded.dev>
In-Reply-To: <20261028-bonding-last-rx-v4-0-4d8e4cd47467@well-founded.dev>
To: Jay Vosburgh <jv@jvosburgh.net>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Jiri Bohac <jbohac@suse.cz>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikolay Aleksandrov <razor@blackwall.org>, 
 Hangbin Liu <hangbin.liu@linux.dev>, 
 Ramses de Norre <ramses@well-founded.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793188089; l=2265;
 i=ramses@well-founded.dev; s=20260817; h=from:subject:message-id;
 bh=jXnai77FahX09fOtY6Rp21l2WpqSYi/O/ZmzYrJWvMs=;
 b=U5R6R30n2YS166qbGZnnwdsJawdGkfiO85aLqHD+vTbIYY2cxRR+aLMD+AVYrDChKyI6ZQF7D
 lttVjGTPwTUB0frPT+bYmWCLlInw3wxKaTUR7hUKZ4fAlFkJ5wToByX
X-Developer-Key: i=ramses@well-founded.dev; a=ed25519;
 pk=1vBXHBVeJBMaC+2Zuonl0QQhEgGIQHERyF5RZNnrCmw=
X-Endpoint-Received: by B4 Relay for ramses@well-founded.dev/20260817 with auth_id=957
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ARP monitor marks an UP slave DOWN once jiffies passes
last_rx + arp_missed_max * arp_interval + arp_interval/2. bond_enslave()
seeds last_rx one arp_interval (plus a tick) in the past, which brings
the down deadline of a slave that starts UP forward by one interval
compared to what arp_missed_max promises.

Active-backup mode hides this with a grace period after enslavement in
bond_ab_arp_inspect(). Load-balance mode has no grace period after
enslavement. With arp_missed_max=1 the deadline is half an interval
after enslavement, and the first monitor run checks the slave before it
sends the first probe. If that run lands in the second half of the
interval, a healthy slave is reported "interface is now down" and comes
back UP on the next run.

Seed a slave that starts UP with last_link_up instead, so it gets a full
arp_missed_max window for its first reply. bond_arp_rcv() and
bond_na_rcv() only trust ARPs seen on backup slaves once the active
slave's last_rx is after its last_link_up. A seed equal to last_link_up
keeps that check false until a real reply arrives, as it is today.

Fixes: 5944b5abd864 ("Bonding: add arp_missed_max option")
Signed-off-by: Ramses de Norre <ramses@well-founded.dev>
---
 drivers/net/bonding/bond_main.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/net/bonding/bond_main.c b/drivers/net/bonding/bond_main.c
index bfa4cb97e647c..de5b196f4a1ee 100644
--- a/drivers/net/bonding/bond_main.c
+++ b/drivers/net/bonding/bond_main.c
@@ -2160,9 +2160,12 @@ int bond_enslave(struct net_device *bond_dev, struct net_device *slave_dev,
 	if (new_slave->link == BOND_LINK_DOWN)
 		new_slave->last_rx = jiffies -
 			(2 * msecs_to_jiffies(bond->params.arp_interval) + 1);
+	/* Give a slave that starts UP a full arp_missed_max window. Not
+	 * seeding it later than last_link_up keeps bond_arp_rcv() from
+	 * trusting ARPs on backup slaves before the active one got a reply.
+	 */
 	else
-		new_slave->last_rx = jiffies -
-			(msecs_to_jiffies(bond->params.arp_interval) + 1);
+		new_slave->last_rx = new_slave->last_link_up;
 	for (i = 0; i < BOND_MAX_ARP_TARGETS; i++)
 		new_slave->target_last_arp_rx[i] = new_slave->last_rx;
 

-- 
2.56.0

