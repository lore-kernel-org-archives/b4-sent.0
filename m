From: Satish Kharat <satishkh@cisco.com>
Subject: [PATCH net-next v2 0/6] enic: SR-IOV V2 preparatory infrastructure
Date: Wed, 25 Mar 2026 22:18:58 -0700
Message-Id: <20260325-enic-sriov-v2-prep-v2-0-f72cf716ebfa@cisco.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMLBxGkC/22NwQrCMBBEf6Xs2ZUkrSKe/I/SQ91u7B5MShJCp
 eTfDcGjx5nHvDkgchCOcO8OCJwlinc1mFMHtM7uxShLzWCUuareDMhOCGMQnzEb3AJvaCxrnp/
 UL6ShDmtpZW/SERwndLwnmCpZJSYfPu0t68Z/4ss/cdaocLhZNRBrrYgeJJH8mfwbplLKFyWfT
 7a+AAAA
To: Satish Kharat <satishkh@cisco.com>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774502338; l=3312;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=RYIDhb40pciHyjxA9d9rEgw6W+Ol3a6na/ntr3tvrXU=;
 b=XcxxjsWLxIc6TY47kNkGFQ+RDeEC6m9O99JU5KavoK5gotZWar1R6/w/3lmho8acSpKkDEzY1
 2WlC3ShviH5B8uWS6l4T+Pel5ZGgORwzBMk8BWy1NIR2ySuH/IvhIjw
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is the first of four series adding SR-IOV V2 support to the enic
driver for Cisco VIC 14xx/15xx adapters.

The existing V1 SR-IOV implementation has VFs that interact directly
with the VIC firmware, leaving the PF driver with no visibility or
control over VF behavior. V2 introduces a PF-mediated model where VFs
communicate with the PF through a mailbox over a dedicated admin
channel. This brings enic in line with the standard Linux SR-IOV
model, enabling full PF management of VFs via ip link (MAC, VLAN,
link state, spoofchk, trust, and per-VF statistics).

This preparatory series adds detection and resource helper code with
no functional change to existing driver behavior:

  - Extend BAR resource discovery for admin channel resources
  - Register the V2 VF PCI device ID
  - Detect VF type (V1/V2/usNIC) from SR-IOV PCI capability
  - Make enic_dev_enable/disable ref-counted for shared use by data
    path and admin channel
  - Add type-aware resource allocation for admin WQ/RQ/CQ/INTR
  - Detect presence of admin channel resources at probe time

Tested on VIC 14xx and 15xx series adapters with V2 VFs under KVM
(sriov_numvfs, VF passthrough, ip link VF configuration, VF traffic).

Based in part on initial work by Christian Benvenuti.

To: Satish Kharat <satishkh@cisco.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>
To: David S. Miller <davem@davemloft.net>
To: Eric Dumazet <edumazet@google.com>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

Changes in v2:
- Add RES_TYPE_SRIOV_INTR to the has_admin_channel check in patch 6/6
- CC all netdev maintainers per cc_maintainers CI feedback
- Link to v1: https://lore.kernel.org/r/20260325-enic-sriov-v2-prep-v1-0-48f04ce110cc@cisco.com

---
Satish Kharat (6):
      enic: extend resource discovery for SR-IOV admin channel
      enic: add V2 SR-IOV VF device ID
      enic: detect SR-IOV VF type from PCI capability
      enic: make enic_dev_enable/disable ref-counted
      enic: add type-aware alloc for WQ, RQ, CQ and INTR resources
      enic: detect admin channel resources for SR-IOV

 drivers/net/ethernet/cisco/enic/enic.h          | 18 +++++++++++
 drivers/net/ethernet/cisco/enic/enic_dev.c      | 17 +++++++---
 drivers/net/ethernet/cisco/enic/enic_main.c     | 42 ++++++++++++++++++++++++-
 drivers/net/ethernet/cisco/enic/enic_res.c      | 11 +++++--
 drivers/net/ethernet/cisco/enic/vnic_cq.c       | 14 +++++++--
 drivers/net/ethernet/cisco/enic/vnic_cq.h       |  3 ++
 drivers/net/ethernet/cisco/enic/vnic_dev.c      | 10 ++++++
 drivers/net/ethernet/cisco/enic/vnic_intr.c     | 12 +++++--
 drivers/net/ethernet/cisco/enic/vnic_intr.h     |  2 ++
 drivers/net/ethernet/cisco/enic/vnic_resource.h |  4 +++
 drivers/net/ethernet/cisco/enic/vnic_rq.c       | 14 +++++++--
 drivers/net/ethernet/cisco/enic/vnic_rq.h       |  3 ++
 drivers/net/ethernet/cisco/enic/vnic_wq.c       | 14 +++++++--
 drivers/net/ethernet/cisco/enic/vnic_wq.h       |  3 ++
 14 files changed, 148 insertions(+), 19 deletions(-)
---
base-commit: b1c803d5c8167026791abfaed96fd3e6a1fcd750
change-id: 20260324-enic-sriov-v2-prep-2fe1eabc3dc1

Best regards,
-- 
Satish Kharat <satishkh@cisco.com>

