From: Cedric Jehasse <cedric.jehasse@luminex.be>
Subject: [PATCH net-next v6 0/2] net: dsa: mv88e6xxx: Add partial support
 for TCAM entries
Date: Thu, 05 Mar 2026 10:56:53 +0100
Message-Id: <20260305-net-next-mv88e6xxx-tcam-v6-0-32c7fbac129d@luminex.be>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGVTqWkC/4XQzUrEQAwA4FdZ5uzIJJ2/9eR7iId2JuMO2K60d
 RhZ+u7Gglgp1UMOIckXkpuYaMw0iYfTTYxU8pSvAyf27iTCpR1eSObIuUCFViE0cqCZo86yL96
 TrbXKObS9TNZ0BFYpnzrB028jpVxX+Ul8D4lnrlzyNF/Hj3VlgbX+r15AglQGyBgkbFN4fH3vM
 3fed7SiBbeQO4aQoeh1SBpVbLXdQc0GQn0MNV9QAO+9iw4S7iC9hcwxpBkCcIl/Rxqi20HmB2r
 UHz8yUkmbzoBn6x2636cty/IJ4FI9se0BAAA=
X-Change-ID: 20260213-net-next-mv88e6xxx-tcam-f65be16008fb
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Russell King <linux@armlinux.org.uk>, Jamal Hadi Salim <jhs@mojatatu.com>, 
 Jiri Pirko <jiri@resnulli.us>, Simon Horman <horms@kernel.org>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Cedric Jehasse <cedric.jehasse@luminex.be>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772704628; l=3347;
 i=cedric.jehasse@luminex.be; s=20260213; h=from:subject:message-id;
 bh=ux8/oNIix2i6Qn3/+H5lFeTub559tZCZg8GAU/myr1k=;
 b=psihY2kPr2sl/ZpI0m1w90JCDhDcRIpXvDwdQ6/vxyWAcO3d9tlQvwAAgNRRTyPxg8SaWJl6J
 EWWL1Ty535oBlaJ2Ev/T6n+Cixa0IlRhDkU5TxcwMf3tFLpCX/yp8Rq
X-Developer-Key: i=cedric.jehasse@luminex.be; a=ed25519;
 pk=DL2RaHc2bc7tTDTMJdugm42BtJk4Ip+7V41Gkj+Avjk=
X-Endpoint-Received: by B4 Relay for cedric.jehasse@luminex.be/20260213 with auth_id=638
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds partial Ternary Content Addressable Memory (TCAM) for
the mv88e6390 and mv88e6393 family of switches. TCAM entries allow the
switch to match the first 48 or 96 bytes of a frame and take actions on
matched frames.

This patch introduces a subset of the available TCAM functionality.
Matching on ip addresses/protocol and trapping to the cpu.

Eg. to trap traffic with destination ip 224.0.1.129 to the cpu:

tc qdisc add dev p1 clsact
tc filter add dev p1 ingress protocol ip flower skip_sw \
    dst_ip 224.0.1.129 action trap

Review of the mv88e6xxx changes have brought to light something in
cls_flower:
When adding a classifier with an ipv4 address both
FLOW_DISSECTOR_KEY_IPV4_ADDRS and FLOW_DISSECTOR_KEY_IPV6_ADDRS bits are
set in dissector->used_keys.
A change was made to address this.

Signed-off-by: Cedric Jehasse <cedric.jehasse@luminex.be>
---
Changes in v6:
- add num_tcam_entries in chip info and check this is not exceeded when
  adding an entry
- fix use after free in error path of tcam entry deletion
- fix copy/paste mistake in comment
- Link to v5: https://lore.kernel.org/r/20260303-net-next-mv88e6xxx-tcam-v5-0-6f9129687276@luminex.be

Changes in v5:
- changes to cls_flower to only set the correct
  FLOW_DISSECTOR_KEY_IPV*_ADDRS bits
- Link to v4: https://lore.kernel.org/r/20260225-net-next-mv88e6xxx-tcam-v4-1-117f600e41d7@luminex.be

Changes in v4:
- return -ENOMEM on allocation failure
- fix double mv88e6xxx_reg_unlock
- return -EOPNOTSUPP for unsupported addr_type
- improve error handling in mv88e6xxx_tcam_entry_del
- Link to v3: https://lore.kernel.org/r/20260224-net-next-mv88e6xxx-tcam-v3-1-dc18887d71f2@luminex.be

Changes in v3:
- move locking to top level functions
- use defines for match field offsets
- use correct comment style
- remove warning used for debugging
- rename rc variables to err
- limit line length to 80 characters
- Link to v2: https://lore.kernel.org/r/20260217-net-next-mv88e6xxx-tcam-v2-1-d84cf420da46@luminex.be

Changes in RFC-v2:
- moved tcam_addr to chip info struct and remove tcam_support field
- added 6393-specific tcam ops that write the TCAM extension register
- rename the defines for TCAM registers to be consistent
- reverse christmas tree variable declarations
- Link to v1: https://lore.kernel.org/r/20260213-net-next-mv88e6xxx-tcam-v1-1-051e552e2afc@luminex.be

---
Cedric Jehasse (2):
      net/sched: cls_flower: remove unions from fl_flow_key
      net: dsa: mv88e6xxx: Add partial support for TCAM entries

 drivers/net/dsa/mv88e6xxx/Makefile   |   2 +
 drivers/net/dsa/mv88e6xxx/chip.c     |  34 ++++
 drivers/net/dsa/mv88e6xxx/chip.h     |  52 ++++++
 drivers/net/dsa/mv88e6xxx/port.c     |  27 ++-
 drivers/net/dsa/mv88e6xxx/port.h     |   7 +-
 drivers/net/dsa/mv88e6xxx/tcam.c     | 332 +++++++++++++++++++++++++++++++++++
 drivers/net/dsa/mv88e6xxx/tcam.h     |  41 +++++
 drivers/net/dsa/mv88e6xxx/tcflower.c | 157 +++++++++++++++++
 drivers/net/dsa/mv88e6xxx/tcflower.h |  13 ++
 net/sched/cls_flower.c               |  12 +-
 10 files changed, 667 insertions(+), 10 deletions(-)
---
base-commit: cd51b40495c09b92beea6893663b3d0ed7605e81
change-id: 20260213-net-next-mv88e6xxx-tcam-f65be16008fb

Best regards,
-- 
Cedric Jehasse <cedric.jehasse@luminex.be>

