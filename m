From: Ramses de Norre <ramses@well-founded.dev>
Date: Tue, 27 Oct 2026 13:23:29 +0100
Subject: [PATCH net v3] bonding: fix initial last_rx vs ARP-monitor slack
 window
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-bonding-last-rx-v3-1-54907f1fb042@well-founded.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XNQQ7CIBAF0KsY1mJgMC115T2MixaGFtNQAxRrm
 t7dFjcu6vJP/rw/k4DeYiCXw0w8Jhvs4NYgjgeiutq1SK1eMwEGBZO8pM3gtHUt7esQqZ8oE0y
 Ymp2lqTRZv54ejZ2yeCMOI7l/j2FsHqjiZm21zoY4+HfeTTyX/04kTjmtdF2Y0mgjOVxf2PfUD
 KPTqE8aUx5J8MPADgMrUyohhZAACsQOsyzLB7lsV8cTAQAA
X-Change-ID: 20260817-bonding-last-rx-0303fa048f9d
To: Jay Vosburgh <jv@jvosburgh.net>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Jiri Bohac <jbohac@suse.cz>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikolay Aleksandrov <razor@blackwall.org>, 
 Hangbin Liu <liuhangbin@kylinos.cn>, 
 Ramses de Norre <ramses@well-founded.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793103811; l=3887;
 i=ramses@well-founded.dev; s=20260817; h=from:subject:message-id;
 bh=iLuXMQJ1SxlaYAgJ6k8T6L5P5ZUpQnl669RJjA7KhuI=;
 b=egGJkC94lXuW0zEaKLESCsSkMiu5EmZPrr3lE2In3Bof0dnjmZZWq9wH8A97RhZNl12/YvHI0
 NRTktxnngChCKVB2BJwwHAhhrD+AuF5ntrFDgOzcSTamrda8Z8QoGu1
X-Developer-Key: i=ramses@well-founded.dev; a=ed25519;
 pk=1vBXHBVeJBMaC+2Zuonl0QQhEgGIQHERyF5RZNnrCmw=
X-Endpoint-Received: by B4 Relay for ramses@well-founded.dev/20260817 with auth_id=957
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bond_enslave() seeds a new slave's last_rx with a timestamp old enough
that the ARP monitor does not consider the slave up until a real ARP
reply arrives. That is the purpose of the seed, see commit f31c7937c254
("bonding: start slaves with link down for ARP monitor").

The seed is one arp_interval (plus a tick) in the past, which was just
old enough when the test was "jiffies <= last_rx + arp_interval".
Commit da210f559019 ("bonding: add some slack to arp monitoring time
limits") added arp_interval/2 of slack to every such comparison without
adjusting the seed, so the seed now sits inside the window instead of
outside it. For the first half ARP interval after enslavement,
bond_ab_arp_inspect() therefore sees "received recently" for a slave
that has not received anything and proposes it UP. This happens for any
freshly enslaved slave, independent of primary_reselect.

When the slave is the configured primary, the still-armed force_primary
then makes it the active slave. ARP validation fails it shortly after,
since the link has not received anything (on SFP+ ports the PHY is
often still negotiating), and the bond falls back to the backup. With
primary_reselect=always the bond recovers once the port really comes
up, but drops traffic until then. With primary_reselect=failure,
force_primary has been spent and the bond stays on the backup.

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

Seed last_rx (and with it the per-target array and last_tx) two
intervals in the past, so it is outside the slack window from the
start. The initial link state is unchanged, it still comes from
netif_carrier_ok().

Fixes: da210f559019 ("bonding: add some slack to arp monitoring time limits")
Reviewed-by: Hangbin Liu <liuhangbin@kylinos.cn>
Signed-off-by: Ramses de Norre <ramses@well-founded.dev>
---
Changes in v3:
- No code changes. Rebase on current net.
- Reword the commit message along the lines of the v2 discussion: lead
  with what the last_rx seed is for, state that the false UP happens
  independent of primary_reselect, and that the initial link state is
  unchanged.
- Pick up Reviewed-by from Hangbin.
- Cc Nikolay. Hangbin asked for a second review, Jay or Nikolay, would
  you have a look?
- Link to v2: https://patch.msgid.link/20260827-bonding-last-rx-v2-1-7c3833822c23@well-founded.dev

Changes in v2:
- No code changes. Resend with my personal name in the From and
  Signed-off-by lines instead of my handle, as requested for the DCO.
- Link to v1: https://patch.msgid.link/20260817-bonding-last-rx-v1-1-9da6f7fdf812@well-founded.dev
---
 drivers/net/bonding/bond_main.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/bonding/bond_main.c b/drivers/net/bonding/bond_main.c
index 7019e5d8fdc8e..269384fadfa6f 100644
--- a/drivers/net/bonding/bond_main.c
+++ b/drivers/net/bonding/bond_main.c
@@ -2123,7 +2123,7 @@ int bond_enslave(struct net_device *bond_dev, struct net_device *slave_dev,
 		new_slave->link = BOND_LINK_DOWN;
 
 	new_slave->last_rx = jiffies -
-		(msecs_to_jiffies(bond->params.arp_interval) + 1);
+		(2 * msecs_to_jiffies(bond->params.arp_interval) + 1);
 	for (i = 0; i < BOND_MAX_ARP_TARGETS; i++)
 		new_slave->target_last_arp_rx[i] = new_slave->last_rx;
 

---
base-commit: f75062536e2d45ee182828f0e47e0124be2fdc8d
change-id: 20260817-bonding-last-rx-0303fa048f9d

Best regards,
--  
Ramses de Norre <ramses@well-founded.dev>

