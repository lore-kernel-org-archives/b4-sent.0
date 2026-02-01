From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH net-next v8 0/6] move CAN skb headroom content to skb
 extensions
Date: Sun, 01 Feb 2026 15:33:15 +0100
Message-Id: <20260201-can_skb_ext-v8-0-3635d790fe8b@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACtkf2kC/23NTWrDMBAF4KsErasykmP9ZJV7lBIUa6YWAdlIx
 rgE372DV3bx8vHme/MWFUvCKm6Xtyg4p5qGzMF9XETXh/yDMkXOQoM2oLSTXciP+no+cJkkoA3
 eY1TeXQWLsSClZVv7EhknmflKfHPTpzoN5Xd7M6utP12clQTZNEAGKLbR4r0PZXoN4/jJe9vU3
 O65P/KWuVa61RQ75wFOuNnxBo7cMHfUYaDwtKTNCbd7ro7cMo8RyJG7BtfEf3xd1z/Azg/pcAE
 AAA==
X-Change-ID: 20260128-can_skb_ext-0e7a99ed1984
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Oliver Hartkopp <socketcan@hartkopp.net>, 
 Robin van der Gracht <robin@protonic.nl>, 
 Oleksij Rempel <o.rempel@pengutronix.de>, kernel@pengutronix.de, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, kernel test robot <lkp@intel.com>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769956418; l=4501;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=0yW/m2RMnzKOSyHSfGPSc1BiRUjwlUxvIIqoWplTL+Q=;
 b=lI1XAqOOLQAt6dwlAdR4GxB4ZFeze5hn3FhTfQJDEfC9HIc2Xm+rs5ICkS5k1O587YfO22s/b
 NmYOgVRla5fDA6Bt4L+jkmtp2aZWnhzswCfHANHO6J9EG1UijbUTE0r
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CAN bus related skbuffs (ETH_P_CAN/ETH_P_CANFD/ETH_P_CANXL) simply contain
CAN frame structs for CAN CC/FD/XL of skb->len length at skb->data. Those
CAN skbs do not have network/mac/transport headers nor other such
references for encapsulated protocols like ethernet/IP protocols.

To store data for CAN specific use-cases all CAN bus related skbuffs are
created with a 16 byte private skb headroom (struct can_skb_priv). Using
the skb headroom and accessing skb->head for this private data led to
several problems in the past likely due to "The struct can_skb_priv
business is highly unconventional for the networking stack." [1]

This patch set aims to remove the unconventional skb headroom usage for CAN
bus related skbuffs and use the common skb extensions instead.

[1] https://lore.kernel.org/linux-can/20260104074222.29e660ac@kernel.org/

---
Changes in v2:
- Patch#1: use u32 instead of __u32 for "struct uniqframe::hash"
- Patch#3: use u{8,16} instead of __u{8,16} for "struct can_skb_ext"
- Patch#6: add missing patch
- Link to v1: https://patch.msgid.link/20260125201601.5018-1-socketcan@hartkopp.net

Changes in v3:
- Patch#2: new patch: rename dev_put() in CAN subsystem suggested by Checkpatch
- Patch#3: use netdev_put() instead of dev_put() suggested by Checkpatch
- Patch#3: initialize can_gw_hops in can_skb_ext_add() suggested by AI-bot
- Patch#6: add linebreak in sock_alloc_send_skb() to fit the 80 columns (Checkpatch)
- Link to v2: https://lore.kernel.org/linux-can/20260128-can-skb-ext-v2-0-fe64aa152c8a@pengutronix.de/

Changes in v4:
Solve the netdev_put() / dev_put() suggestion from Checkpatch in a separate
patch set. Therefore these changes are based on V2 again. 
- Patch#2: initialize can_gw_hops in can_skb_ext_add() suggested by AI-bot
- Patch#5: add linebreak in sock_alloc_send_skb() to fit the 80 columns
- Link to v2: https://lore.kernel.org/linux-can/20260128-can-skb-ext-v2-0-fe64aa152c8a@pengutronix.de/

Changes in v5:
- Patch#2: use skb_ext_add() for the cloned skb suggested by AI-bot
- Patch#2: use netdev_put() instead of dev_put() suggested by Checkpatch
- managed to get the receipient list with b4 prep --auto-to-cc
- Link to v4: https://lore.kernel.org/netdev/20260128-can_skb_ext-v1-0-330f60fd5d7e@hartkopp.net/

Changes in v6:
- Patch#1: drop extern prototype in header file (Checkpatch)
- Patch#6: vxcan: correctly reset drop counter with skb extensions (AI-bot)
- Link to v5: https://patch.msgid.link/20260129-can_skb_ext-v5-0-21252fdc8900@hartkopp.net

Changes in v7:
- Patch#2: common handling for cloned skbs in gw.c j1939/transport.c vxcan.c
- Patch#6: vxcan: correctly reset drop counter based on updated Patch#2
- Link to v6: https://patch.msgid.link/20260130-can_skb_ext-v6-0-8fceafab7f26@hartkopp.net

Changes in v8:
- Patch#2: Fix double free in vxcan.c patch (AI-bot)
- Patch#2: Fix missing return value settings in error paths (AI-bot)
- Patch#2: Fix an indention issue in the original code (kernel test robot)
- Link to v7: https://patch.msgid.link/20260131-can_skb_ext-v7-0-dd0f8f84a83d@hartkopp.net

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>

---
Oliver Hartkopp (6):
      can: use skb hash instead of private variable in headroom
      can: add CAN skb extension infrastructure
      can: move ifindex to CAN skb extensions
      can: move frame_len to CAN skb extensions
      can: remove private CAN skb headroom infrastructure
      can: gw: use can_gw_hops instead of sk_buff::csum_start

 MAINTAINERS               |   1 +
 drivers/net/can/dev/skb.c | 123 +++++++++++++++++++++++++++++-----------------
 drivers/net/can/vxcan.c   |  15 +++++-
 include/linux/can/core.h  |   1 +
 include/linux/can/skb.h   |  38 +++++---------
 include/linux/skbuff.h    |   3 ++
 include/net/can.h         |  28 +++++++++++
 net/can/Kconfig           |   1 +
 net/can/af_can.c          |  23 ++++++---
 net/can/bcm.c             |  26 +++++++---
 net/can/gw.c              |  42 +++++++++-------
 net/can/isotp.c           |  46 +++++++++++------
 net/can/j1939/socket.c    |  16 ++++--
 net/can/j1939/transport.c |  39 +++++++++++----
 net/can/raw.c             |  23 ++++++---
 net/core/skbuff.c         |   4 ++
 16 files changed, 287 insertions(+), 142 deletions(-)
---
base-commit: 239f09e258b906deced5c2a7c1ac8aed301b558b
change-id: 20260128-can_skb_ext-0e7a99ed1984

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

