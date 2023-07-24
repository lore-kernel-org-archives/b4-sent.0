From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/2] net: add support for HiSilicon Fast Ethernet
 Controller driver
Date: Tue, 25 Jul 2023 00:20:07 +0800
Message-Id: <20230725-wip-hisi_femac-trunk-v1-0-88469a170310@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALekvmQC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2MDcyMT3fLMAt0MoLL4tNTcxGTdkqLSvGxdwzRT8zQDSwuzNINkJaDWgqL
 UtMwKsLHRsbW1ACAj2BBmAAAA
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>
Cc: Yisen Zhuang <yisen.zhuang@huawei.com>, 
 Salil Mehta <salil.mehta@huawei.com>, David Yang <mmyangfl@gmail.com>, 
 u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1690215608; l=1066;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=oklXERr8FMwt6uEJGE9VaehniYtKEakouGV6e5/jhfo=;
 b=bQzUEMnsR6uS8C9mDGoQD5t9gmSrpQy0KMVs6Zs97qV2GsVvQqbPB+zDtB5g/9lC4KtIBr2Dm
 TBT7ua+CwomBVyj+s25+51H8dc0/MNvzCjryPoA/bLnMqilsIfMI4Je
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
Yang Xiwen (2):
      net: add hifemac Ethernet driver for HiSilicon platform
      net: add hifemac_mdio MDIO bus driver for HiSilicon platform

 drivers/net/Kconfig        |  17 ++
 drivers/net/Makefile       |   2 +
 drivers/net/hifemac.c      | 478 +++++++++++++++++++++++++++++++++++++++++++++
 drivers/net/hifemac_mdio.c | 116 +++++++++++
 4 files changed, 613 insertions(+)
---
base-commit: 580eb31199be8a822e62f20965854a242f895d03
change-id: 20230724-wip-hisi_femac-trunk-1f57f0986f0c

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

