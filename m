From: Jack Wu <jackbb_wu@compal.com>
Subject: [PATCH 00/11] net: wwan: t9xx: Add MediaTek T9XX WWAN driver
Date: Fri, 29 May 2026 18:31:39 +0800
Message-Id: <20260529-t9xx_driver_v1-v1-0-bdbfe2c01e57@compal.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAtrGWoC/yXMzQ5FMBBA4VeRWWui5eqtVxERP1N3LJApTRPx7
 upafotzTnDIhA6q5ARGT47WJUKmCQy/bplQ0BgNKlNl9lFG7CaEdmTyyK2XQuqisN/Oap0biNH
 GaCn8h3Xz2h39jMP+XOC6bhLEN+pyAAAA
X-Change-ID: 20260529-t9xx_driver_v1-1744f8af7739
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Sergey Ryazanov <ryazanov.s.a@gmail.com>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Jack Wu <jackbb_wu@compal.com>, Wen-Zhi Huang <wen-zhi.huang@mediatek.com>, 
 Shi-Wei Yeh <shi-wei.yeh@mediatek.com>, 
 Minano Tseng <Minano.tseng@mediatek.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-doc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780050704; l=5835;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=Uhk5W8Tuq0902LMgAiqFtam6oLO/82rfu4jgFWKW+a4=;
 b=iqDg+vLGU+X657DStNqZFEAiE7d5rUDTD53nG4CwrDrNfZblbPjZ6fRCVURu6Td8HZy528uDB
 is4E2j+pLqCCnmsI5MFSEce3CnWGORvwT0Hv25O2YwiwvQQ/YwYYvHj
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

T9XX is the PCIe host device driver for MediaTek's
t900 modem. The driver uses the WWAN framework
infrastructure to create the following control ports
and network interfaces for data transactions.
* /dev/wwan0at0 - Interface that supports AT commands.
* /dev/wwan0mbim0 - Interface conforming to the MBIM
  protocol.
* wwan0-X - Primary network interface for IP traffic.

The main blocks in the T9XX driver are:
* HW layer - Abstracts the hardware bus operations for
   the device, and provides generic interfaces for the
   transaction layer to get the device's information and
   control the device's behavior. It includes:

   * PCIe - Implements probe, removal and interrupt
     handling.
   * MHCCIF (Modem Host Cross-Core Interface) - Provides
     interrupt channels for bidirectional event
     notification such as handshake and port enumeration.

* Transaction layer - Implements data transactions for
   the control plane and the data plane. It includes:

   * DPMAIF (Data Plane Modem AP Interface) - Controls
     the hardware that provides uplink and downlink
     queues for the data path. The data exchange takes
     place using circular buffers to share data buffer
     addresses and metadata to describe the packets.
   * CLDMA (Cross Layer DMA) - Manages the hardware
     used by the port layer to send control messages to
     the device using MediaTek's CCCI (Cross-Core
     Communication Interface) protocol.
   * TX Services - Dispatch packets from the port layer
     to the device.
   * RX Services - Dispatch packets to the port layer
     when receiving packets from the device.

* Port layer - Provides control plane and data plane
   interfaces to userspace. It includes:

   * Control Plane - Provides device node interfaces
     for controlling data transactions.
   * Data Plane - Provides network link interfaces
     wwanX (0, 1, 2...) for IP data transactions.

* Core logic - Contains the core logic to keep the
   device working. It includes:

   * FSM (Finite State Machine) - Monitors the state
     of the device, and notifies each module when the
     state changes.

The compilation of the T9XX driver is enabled by the
CONFIG_MTK_T9XX and CONFIG_MTK_T9XX_PCI config option
which depends on CONFIG_WWAN.

---
Jack Wu (11):
      net: wwan: t9xx: Add PCIe core
      net: wwan: t9xx: Add control plane transaction layer
      net: wwan: t9xx: Add control DMA interface
      net: wwan: t9xx: Add control port
      net: wwan: t9xx: Add FSM thread
      net: wwan: t9xx: Add AT & MBIM WWAN ports
      net: wwan: t9xx: Introduce data plane hardware
      net: wwan: t9xx: Add data plane transaction layer
      net: wwan: t9xx: Introduce WWAN interface
      net: wwan: t9xx: Add power management support
      net: wwan: t9xx: Add maintainers and documentation

 .../networking/device_drivers/wwan/t9xx.rst        |   48 +
 MAINTAINERS                                        |   10 +
 drivers/net/wwan/Kconfig                           |   17 +
 drivers/net/wwan/Makefile                          |    1 +
 drivers/net/wwan/t9xx/Makefile                     |   16 +
 drivers/net/wwan/t9xx/mtk_ctrl_plane.c             |   95 +
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h             |   88 +
 drivers/net/wwan/t9xx/mtk_data_plane.c             |  104 +
 drivers/net/wwan/t9xx/mtk_data_plane.h             |  105 +
 drivers/net/wwan/t9xx/mtk_dev.c                    |   55 +
 drivers/net/wwan/t9xx/mtk_dev.h                    |  114 +
 drivers/net/wwan/t9xx/mtk_fsm.c                    |  931 +++++++
 drivers/net/wwan/t9xx/mtk_fsm.h                    |  140 +
 drivers/net/wwan/t9xx/mtk_port.c                   |  967 +++++++
 drivers/net/wwan/t9xx/mtk_port.h                   |  176 ++
 drivers/net/wwan/t9xx/mtk_port_io.c                |  576 +++++
 drivers/net/wwan/t9xx/mtk_port_io.h                |   41 +
 drivers/net/wwan/t9xx/mtk_utility.h                |   33 +
 drivers/net/wwan/t9xx/mtk_wwan.c                   |  475 ++++
 drivers/net/wwan/t9xx/mtk_wwan.h                   |   17 +
 drivers/net/wwan/t9xx/pcie/Makefile                |   19 +
 drivers/net/wwan/t9xx/pcie/mtk_cldma.c             | 1527 +++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_cldma.h             |  176 ++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.c         |  373 +++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.h         |  174 ++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.c    |  177 ++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.h    |  101 +
 drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c     |   55 +
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif.c            | 2714 ++++++++++++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif.h            |   16 +
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c        | 1586 ++++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.h        |  268 ++
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv_m9xx.c   |  687 +++++
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_reg.h        |  387 +++
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_reg_m9xx.h   |   37 +
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.c       |  168 ++
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.h       |  161 ++
 drivers/net/wwan/t9xx/pcie/mtk_pci.c               | 1067 ++++++++
 drivers/net/wwan/t9xx/pcie/mtk_pci.h               |  219 ++
 drivers/net/wwan/t9xx/pcie/mtk_pci_drv_m9xx.c      |   70 +
 drivers/net/wwan/t9xx/pcie/mtk_pci_reg.h           |   72 +
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c        |  593 +++++
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h        |  105 +
 43 files changed, 14761 insertions(+)
---
base-commit: eb3f4b7426cfd2b79d65b7d37155480b32259a11
change-id: 20260529-t9xx_driver_v1-1744f8af7739

Best regards,
--  
Jack Wu <jackbb_wu@compal.com>

