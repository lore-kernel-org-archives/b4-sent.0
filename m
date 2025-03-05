From: Satish Kharat <satishkh@cisco.com>
Subject: [PATCH net-next v2 0/8] enic:enable 32, 64 byte cqes and get max
 rx/tx ring size from hw
Date: Tue, 04 Mar 2025 19:56:36 -0500
Message-Id: <20250304-enic_cleanup_and_ext_cq-v2-0-85804263dad8@cisco.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEShx2cC/3WNwQ6CMBBEf4Xs2Zq2iqAn/8OQhi6LbKIttpVgC
 P9ug2ePkzfzZoFIgSnCpVgg0MSRvctB7wrAoXV3EtzlDFrqUmpVC3KMBh/UuvdoWtcZmpPBl+g
 zPNXWdiQryOsxUM/zZr6BoyRcLkKTycAx+fDZLie18Z9dV3/tkxJS4EEd+3NZK23tFTmi36N/Q
 rOu6xd4r76syAAAAA==
X-Change-ID: 20250218-enic_cleanup_and_ext_cq-f21868bbde07
To: Christian Benvenuti <benve@cisco.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Satish Kharat <satishkh@cisco.com>, Nelson Escobar <neescoba@cisco.com>, 
 John Daley <johndale@cisco.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741136202; l=2463;
 i=satishkh@cisco.com; s=20250226; h=from:subject:message-id;
 bh=tIhOLNOlcINBx0UYhFOL+x8Q07QOhFjHXPWnR8anXHc=;
 b=BZwIfK2gawRr7sIDLP7RnxjDXPXKTC56P8ilZ8yA2qgJ0K6GIEknAIO+BcAeFHSv+uhsU1UT5
 SjBo+UGe2KEC0FrE6MxOGWW1kwoQ37c3tVoYxqtBI4LaAdg4U9VXgPi
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=lkxzORFYn5ejiy0kzcsfkpGoXZDcnHMc4n3YK7jJnJo=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/20250226 with auth_id=351
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series enables using the max rx and tx ring sizes read from hw.
For newer hw that can be up to 16k entries. This requires bigger
completion entries for rx queues. This series enables the use of the
32 and 64 byte completion queues entries for enic rx queues on
supported hw versions. This is in addition to the exiting (default)
16 byte rx cqes.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
Changes in v2:
- Added net-next to the subject line.
- Removed inlines from function defs in .c file.
- Fixed function local variable style issues.
- Added couple of helper functions to common code.
- Fixed checkpatch errors and warnings.
- Link to v1: https://lore.kernel.org/r/20250227-enic_cleanup_and_ext_cq-v1-0-c314f95812bb@cisco.com

---
Satish Kharat (8):
      enic: Move function from header file to c file
      enic: enic rq code reorg
      enic: enic rq extended cq defines
      enic: enable rq extended cq support
      enic : remove unused function cq_enet_wq_desc_dec
      enic : added enic_wq.c and enic_wq.h
      enic : cleanup of enic wq request completion path
      enic : get max rq & wq entries supported by hw, 16K queues

 drivers/net/ethernet/cisco/enic/Makefile       |   2 +-
 drivers/net/ethernet/cisco/enic/cq_desc.h      |  25 +--
 drivers/net/ethernet/cisco/enic/cq_enet_desc.h | 142 ++++++---------
 drivers/net/ethernet/cisco/enic/enic.h         |  13 ++
 drivers/net/ethernet/cisco/enic/enic_ethtool.c |  12 +-
 drivers/net/ethernet/cisco/enic/enic_main.c    |  69 ++-----
 drivers/net/ethernet/cisco/enic/enic_res.c     |  87 +++++++--
 drivers/net/ethernet/cisco/enic/enic_res.h     |  11 +-
 drivers/net/ethernet/cisco/enic/enic_rq.c      | 240 ++++++++++++++++++++++---
 drivers/net/ethernet/cisco/enic/enic_rq.h      |   6 +-
 drivers/net/ethernet/cisco/enic/enic_wq.c      | 117 ++++++++++++
 drivers/net/ethernet/cisco/enic/enic_wq.h      |   7 +
 drivers/net/ethernet/cisco/enic/vnic_cq.h      |  45 +----
 drivers/net/ethernet/cisco/enic/vnic_devcmd.h  |  19 ++
 drivers/net/ethernet/cisco/enic/vnic_enet.h    |   5 +
 drivers/net/ethernet/cisco/enic/vnic_rq.h      |   2 +-
 drivers/net/ethernet/cisco/enic/vnic_wq.h      |   2 +-
 17 files changed, 545 insertions(+), 259 deletions(-)
---
base-commit: de7a88b639d488607352a270ef2e052c4442b1b3
change-id: 20250218-enic_cleanup_and_ext_cq-f21868bbde07

Best regards,
-- 
Satish Kharat <satishkh@cisco.com>

