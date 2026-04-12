From: Satish Kharat <satishkh@cisco.com>
Subject: [PATCH net-next v4 00/10] enic: SR-IOV V2 admin channel and MBOX
 protocol
Date: Sat, 11 Apr 2026 22:06:26 -0700
Message-Id: <20260411-enic-sriov-v2-admin-channel-v2-v4-0-f052326c2a57@cisco.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFIo22kC/5XNwWoCMRAG4FeRnJ2SzaQx21PfQzyEyVgHNJFkC
 Suy725cepBepMd//uH776pyEa7qa3NXhZtUyakHu90oOoX0wyCxZ2W0cdpqC5yEoBbJDZqBEC+
 S4PmZ+Pw8kA4BefTeI6qOXAsfZV4H9irxBInnSR16c5I65XJbl9uw9r8j7t1IG0CDN0R259CFn
 f8mqZQ/KF9WuplXzr/lTOei/owRncFjxL8c/o/Dzg3RjuMYNBLTK7csywPkCtecdAEAAA==
X-Change-ID: 20260404-enic-sriov-v2-admin-channel-v2-c0aa3e988833
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 20260401-enic-sriov-v2-prep-v4-0-d5834b2ef1b9@cisco.com, 
 Satish Kharat <satishkh@cisco.com>, Breno Leitao <leitao@debian.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775970405; l=3459;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=8Y2cZHnHRd+OEA7oYKlo8NGbDuhH+knxvBJlguRu5bQ=;
 b=/Ckf+/pjk3IPrswfG34RP05j3N9Jt6ehbbmOVftxYvCl4g9toXU4nTpc4/oVV0Lnu+8aGUlUG
 60RYVHdmOGTA/KMXrga2XyoVsg+U2xx3mL9BFWw3PkKtmv2h7CGRppn
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds the admin channel infrastructure and mailbox (MBOX)
protocol needed for V2 SR-IOV support in the enic driver.

The V2 SR-IOV design uses a direct PF-VF communication channel built on
dedicated WQ/RQ/CQ hardware resources and an MSI-X interrupt.

Firmware capability and admin channel infrastructure (patches 1-4):
  - Probe-time firmware feature check for V2 SR-IOV support
  - Admin channel open/close, RQ buffer management, CQ service
    with MSI-X interrupt and NAPI polling

MBOX protocol and VF enable (patches 5-10):
  - MBOX message types, core send/receive, PF and VF handlers
  - V2 SR-IOV enable wiring with admin channel setup
  - V2 VF probe with admin channel and PF registration

This series depends on "enic: SR-IOV V2 resource discovery and VF
type detection" (Series 1), which has been accepted.

Depends-on: 20260401-enic-sriov-v2-prep-v4-0-d5834b2ef1b9@cisco.com

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
Changes in v4:
- Fix reverse xmas tree variable ordering (patches 1, 6)
- Use kzalloc_obj instead of kzalloc with sizeof (patch 9)
- Add NULL check for pp allocation in V1 SR-IOV disable path (patch 9)
- Link to v3: https://lore.kernel.org/r/20260408-enic-sriov-v2-admin-channel-v2-v3-0-1d4999a03cec@cisco.com

Changes in v3:
- Use early-return pattern in enic_sriov_detect_vf_type to reduce
  nesting (patch 1) [Breno Leitao]
- Link to v2: https://lore.kernel.org/r/20260408-enic-sriov-v2-admin-channel-v2-v2-0-d05dd3623fd3@cisco.com

Changes in v2:
- Fix lines exceeding 80 columns (patches 4, 6, 7, 8)
- Add __maybe_unused to enic_sriov_configure and enic_sriov_v2_enable;
  .sriov_configure wiring deferred to a later series after devcmd
  hardening is in place (patch 9)
- Guard probe-time auto-enable to skip V2 VFs (patch 9)
- Link to v1: https://lore.kernel.org/r/20260406-enic-sriov-v2-admin-channel-v2-v1-0-82cc47636a78@cisco.com

---
Satish Kharat (10):
      enic: verify firmware supports V2 SR-IOV at probe time
      enic: add admin channel open and close for SR-IOV
      enic: add admin RQ buffer management
      enic: add admin CQ service with MSI-X interrupt and NAPI polling
      enic: define MBOX message types and header structures
      enic: add MBOX core send and receive for admin channel
      enic: add MBOX PF handlers for VF register and capability
      enic: add MBOX VF handlers for capability, register and link state
      enic: wire V2 SR-IOV enable with admin channel and MBOX
      enic: add V2 VF probe with admin channel and PF registration

 drivers/net/ethernet/cisco/enic/Makefile      |   3 +-
 drivers/net/ethernet/cisco/enic/enic.h        |  29 +-
 drivers/net/ethernet/cisco/enic/enic_admin.c  | 511 ++++++++++++++++++++++++
 drivers/net/ethernet/cisco/enic/enic_admin.h  |  27 ++
 drivers/net/ethernet/cisco/enic/enic_main.c   | 218 +++++++++-
 drivers/net/ethernet/cisco/enic/enic_mbox.c   | 546 ++++++++++++++++++++++++++
 drivers/net/ethernet/cisco/enic/enic_mbox.h   |  87 ++++
 drivers/net/ethernet/cisco/enic/enic_res.c    |   4 +-
 drivers/net/ethernet/cisco/enic/vnic_devcmd.h |  11 +
 drivers/net/ethernet/cisco/enic/vnic_enet.h   |   4 +-
 10 files changed, 1425 insertions(+), 15 deletions(-)
---
base-commit: 3e6ef4fb822c971b464d44910a1561b4e7f9efa7
change-id: 20260404-enic-sriov-v2-admin-channel-v2-c0aa3e988833

Best regards,
--  
Satish Kharat <satishkh@cisco.com>

