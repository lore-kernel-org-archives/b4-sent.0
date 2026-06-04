From: Cedric Jehasse <cedric.jehasse@luminex.be>
Subject: [PATCH net-next 0/2] net: dsa: mv88e6xxx: add support for dcb pcp
 app
Date: Thu, 04 Jun 2026 10:30:13 +0200
Message-Id: <20260604-net-next-mv88e6xxx-pcp-prio-v1-0-f9d10fe6cdc8@luminex.be>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJY3IWoC/23NOw7DIBAE0KtYWwdpwQaDrxK5MLBOKPwJOBZSl
 LuHfKsUW4xGO+8GiWKgBF11g0h7SGGZS+CHCtx5mE/Egi8ZBAqFCms201Yub2zatSaVc2arW9k
 aw8JkK4UbhtYIZaEsrJHGkF/rR/g+Qv9uIl2uhds+9U/rqpfV1PjPcjYxwQXnyhRJ6W6XT8kOi
 ZhbpilsXYXGNMJ78s4ahaOhVo9e85ZcXY8SuefYoJMW+vv9AYgTS/sBAQAA
X-Change-ID: 20260603-net-next-mv88e6xxx-pcp-prio-5752caa7926b
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Luke Howard <lukeh@padl.com>, Cedric Jehasse <cedric.jehasse@gmail.com>, 
 Cedric Jehasse <cedric.jehasse@luminex.be>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780561819; l=2032;
 i=cedric.jehasse@luminex.be; s=20260213; h=from:subject:message-id;
 bh=bGDZ2KmYMu8TPrWbvyodp+cEnNoB47xZ8xSbg/l4UNA=;
 b=Pkc1VjKFsVN4zwDEY/02NcavPpe08EC0GqN9rrjLAWxSbSY8Br3Kf/GmPvMdEcmv4fTDTrkIE
 Bit53QYOoWfBUNvr3AjMZBVJVqZYfQwGg7sTHSiUNTNAXqupyRfdq67
X-Developer-Key: i=cedric.jehasse@luminex.be; a=ed25519;
 pk=DL2RaHc2bc7tTDTMJdugm42BtJk4Ip+7V41Gkj+Avjk=
X-Endpoint-Received: by B4 Relay for cedric.jehasse@luminex.be/20260213 with auth_id=638
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for dcb pcp app to the mv88e6xxx
driver. The pcp app is there to configure pcp based queue
classification.

In the Marvell switches this is done by configuring the IEEE PRI Mapping
table. There are different hardware implementations of this table
depending on the switch:
* a global table
* the 6390 has one table per port
* the 6393 has one table for DEI=0, and another table for DEI=1 per port

For this the DSA framework needs to be extended. The implementation for
pcp-prio in the DSA framework is very similar to existing dcsp-prio
implementation.

There's another patch series [1] on the mailing list that uses the same
IEEE PRI Mapping table to implement MPQRIO. To me the dcb pcp app feels
like the natural way to configure the pcp to QPri mappings in the
switch.

[1] https://lore.kernel.org/netdev/20260602-mv88e6xxx-8021qat-mqprio-v2-0-72be14522e7c@padl.com/

Signed-off-by: Cedric Jehasse <cedric.jehasse@luminex.be>
---
Cedric Jehasse (2):
      net: dsa: add support for dcb pcp app
      net: dsa: mv88e6xxx: add support for dcb pcp app

 drivers/net/dsa/mv88e6xxx/Makefile |   1 +
 drivers/net/dsa/mv88e6xxx/chip.c   |  36 ++++++
 drivers/net/dsa/mv88e6xxx/chip.h   |  17 +++
 drivers/net/dsa/mv88e6xxx/dcb.c    | 229 +++++++++++++++++++++++++++++++++++++
 drivers/net/dsa/mv88e6xxx/dcb.h    |  21 ++++
 drivers/net/dsa/mv88e6xxx/port.c   |  28 ++++-
 drivers/net/dsa/mv88e6xxx/port.h   |   8 ++
 include/net/dsa.h                  |  10 ++
 net/dsa/user.c                     | 126 ++++++++++++++++++--
 9 files changed, 467 insertions(+), 9 deletions(-)
---
base-commit: 09942ddedcb960f9e78fd817ec33f501d1040c5b
change-id: 20260603-net-next-mv88e6xxx-pcp-prio-5752caa7926b
prerequisite-change-id: 20260430-net-next-mv88e6xxx-cbs-2121169caa68:v5
prerequisite-patch-id: 8ad59c43368d4639e0cabcc59a7f6e487560d3f7
prerequisite-patch-id: 88ee88bf34ac3631056bc92c6c6251c29cf7223c

Best regards,
-- 
Cedric Jehasse <cedric.jehasse@luminex.be>

