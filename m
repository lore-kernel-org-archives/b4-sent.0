From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH RESEND v2 0/2] net: add support for HiSilicon Fast Ethernet
 Controller driver
Date: Wed, 23 Aug 2023 01:03:41 +0800
Message-Id: <20230823-wip-hisi_femac-trunk-v2-0-f64c28dc9b95@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>
Cc: Yisen Zhuang <yisen.zhuang@huawei.com>, 
 Salil Mehta <salil.mehta@huawei.com>, David Yang <mmyangfl@gmail.com>, 
 u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692723823; l=1239;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=6NJqaJvdjGHbug0V5ivKzYtBV8Sd2+bQXnF+m+rLY38=;
 b=7W9L65ErtM9ldFdCcTZJ8BFx5tmfQoBRpwg4oLhcWgFhxq1Do2gk2NXUtsCFuI0q9gdKQ0+F5
 ZB/iFiBv9GMD1VpQXzwiOOcEn9+8PU7S06Mhrb7V0gJQnBnrg/O64g0
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This core is found on many HiSilicon chips. This patchset adds support
for it and the integrated MDIO bus.

The driver code comes from linux kernel driver, downstream u-boot driver
and the datasheet. It's already tested on a Hi3798MV200 based STB.

Note that currently this driver can't be used for Hi3798MV200 since the
clock driver is missing. I will implement and submit the clock driver
and the framework in a later patchset.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v2:
- hisi_femac: clear previous irq before sending
- Link to v1: https://lore.kernel.org/r/20230725-wip-hisi_femac-trunk-v1-0-88469a170310@outlook.com

---
Yang Xiwen (2):
      net: add hifemac Ethernet driver for HiSilicon platform
      net: add hifemac_mdio MDIO bus driver for HiSilicon platform

 drivers/net/Kconfig        |  17 ++
 drivers/net/Makefile       |   2 +
 drivers/net/hifemac.c      | 481 +++++++++++++++++++++++++++++++++++++++++++++
 drivers/net/hifemac_mdio.c | 116 +++++++++++
 4 files changed, 616 insertions(+)
---
base-commit: 580eb31199be8a822e62f20965854a242f895d03
change-id: 20230724-wip-hisi_femac-trunk-1f57f0986f0c

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

