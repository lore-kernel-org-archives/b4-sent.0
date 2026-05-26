From: Cedric Jehasse <cedric.jehasse@luminex.be>
Subject: [PATCH net-next v2 0/2] net: dsa: mv88e6xxx: add support for
 credit based shaper
Date: Tue, 26 May 2026 13:41:13 +0200
Message-Id: <20260526-net-next-mv88e6xxx-cbs-v2-0-13eb49c29b83@luminex.be>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIANmGFWoC/3WNsQ7CMAxEf6XyjFFiIAQm/gN1SIOhlmiLkhIFV
 f13okiMDDfcne95gchBOMK5WSBwkijTWAxtGvC9Gx+MciseSJFR+53CkeeiPOOQrGWTc0bfRSR
 NWpuTd85YKONX4LvkCr7CbwNtaXqJ8xQ+9WPSta/wA9E/eNKo0NujK1nnvfKX53uQcrjtGNp1X
 b+8S8XUxwAAAA==
X-Change-ID: 20260430-net-next-mv88e6xxx-cbs-2121169caa68
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Cedric Jehasse <cedric.jehasse@luminex.be>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779795677; l=1698;
 i=cedric.jehasse@luminex.be; s=20260213; h=from:subject:message-id;
 bh=gsBMOqckNew79nqSk38co9T/p1xGYyM8joscT6dFzlw=;
 b=9Z/Kxlm4nnbXY7ex5AR29/rzFU9jQ7Uq1ABUsumK8TzhsfrgCrnQs7o4f2CB3lkxan6sdTM9q
 baYQHU2hDGTAsFBHcK+evUAh/yeTtPFBmK/jhkh98DIjLL9TmHNY+RP
X-Developer-Key: i=cedric.jehasse@luminex.be; a=ed25519;
 pk=DL2RaHc2bc7tTDTMJdugm42BtJk4Ip+7V41Gkj+Avjk=
X-Endpoint-Received: by B4 Relay for cedric.jehasse@luminex.be/20260213 with auth_id=638
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several of the switch families in this driver have switches with AVB
support. The switches with AVB support have support for Credit based
shaping. This series adds support for the 6352, 6390 and 6393 families.
The difference between the families is:
- total number of queues
- which queues support credit based shaping
- shaping granularity

Eg. setting up 20mbps credit based shaper on a 1GBit link:
tc qdisc add dev p8 parent root handle 100: mqprio \
    num_tc 8 \
    map 0 0 6 7 0 5 0 0 0 0 0 0 0 0 0 0 \
    queues 1@0 1@1 1@2 1@3 1@4 1@5 1@6 1@7 \
    hw 0

tc qdisc replace dev p8 parent 100:8 cbs locredit -1470 hicredit 30 \
    sendslope -980000 idleslope 20000 offload 1

Signed-off-by: Cedric Jehasse <cedric.jehasse@luminex.be>
---
Changes in v2:
- tx_queues defined for all devices (which could be found). Thanks to Marek Behún.
- Link to v1: https://lore.kernel.org/r/20260522-net-next-mv88e6xxx-cbs-v1-0-c87a8e6bcc0c@luminex.be

---
Cedric Jehasse (2):
      net: dsa: mv88e6xxx: use the hw tx queues
      net: dsa: mv88e6xxx: add support for credit based shaper

 drivers/net/dsa/mv88e6xxx/chip.c        | 157 ++++++++++++++++++++++++++++++++
 drivers/net/dsa/mv88e6xxx/chip.h        |  22 +++++
 drivers/net/dsa/mv88e6xxx/global2_avb.c |  21 +++++
 drivers/net/dsa/mv88e6xxx/port.c        |  38 ++++++++
 drivers/net/dsa/mv88e6xxx/port.h        |  16 ++++
 net/dsa/tag_dsa.c                       |   3 +-
 6 files changed, 256 insertions(+), 1 deletion(-)
---
base-commit: 022bdd9c0d036863c4bacd1688b73c6be3001cee
change-id: 20260430-net-next-mv88e6xxx-cbs-2121169caa68

Best regards,
-- 
Cedric Jehasse <cedric.jehasse@luminex.be>

