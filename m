From: Ramses de Norre <ramses@well-founded.dev>
Date: Fri, 30 Oct 2026 15:51:16 +0100
Subject: [PATCH net v5 2/2] bonding: give a slave that starts UP a full
 arp_missed_max window
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-bonding-last-rx-v5-2-0b9b653f2f94@well-founded.dev>
References: <20261030-bonding-last-rx-v5-0-0b9b653f2f94@well-founded.dev>
In-Reply-To: <20261030-bonding-last-rx-v5-0-0b9b653f2f94@well-founded.dev>
To: Jay Vosburgh <jv@jvosburgh.net>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Jiri Bohac <jbohac@suse.cz>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikolay Aleksandrov <razor@blackwall.org>, 
 Hangbin Liu <hangbin.liu@linux.dev>, 
 Ramses de Norre <ramses@well-founded.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793371876; l=2527;
 i=ramses@well-founded.dev; s=20260817; h=from:subject:message-id;
 bh=Jz6XOf8wK/vTGG6FZBTatFH3vzBsN5U/CtOmPMLqDGk=;
 b=ud5UqZ2PLRoXHmclyAZZgFGIviPMEZlhFDBxo3uAxdNCzS98Svhl/pTlmP6yrpxt29Y9qiksT
 dbIMi1U6s/fAHsNXkverOD/afPHF/CnkXgtyU04JK6SzZpMnAoyhgKi
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

This only covers a slave enslaved while the ARP monitor is running.
When the monitor starts later, from bond_open() or when arp_interval is
set at runtime, the seed is still as old as the time since enslavement,
as it was before this patch.

Fixes: 5944b5abd864 ("Bonding: add arp_missed_max option")
Signed-off-by: Ramses de Norre <ramses@well-founded.dev>
---
 drivers/net/bonding/bond_main.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/net/bonding/bond_main.c b/drivers/net/bonding/bond_main.c
index 2f5638f4d3a78..84eafb607c370 100644
--- a/drivers/net/bonding/bond_main.c
+++ b/drivers/net/bonding/bond_main.c
@@ -2158,9 +2158,13 @@ int bond_enslave(struct net_device *bond_dev, struct net_device *slave_dev,
 		new_slave->last_rx = jiffies -
 			(2 * msecs_to_jiffies(bond->params.arp_interval) + 1);
 	} else {
+		/* Give a slave that starts UP a full arp_missed_max window.
+		 * Not seeding it later than last_link_up keeps bond_arp_rcv()
+		 * from trusting ARPs on backup slaves before the active one
+		 * got a reply.
+		 */
 		new_slave->last_link_up = jiffies;
-		new_slave->last_rx = jiffies -
-			(msecs_to_jiffies(bond->params.arp_interval) + 1);
+		new_slave->last_rx = new_slave->last_link_up;
 	}
 	for (i = 0; i < BOND_MAX_ARP_TARGETS; i++)
 		new_slave->target_last_arp_rx[i] = new_slave->last_rx;

-- 
2.56.0

