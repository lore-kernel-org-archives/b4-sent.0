From: Ricardo Pardini <ricardo@pardini.net>
Subject: [PATCH 0/3] rockchip: fix on-board SATA on RK3588 and RK356x
Date: Mon, 09 Nov 2026 03:57:57 +0100
Message-Id: <20261109-rk3588-sata-fixes-v2027-01-v1-0-e54ca8e68f18@pardini.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALU28WoC/yWMQQ6CQAxFr0K6tsm0iI5ehbAYoGg1QTMFYkK4u
 1WWL/+/t4JJVjG4FitkWdT0NTrQoYDunsaboPbOwIFPFPiI+VlWMaKlKeGgHzFcfDtjIIwXbgc
 KqayIwQPvLP+H+3Wzs83tQ7rpV4Rt+wJDovkDfgAAAA==
X-Change-ID: 20261024-rk3588-sata-fixes-v2027-01-892bf10a3512
To: u-boot@lists.u-boot-project.org, Simon Glass <sjg@chromium.org>, 
 Kever Yang <kever.yang@rock-chips.com>, Eugen Hristev <ehristev@kernel.org>, 
 Jon Lin <jon.lin@rock-chips.com>
Cc: Tom Rini <trini@konsulko.com>, Peng Fan <peng.fan@nxp.com>, 
 Ricardo Pardini <ricardo@pardini.net>, Quentin Schulz <u-boot@0leil.net>, 
 Jonas Karlman <jonas@kwiboo.se>, Heiko Stuebner <heiko@sntech.de>, 
 Julius Lehmann <lehmanju@devpi.de>, 
 Yifeng Zhao <yifeng.zhao@rock-chips.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2061; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=MSfvXvaN1DR4S2bn3IrJreOSPijm7cdZ9zFFwCNgR60=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq8Ta2q0Xm/pIA8t68QYybo2hckYSbZ0NrqqZJw
 RHcq9yYhaCJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCavE2tgAKCRA7Xj/jnsft
 6YJIB/9TbhQ9TqHz9M0RL3b3FE+d+URlHBnkIfgn/NifOmDW93f9gTQH44RKVNDfziXpxClw+uA
 QmmZKaeijQnrdBvcyhAWt8adpjphfnticNx4bSYDd5TezVvrRH15QfMXS9ZQMFkesaYvvFubCa3
 sv0MDVZQFfo+CYEj5Qj2Lcgn2Sote5dERN/np9g+2IdRxQL2sns6GBC52sKW7IrmqZTY7pNR5mL
 Hz/I3F/mi2Moyd3HtsrRjWlJFLEaR1TXu/FUrXApNoO9eF/G5r0OGPwxXkln2/knImVfMQP0r3T
 nw8BcDmKzWECrG/SlHXR2g1H+8e9vCLyPBfFzgmNqK7YIie3
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This makes the on-board SATA controllers (dwc_ahci) work on RK3588,
and on RK356x sata1/sata2 again. They currently fail to probe, and
fixing that exposes two more problems once a disk is actually used:

1: dwc_ahci only looks for the PHY on the controller node, but the
   RK3588 DT has it in the sata-port@0 subnode, so probe always fails.
   RK356x sata1/sata2 have the same problem since the v7.1 DT sync.
2: AHCI reports disks one sector too large since the scsi +1 fix [1],
   which breaks e.g. UMS when the host reads the backup GPT.
3: sata2 links at 1.5 Gb/s only, due to a wrong GRF offset (see the
   RK3588 TRM); Rockchip fixed it in their BSP kernel [2], and the
   same fix was sent for Linux [3].

The misplaced write in (3) lands in PHP_GRF_PHP_CON0[2:0], which are
the PCIe link reset grant bits, and turns on the one for pcie3x2
whenever a combphy is put in SATA mode. I don't know of any effect
from that, but this series stops it too.

Tested with an mSATA SSD on sata2 (combphy2_psu): scsi scan, booting
via bootstd, and UMS all work, with the link at 6 Gb/s.

[1] https://lore.kernel.org/u-boot/20241026-fix-scsi-disksize-v2-1-bc6be9a6043d@devpi.de/
[2] https://github.com/rockchip-linux/kernel/commit/2f5fe2c0bbd4fa95102aadd60da1100989103aa0
[3] https://patch.msgid.link/20261109-rk3588-combphy-sata2-6g-v1-1-e9135c91de6a@pardini.net

---
Ricardo Pardini (3):
      ata: dwc_ahci: fall back to the PHY in the sata-port subnode
      ata: ahci: return the last LBA from emulated READ CAPACITY
      phy: rockchip: naneng-combphy: fix RK3588 SATA pipe_con1 register offset

 drivers/ata/ahci.c                                 |  8 +++++---
 drivers/ata/dwc_ahci.c                             | 13 +++++++++++++
 drivers/phy/rockchip/phy-rockchip-naneng-combphy.c |  2 +-
 3 files changed, 19 insertions(+), 4 deletions(-)
---
base-commit: 934995f642a21ca7f35fa9aed5f061394fcba243
change-id: 20261024-rk3588-sata-fixes-v2027-01-892bf10a3512

Best regards,
--  
Ricardo Pardini <ricardo@pardini.net>

