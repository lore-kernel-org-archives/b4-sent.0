From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH net-next v4 0/6] move CAN skb headroom content to skb
 extensions
Date: Wed, 28 Jan 2026 23:43:39 +0100
Message-Id: <20260128-can_skb_ext-v1-0-330f60fd5d7e@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABuRemkC/x2MQQqEMBAEvxLmbCAJomYfshcRidrqIMwuiYgg/
 t3gsaCqLkqIjEQfdVHEwYl/ksEWisY1yALNU2ZyxlXGukaPQfq0DT3OXRvUwXtM1jcl5eIfMfP
 53loS7Fqypb4ldff9AMJsovBqAAAA
X-Change-ID: 20260128-can_skb_ext-0e7a99ed1984
To: netdev@vger.kernel.org, linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769640237; l=3309;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=f0b7C3R7nIS4pAEHba0gtxCqsmxcULxVtR793d7XUko=;
 b=ygKcs41SccF0rhpQpv0gVvUagf9crxEDNmSOk8rkEC1RG1zjSJU+mkQSosRH+E9NNGBZegnFp
 qNbMiyrG1u5Aj41T1MaO1RuU+k4Fr7gr5iZBBEYB4jpw7Z9gmfcrThk
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
 include/linux/can/core.h  |   1 +
 include/linux/can/skb.h   |  38 +++++---------
 include/linux/skbuff.h    |   3 ++
 include/net/can.h         |  28 +++++++++++
 net/can/Kconfig           |   1 +
 net/can/af_can.c          |  23 ++++++---
 net/can/bcm.c             |  26 +++++++---
 net/can/gw.c              |  38 +++++++-------
 net/can/isotp.c           |  45 +++++++++++------
 net/can/j1939/socket.c    |  15 ++++--
 net/can/j1939/transport.c |  28 +++++++----
 net/can/raw.c             |  22 ++++++---
 net/core/skbuff.c         |   4 ++
 15 files changed, 255 insertions(+), 141 deletions(-)
---
base-commit: 239f09e258b906deced5c2a7c1ac8aed301b558b
change-id: 20260128-can_skb_ext-0e7a99ed1984

Best regards,
-- 
Oliver Hartkopp <socketcan@hartkopp.net>

