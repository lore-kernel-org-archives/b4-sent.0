From: Ramses de Norre <ramses@well-founded.dev>
Subject: [PATCH net v5 0/2] bonding: fix the initial last_rx seed for the
 ARP monitor
Date: Fri, 30 Oct 2026 15:51:14 +0100
Message-Id: <20261030-bonding-last-rx-v5-0-0b9b653f2f94@well-founded.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XOTWrDMBAF4KsErTtBf7HkrnKP0IWtGSUqRi6So
 6YE372KAyVQeznDm+/NnWVKgTJ7391ZohJyGGMdDm875i5dPBMErDOTXDbcCgP9GDHEMwxdniD
 dgCuufMe19S2yevWVyIfbIp5YpIl9PJf52n+Smx7WI3YJeRrTz9JbxBLerCgCBLTYNd549FbI4
 zcNA/jxGpFwj1SWkiJfGLnCyMoYp6xSVkon1Qaj/hjB1xhVmYNuufHC91xvfaNfGfuf0cBBoyX
 tUBvdmBVmnudfjBRj6aEBAAA=
X-Change-ID: 20260817-bonding-last-rx-0303fa048f9d
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793371876; l=3283;
 i=ramses@well-founded.dev; s=20260817; h=from:subject:message-id;
 bh=HIYn8VwTx+6igHuhnbuF729ujWFvIM7B9ubzvtMtSVU=;
 b=dKgrrTRXVX1LGHd/1hXgQbbC6jlNaF6io2ZkQA5Ul1o2bp9ql2X86sRUwplQbl8lsCyUKgz4s
 5rzT2ZrMllwBmYltcG6737wS3gXdiGUIIINevh+NdQ9I3aitYrj81PA
X-Developer-Key: i=ramses@well-founded.dev; a=ed25519;
 pk=1vBXHBVeJBMaC+2Zuonl0QQhEgGIQHERyF5RZNnrCmw=
X-Endpoint-Received: by B4 Relay for ramses@well-founded.dev/20260817 with auth_id=957
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bond_enslave() seeds a new slave's last_rx before it has received
anything. The ARP monitor checks that seed with an up test for a slave
that starts DOWN, and with a down test for a slave that starts UP. The
seed is wrong for both.

Patch 1 fixes a slave that starts DOWN. Since the up test gained
arp_interval/2 of slack, the seed falls inside the up window, so the
slave is reported UP for half an interval without having received
anything.

Patch 2 fixes a slave that starts UP. The seed brings its down deadline
forward by one interval compared to what arp_missed_max implies. In
load-balance mode, which has no grace period after enslavement, a
healthy slave can flap DOWN with arp_missed_max=1.

Both patches only cover a slave enslaved while the ARP monitor is
running. The seed is not refreshed when the monitor starts later, from
bond_open() or when arp_interval is set at runtime. That predates this
series, I will address it in a separate follow-up.

Signed-off-by: Ramses de Norre <ramses@well-founded.dev>
---
Changes in v5:
- Patch 1: set last_link_up in the UP branch of the seed (Hangbin).
- Patch 1: say "until it receives traffic" instead of "until a real
  reply arrives", any frame updates last_rx with arp_validate=none
  (Sashiko).
- Patch 2: say that it only covers a slave enslaved while the ARP
  monitor is running (Sashiko).
- Pick up Hangbin's Reviewed-by on patch 1.
- Link to v4: https://patch.msgid.link/20261028-bonding-last-rx-v4-0-4d8e4cd47467@well-founded.dev

Changes in v4:
- Patch 1: only use the older seed for a slave that starts DOWN. v3
  also applied it to a slave that starts UP, which brought its down
  deadline forward by one interval (Jay).
- New patch 2: seed a slave that starts UP with last_link_up, giving it
  a full arp_missed_max window. Fixes an existing flap in load-balance
  mode with arp_missed_max=1.
- Drop Hangbin's Reviewed-by, patch 1 changed.
- Link to v3: https://patch.msgid.link/20261027-bonding-last-rx-v3-1-54907f1fb042@well-founded.dev

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
Ramses de Norre (2):
      bonding: fix initial last_rx vs ARP-monitor slack window
      bonding: give a slave that starts UP a full arp_missed_max window

 drivers/net/bonding/bond_main.c | 28 ++++++++++++++++++++--------
 1 file changed, 20 insertions(+), 8 deletions(-)
---
base-commit: f75062536e2d45ee182828f0e47e0124be2fdc8d
change-id: 20260817-bonding-last-rx-0303fa048f9d

Best regards,
--  
Ramses de Norre <ramses@well-founded.dev>

