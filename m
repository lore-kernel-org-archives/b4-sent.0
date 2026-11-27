From: Ricardo Pardini <ricardo@pardini.net>
Subject: [PATCH v2 0/4] rockchip: fix on-board SATA on RK3588 and RK356x
Date: Fri, 27 Nov 2026 14:12:57 +0100
Message-Id: <20261127-rk3588-sata-fixes-v2027-01-v2-0-dbdf7770972a@pardini.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANqBCWsC/32NzQ6CMBAGX4X07Jpu+bF48j0MhwKLrCaFtLXRE
 N7dAnePk539ZhGeHJMX12wRjiJ7nmwCdcpENxr7IOA+sVBSVShVAe6Vl1qDN8HAwB/yENPtAhJ
 B16odUJq8RCXSwOxoN9L/vTnYv9sndWFb3IyRfZjcd69H3LwjhLL+F4oIEqgsOqOp0gPq22xcz
 5bPloJo1nX9AdPQxWzYAAAA
X-Change-ID: 20261024-rk3588-sata-fixes-v2027-01-892bf10a3512
To: u-boot@lists.u-boot-project.org, Simon Glass <sjg@chromium.org>, 
 Kever Yang <kever.yang@rock-chips.com>, Eugen Hristev <ehristev@kernel.org>, 
 Jon Lin <jon.lin@rock-chips.com>
Cc: Tom Rini <trini@konsulko.com>, Peng Fan <peng.fan@nxp.com>, 
 Ricardo Pardini <ricardo@pardini.net>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Heiko Stuebner <heiko@sntech.de>, Julius Lehmann <lehmanju@devpi.de>, 
 Yifeng Zhao <yifeng.zhao@rock-chips.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3009; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=DTCo8lpu7MajxLVaWrDtdaiCkp3xKbvJsTY1bbfUMJg=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBrCYIZOIH1R92sqFQBsRn+vi0qly7E7kBXh/C7G
 gBAum6PI2KJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCawmCGQAKCRA7Xj/jnsft
 6WNDCACiX5V0RvoeuCyyiPWH7VSMlx5boJhhVNgrEIeCLYqRwGehHHRh2v24wAQ9G4NyYjdd1WV
 R7AXby9nCd1UPdwdJSaNnJcjCIxGE+E10IVwMswIGo30Sj3cvo9YCh4f4TsnSW2d8qCLeYbBjC0
 nLty4GLiKcqpa8q17zWQPXQoctbFQ6+aRcqjoF94YWGfzl2MWEhTW1AKo/A0mh9BvzBPHpIsgIX
 DfEhbgOvWufrbzaH4dyFweXlOy0GCF82PqUcNztEN2cW7MqHo0NuAMdJpmcTIkZKdTjRbJDpI2j
 uz+yLLWVJOUAewAM97zkffGGwrtW5CHTjF5NPMgaEBZGjLNK
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This makes the on-board SATA controllers (dwc_ahci) work on RK3588,
and on RK356x sata1/sata2 again. They currently fail to probe, and
fixing that exposes two more problems once a disk is actually used:

A: dwc_ahci only looks for the PHY on the controller node, but the
   RK3588 DT has it in the sata-port@0 subnode, so probe always fails.
   RK356x sata1/sata2 have the same problem since the v7.1 DT sync.
   The PHY is now found like Linux's libahci_platform does it: the
   first PHY, ignoring phy-names (1/4), of the sata-port subnodes if
   any, else of the controller (2/4). The binding allows one PHY per
   node and phy-names is optional, so RK3576, RK3568 sata0 and TI DRA7
   get the same PHY as before.
B: AHCI reports disks one sector too large since the scsi +1 fix [1],
   which breaks e.g. UMS when the host reads the backup GPT.
C: sata2 links at 1.5 Gb/s only, due to a wrong GRF offset (see the
   RK3588 TRM); Rockchip fixed it in their BSP kernel [2], and the
   same fix was sent for Linux [3].

The misplaced write in (C) lands in PHP_GRF_PHP_CON0[2:0], which are
the PCIe link reset grant bits, and turns on the one for pcie3x2
whenever a combphy is put in SATA mode. I don't know of any effect
from that, but this series stops it too.

Tested with an mSATA SSD on sata2 (combphy2_psu): scsi scan, booting
via bootstd, and UMS all work, with the link at 6 Gb/s. Only tested
on RK3588.

[1] https://lore.kernel.org/u-boot/20241026-fix-scsi-disksize-v2-1-bc6be9a6043d@devpi.de/
[2] https://github.com/rockchip-linux/kernel/commit/2f5fe2c0bbd4fa95102aadd60da1100989103aa0
[3] https://patch.msgid.link/20261109-rk3588-combphy-sata2-6g-v1-1-e9135c91de6a@pardini.net

---
Changes in v2:
- v1 1/3 split in two, getting the PHY the same way as Linux's
  libahci_platform (Quentin):
  - 1/4: always the first PHY, ignoring phy-names
  - 2/4: only from the sata-port subnodes if there are any, else from
    the controller node; stop at the first enabled subnode; replaces
    v1's "ata: dwc_ahci: fall back to the PHY in the sata-port subnode"
- 3/4, 4/4 (were 2/3, 3/3): collect Quentin's Reviewed-by
- Link to v1: https://patch.msgid.link/20261109-rk3588-sata-fixes-v2027-01-v1-0-e54ca8e68f18@pardini.net

---
Ricardo Pardini (4):
      ata: dwc_ahci: use the first PHY, ignoring phy-names
      ata: dwc_ahci: get the PHY from the sata-port subnodes if any
      ata: ahci: return the last LBA from emulated READ CAPACITY
      phy: rockchip: naneng-combphy: fix RK3588 SATA pipe_con1 register offset

 drivers/ata/ahci.c                                 |  8 +++++---
 drivers/ata/dwc_ahci.c                             | 16 ++++++++++++++--
 drivers/phy/rockchip/phy-rockchip-naneng-combphy.c |  2 +-
 3 files changed, 20 insertions(+), 6 deletions(-)
---
base-commit: 934995f642a21ca7f35fa9aed5f061394fcba243
change-id: 20261024-rk3588-sata-fixes-v2027-01-892bf10a3512

Best regards,
--  
Ricardo Pardini <ricardo@pardini.net>

