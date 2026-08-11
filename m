From: Cedric Jehasse <cedric.jehasse@luminex.be>
Subject: [PATCH net-next v8 0/3] net: dsa: mv88e6xxx: add support for
 credit based shaper
Date: Tue, 11 Aug 2026 13:45:46 +0200
Message-Id: <20260811-net-next-mv88e6xxx-cbs-v8-0-10d0baab2905@luminex.be>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAGoLe2oC/3XQzW7DIAwA4FepOI8JDBjYae9R9RD+VqQ1nZIsy
 lTl3edFmpYp4sDBGH+2ebAxDzWP7OX0YEOe61jvPQXu6cTitevfMq+JYgYCUGgleJ8nOsvEb7N
 zGZdl4TGMHCRIiT52HTpGxR9DLnXZ4DP7rWEXylzrON2Hr63jLLf8hhuAFj5LLnh0tqO7EKOIr
 ++ft0oPn0PezBn2DjYdIEeqHLSP4INTB0ftHdt0FDlQlLM5mFLw6Oi945qOJseFJFXwArWxB8f
 8OSja/2N+9vLorXFJlu44D+4d3XSQnIAuCik1JJkPjt07vulYcmwyySpIxWjzz1nX9RuMU+3Hd
 wIAAA==
X-Change-ID: 20260430-net-next-mv88e6xxx-cbs-2121169caa68
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Russell King <linux@armlinux.org.uk>, 
 Jamal Hadi Salim <jhs@mojatatu.com>, Jiri Pirko <jiri@resnulli.us>, 
 Vinicius Costa Gomes <vinicius.gomes@intel.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Luke Howard <lukeh@padl.com>, 
 =?utf-8?q?Marek_Beh=C3=BAn?= <kabel@kernel.org>, 
 Cedric Jehasse <cedric.jehasse@gmail.com>, 
 Cedric Jehasse <cedric.jehasse@luminex.be>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786448754; l=3858;
 i=cedric.jehasse@luminex.be; s=20260213; h=from:subject:message-id;
 bh=B4bQSI2L9KrzAEcIP4HLvbYVCODqikvBn0mglsjGQz8=;
 b=VNW0VLwrPxfkUJfWVb77qtkSsp2u1/vd8HHA/ch5X149QN0na8Y/jElM9fRcG7A94dqUtOWC3
 8LsTmCKX0K9C5KOpsPPB2FzK8QnTgg6MtCSA0Z0Sz9WLUCh0Blz3WZa
X-Developer-Key: i=cedric.jehasse@luminex.be; a=ed25519;
 pk=DL2RaHc2bc7tTDTMJdugm42BtJk4Ip+7V41Gkj+Avjk=
X-Endpoint-Received: by B4 Relay for cedric.jehasse@luminex.be/20260213 with auth_id=638
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several of the switch families in this driver have switches with AVB
support. The switches with AVB support have support for Credit based
shaping. This series adds support for the 6341, 6352, 6390 and 6393
families.
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
Changes in v8:
- add an extack into tc_cbs_qopt_offload and use it to report the reason
  for rejection back to the user (Jakub)
- Link to v7: https://lore.kernel.org/r/20260609-net-next-mv88e6xxx-cbs-v7-0-7d5d732df545@luminex.be

Changes in v7:
- fix incorrect hilimit_mask for the 6341
- remove dead code in rollback (clearing a bit in cbs_active_queue which
  is already 0)
- fix typo in commit message
- Link to v6: https://lore.kernel.org/r/20260604-net-next-mv88e6xxx-cbs-v6-0-b68c01142d1e@luminex.be

Changes in v6:
- consitently use hilimit naming isof a mixing hilimit and hi_limit
- Link to v5: https://lore.kernel.org/r/20260602-net-next-mv88e6xxx-cbs-v5-0-1969758d1fa3@luminex.be

Changes in v5:
- only set the scheduling mode when no queues are active
- use u32 for rate calculation to avoid truncation
- Link to v4: https://lore.kernel.org/r/20260528-net-next-mv88e6xxx-cbs-v4-0-8bd13b906457@luminex.be

Changes in v4:
- add qav info for the 6341
- remove max_rate from mv88e6xxx_qav_info. It looks like the max rate
  mentioned in the docs is just the maximum rate that fits in the
  registers. This is already represented by rate_mask.
- remove validation on sendslope. This isn't used by the driver.
- use accessors for qav_write and set_scheduling
- Link to v3: https://lore.kernel.org/r/20260527-net-next-mv88e6xxx-cbs-v3-0-2f387eb5ff63@luminex.be

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
Cedric Jehasse (3):
      net/sched: cbs: add extack to struct tc_cbs_qopt_offload
      net: dsa: mv88e6xxx: use the hw tx queues
      net: dsa: mv88e6xxx: add support for credit based shaper

 drivers/net/dsa/mv88e6xxx/chip.c        | 176 ++++++++++++++++++++++++++++++++
 drivers/net/dsa/mv88e6xxx/chip.h        |  21 ++++
 drivers/net/dsa/mv88e6xxx/global2.h     |   3 +
 drivers/net/dsa/mv88e6xxx/global2_avb.c |  21 ++++
 drivers/net/dsa/mv88e6xxx/port.c        |  63 ++++++++++++
 drivers/net/dsa/mv88e6xxx/port.h        |  20 ++++
 include/net/pkt_sched.h                 |   1 +
 net/dsa/tag_dsa.c                       |  11 +-
 net/sched/sch_cbs.c                     |   4 +-
 9 files changed, 318 insertions(+), 2 deletions(-)
---
base-commit: 4e8f1e2c1e3b95fc86754e40c43d8483e01ff806
change-id: 20260430-net-next-mv88e6xxx-cbs-2121169caa68

Best regards,
-- 
Cedric Jehasse <cedric.jehasse@luminex.be>

