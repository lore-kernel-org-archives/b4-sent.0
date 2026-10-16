From: Takahiro Kuwano <takahiro.kuwano@infineon.com>
Subject: [PATCH v3 0/4] mtd: spi-nor: split SFDP, ID database, and fixups
Date: Fri, 16 Oct 2026 10:43:41 +0900
Message-Id: <20261016-split-sfdp-id-v3-v3-0-4a47b8fc945a@infineon.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvyJ7bsE0PfSV6BC51kKUuCGB9Pek4
 zDMVBDKTAKjqpCpsPB1NrCdgnVfzo2QQ2Mw2vhe9x4lHXyjxJCawWIxOq/NYN3iBg0tS5kiP/9
 ymt/3Axt59hliAAAA
X-Change-ID: 20261016-split-sfdp-id-v3-f5602435a540
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, Vignesh R <vigneshr@ti.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, Vincent Jardin <vjardin@free.fr>, 
 Fabio Estevam <festevam@nabladev.com>, Eugen Hristev <ehristev@kernel.org>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792115031; l=3207;
 i=takahiro.kuwano@infineon.com; s=20261016-2; h=from:subject:message-id;
 bh=Mc9K5sN8LF0Gr1yCEXpX7+PZDSAqlIBYhE3AMNF6W98=;
 b=FQplaQowf4AIwyYIs9h3il1g3atVaQcbhPkZ9h5cygSyQweHA6T9FKi3hNqM0qw3CVfr1Lhrb
 2esorlLR9CBBSa///w/GgWtG59jAIg5bhwmzDSODvg30u0vcQ0yoG7h
X-Developer-Key: i=takahiro.kuwano@infineon.com; a=ed25519;
 pk=pp4mpJAHIqhV2MvdSGbIzKRk3ujhk+tSlGjyTursr4E=
X-Endpoint-Received: by B4 Relay for takahiro.kuwano@infineon.com/20261016-2 with auth_id=1202
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The spi-nor-core.c contains optional logics like SFDP and manufcaturer
specific fixups. The spi-nor-ids.c has single large ID database. There
are many #ifdef directives in those files and that negatively affects
readability and maintainability.

This series, as the first step of cleanup, move SFDP logic, IDs, and
fixups to newly source files. Reworking, renaming, and reformating
existing code is not a scope of this series and further cleanup will be
taken place in follow-up patches.

Here is the code size impact when applying this series.
Measured by my AMD Zynq-7000 (ARM32) environment with SFDP and all
manufcaturers are enabled.

SPI-NOR:
            text    data     bss     dec     hex filename
BEFORE    720685   14084       0  734769   b3631 u-boot
AFTER     721827   14156       0  735983   b3aef u-boot
DELTA      +1142     +72

TINY:
            text    data     bss     dec     hex filename
BEFORE     77399    3128     248   80775   13b87 spl/u-boot-spl
AFTER      77589    3200     248   81037   13c8d spl/u-boot-spl
DELTA       +190     +72

Changes in v3:
- Expose manufacturers table so that sandbox can look up
- Update sandbox to handle manufacturers table
- Link to v2: https://lore.kernel.org/u-boot/20260924-split-sfdp-id-v2-0-aafc70e0b657@infineon.com/
Changes in v2:
- Rebase on top of next
- Link to v1: https://lore.kernel.org/u-boot/20260612-split-id-table-into-vendor-files-v1-0-dfaaa82cc6f0@infineon.com/

Signed-off-by: Takahiro Kuwano <takahiro.kuwano@infineon.com>
---
Takahiro Kuwano (4):
      mtd: spi-nor: move SFDP logic out of the core
      mtd: spi-nor: import manufacturer driver concept from Linux
      mtd: spi-nor: move flash info entries to manufacturer drivers
      mtd: spi-nor: move fixups to manufacturer drivers

 drivers/mtd/spi/Makefile        |   18 +
 drivers/mtd/spi/atmel.c         |   28 +
 drivers/mtd/spi/dosilicon.c     |   25 +
 drivers/mtd/spi/eon.c           |   23 +
 drivers/mtd/spi/fujitsu.c       |   27 +
 drivers/mtd/spi/gigadevice.c    |  140 ++
 drivers/mtd/spi/issi.c          |   84 ++
 drivers/mtd/spi/macronix.c      |  154 +++
 drivers/mtd/spi/micron-st.c     |  169 +++
 drivers/mtd/spi/puya.c          |   56 +
 drivers/mtd/spi/sandbox.c       |   33 +-
 drivers/mtd/spi/sf_internal.h   |  136 +-
 drivers/mtd/spi/sfdp.c          |  720 ++++++++++
 drivers/mtd/spi/sfdp.h          |  152 +++
 drivers/mtd/spi/siliconkaiser.c |   18 +
 drivers/mtd/spi/spansion.c      |  700 ++++++++++
 drivers/mtd/spi/spi-nor-core.c  | 2751 +++++++--------------------------------
 drivers/mtd/spi/spi-nor-ids.c   |  753 +----------
 drivers/mtd/spi/spi-nor-tiny.c  |   11 +-
 drivers/mtd/spi/sst.c           |   34 +
 drivers/mtd/spi/winbond.c       |  250 ++++
 drivers/mtd/spi/xmc.c           |   27 +
 drivers/mtd/spi/xtx.c           |   54 +
 drivers/mtd/spi/zbit.c          |   19 +
 include/linux/mtd/spi-nor.h     |    2 +
 25 files changed, 3404 insertions(+), 2980 deletions(-)
---
base-commit: ed869863c7e2aca50d57a05d843830dd843138c4
change-id: 20261016-split-sfdp-id-v3-f5602435a540

Best regards,
-- 
Takahiro Kuwano <takahiro.kuwano@infineon.com>

