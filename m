From: Cedric Jehasse <cedric.jehasse@luminex.be>
Subject: [PATCH net-next v3 0/2] net: dsa: mv88e6xxx: add support for
 credit based shaper
Date: Wed, 27 May 2026 17:33:03 +0200
Message-Id: <20260527-net-next-mv88e6xxx-cbs-v3-0-2f387eb5ff63@luminex.be>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAK8OF2oC/3XNSw7CIBAG4KsY1mJgqEhdeQ/jAsbRktjWQCWYp
 neXkJjoootZ/PP4ZmaRgqfIjpuZBUo++nEoQW03DDs73In7a8kMBGjRKMEHmkrliffJGNI5Z44
 ucpAgpW7RWm1YOX4Guvlc4TP73rBLmXQ+TmN4149J1nnF9wBreJJccDQHW3oOUeDp8ep9Wdw5q
 maCX0evOlAcqcg1LULrjPpzlmX5AOQfbJEPAQAA
X-Change-ID: 20260430-net-next-mv88e6xxx-cbs-2121169caa68
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Luke Howard <lukeh@padl.com>, 
 =?utf-8?q?Marek_Beh=C3=BAn?= <kabel@kernel.org>, 
 Cedric Jehasse <cedric.jehasse@gmail.com>, 
 Cedric Jehasse <cedric.jehasse@luminex.be>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779895985; l=2237;
 i=cedric.jehasse@luminex.be; s=20260213; h=from:subject:message-id;
 bh=O50bUWCUlEAX65YFS4bgnEKO/t542CcWepe9YlMR7/Q=;
 b=xb+ME6nTeycVy+QX18jeCv4B4F7HiP7nItW2st3c7WW/D5AiteKZTqvnGlBNiUIt2nFFKgMJ4
 0RYogS+naQVBWvVsjQoV/6BL69KdbSYluS31cEE5rQE8zdUaPxJg5zz
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
Changes in v3:
- clear cbs_active_queues bit when the rate is set to 0 on
  port_set_scheduling_mode failure
- wait for the MV88E6390_PORT_QUEUE_CTL_UPDATE bit to be cleared after
  writing the scheduling mode
- add num_tx_queues for mv88e6191 based on it's family, as nobody is
  able to find a datasheet for this device
- reverse christmas tree variable declarations
- fix egress queue selection for devices with 4 queues
- Link to v2: https://lore.kernel.org/r/20260526-net-next-mv88e6xxx-cbs-v2-0-13eb49c29b83@luminex.be

Changes in v2:
- tx_queues defined for all devices (which could be found). Thanks to Marek Behún.
- Link to v1: https://lore.kernel.org/r/20260522-net-next-mv88e6xxx-cbs-v1-0-c87a8e6bcc0c@luminex.be

---
Cedric Jehasse (2):
      net: dsa: mv88e6xxx: use the hw tx queues
      net: dsa: mv88e6xxx: add support for credit based shaper

 drivers/net/dsa/mv88e6xxx/chip.c        | 161 ++++++++++++++++++++++++++++++++
 drivers/net/dsa/mv88e6xxx/chip.h        |  22 +++++
 drivers/net/dsa/mv88e6xxx/global2_avb.c |  21 +++++
 drivers/net/dsa/mv88e6xxx/port.c        |  45 +++++++++
 drivers/net/dsa/mv88e6xxx/port.h        |  16 ++++
 net/dsa/tag_dsa.c                       |  11 ++-
 6 files changed, 275 insertions(+), 1 deletion(-)
---
base-commit: 022bdd9c0d036863c4bacd1688b73c6be3001cee
change-id: 20260430-net-next-mv88e6xxx-cbs-2121169caa68

Best regards,
-- 
Cedric Jehasse <cedric.jehasse@luminex.be>

