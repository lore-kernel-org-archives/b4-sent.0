From: Satish Kharat <satishkh@cisco.com>
Subject: [PATCH 0/8] enic:enable 32, 64 byte cqes and get max rx/tx ring
 size from hw
Date: Thu, 27 Feb 2025 19:30:43 -0500
Message-Id: <20250227-enic_cleanup_and_ext_cq-v1-0-c314f95812bb@cisco.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALMDwWcC/x2MUQqEMBDFriLzbaEW1hWvIlJq+1wHZNRWRRDvv
 sXPEJKbEiIjUVvcFHFy4kUyVGVBfnLyg+KQmYw2H22qRkHYWz/DybFaJ8Hi2q3f1Jhl3QxDgP5
 SrteIka/33PXP8wfd6BOGaQAAAA==
X-Change-ID: 20250218-enic_cleanup_and_ext_cq-f21868bbde07
To: Christian Benvenuti <benve@cisco.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Satish Kharat <satishkh@cisco.com>, Nelson Escobar <neescoba@cisco.com>, 
 John Daley <johndale@cisco.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740702696; l=2108;
 i=satishkh@cisco.com; s=20250226; h=from:subject:message-id;
 bh=PZwKPZNIwsktgfTRcNnaJkTyo3RuC268bylz7yQgfOg=;
 b=yXTfvSBP6ouKK/vCk+TWVcKFz+0RU/rWTHyrOcd+XmLM35vplEhXCZAtmN57zTtOTeWRnScLv
 Q6iADyGlfTaCwGwWh0oN+/HQJK8ToB8K3upPjVizE3TwlN+vcHh3vCE
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
 drivers/net/ethernet/cisco/enic/cq_enet_desc.h | 142 ++++++--------
 drivers/net/ethernet/cisco/enic/enic.h         |  13 ++
 drivers/net/ethernet/cisco/enic/enic_ethtool.c |  12 +-
 drivers/net/ethernet/cisco/enic/enic_main.c    |  69 +------
 drivers/net/ethernet/cisco/enic/enic_res.c     |  87 +++++++--
 drivers/net/ethernet/cisco/enic/enic_res.h     |  11 +-
 drivers/net/ethernet/cisco/enic/enic_rq.c      | 246 ++++++++++++++++++++++---
 drivers/net/ethernet/cisco/enic/enic_rq.h      |   6 +-
 drivers/net/ethernet/cisco/enic/enic_wq.c      | 121 ++++++++++++
 drivers/net/ethernet/cisco/enic/enic_wq.h      |   6 +
 drivers/net/ethernet/cisco/enic/vnic_cq.h      |  41 -----
 drivers/net/ethernet/cisco/enic/vnic_devcmd.h  |  19 ++
 drivers/net/ethernet/cisco/enic/vnic_enet.h    |   5 +
 drivers/net/ethernet/cisco/enic/vnic_rq.h      |   2 +-
 drivers/net/ethernet/cisco/enic/vnic_wq.h      |   2 +-
 17 files changed, 545 insertions(+), 264 deletions(-)
---
base-commit: de7a88b639d488607352a270ef2e052c4442b1b3
change-id: 20250218-enic_cleanup_and_ext_cq-f21868bbde07

Best regards,
-- 
Satish Kharat <satishkh@cisco.com>

