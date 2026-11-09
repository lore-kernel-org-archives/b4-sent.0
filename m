From: Takahiro Kuwano <takahiro.kuwano@infineon.com>
Subject: [PATCH v4 0/5] mtd: spi-nor: split SFDP, ID database, and fixups
Date: Mon, 09 Nov 2026 18:39:40 +0900
Message-Id: <20261109-split-sfdp-id-v3-v4-0-7270c9d82fd3@infineon.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ7CIBREr9L8tRhKAbUr72G6QAr2JwqE3xBNw
 93FHsBkNm8mM7MBuYyOYOw2yK4gYQwN5KEDu5jwcAznxiC40D3vNaP0xJWRn1NLWBmYV5oLOSi
 jJIdWS9l5fO+Tt6nxgrTG/NkfyvBz/4w1cSaNPN3P3l6kMlcMHoOL4WjjC6Za6xeBChAEswAAA
 A==
X-Change-ID: 20261016-split-sfdp-id-v3-f5602435a540
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, Vignesh R <vigneshr@ti.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, Vincent Jardin <vjardin@free.fr>, 
 Fabio Estevam <festevam@nabladev.com>, Eugen Hristev <ehristev@kernel.org>, 
 Bastien Curutchet <bastien.curutchet@bootlin.com>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794217192; l=3697;
 i=takahiro.kuwano@infineon.com; s=20261016-2; h=from:subject:message-id;
 bh=bIq6ZaahP+3kiESB3cK50by3HMWQLrcf+ZaQXKb08Rk=;
 b=gWD6B+n9Y1l1Fh+OYX6jT13TlQzIsfvysApFyWbFeLGRzorOtdKtwTfrTaKyNwGtlE1OH1z6E
 NOKasGkSo1VCO8jPFJ5R3RdVO09ql4gkMm0k9/dVP8DyDKJzZzex7aP
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

To mitigate the size increase due to these changes, drop one of the
page size parameter from struct flash_info. The resulting size is
smaller than it was before the patch was applied (see below).

Here is the code size impact when applying this series.
Measured by my AMD Zynq-7000 (ARM32) environment with SFDP and all
manufcaturers are enabled.

SPI-NOR:
            text    data     bss     dec     hex filename
BEFORE    722344   14100       0  736444   b3cbc u-boot
AFTER     722196   14188       0  736384   b3c80 u-boot
DELTA       -148     +88             -60

TINY:
            text    data     bss     dec     hex filename
BEFORE     77490    3128     248   80866   13be2 spl/u-boot-spl
AFTER      76342    3200     248   79790   137ae spl/u-boot-spl
DELTA      -1148     +72           -1076

Changes in v4:
- Rebase to v2027.01-rc1
- Add patch 5 to reduce the size of device ID database
- Link to v3: https://lore.kernel.org/r/20261016-split-sfdp-id-v3-v3-0-4a47b8fc945a@infineon.com
Changes in v3:
- Expose manufacturers table so that sandbox can look up
- Update sandbox to handle manufacturers table
- Link to v2: https://lore.kernel.org/u-boot/20260924-split-sfdp-id-v2-0-aafc70e0b657@infineon.com/
Changes in v2:
- Rebase on top of next
- Link to v1: https://lore.kernel.org/u-boot/20260612-split-id-table-into-vendor-files-v1-0-dfaaa82cc6f0@infineon.com/

Signed-off-by: Takahiro Kuwano <takahiro.kuwano@infineon.com>
---
Takahiro Kuwano (5):
      mtd: spi-nor: move SFDP logic out of the core
      mtd: spi-nor: import manufacturer driver concept from Linux
      mtd: spi-nor: move flash info entries to manufacturer drivers
      mtd: spi-nor: move fixups to manufacturer drivers
      mtd: spi-nor: remove page_size from struct flash_info

 drivers/mtd/spi/Makefile        |   18 +
 drivers/mtd/spi/atmel.c         |   28 +
 drivers/mtd/spi/dosilicon.c     |   27 +
 drivers/mtd/spi/eon.c           |   23 +
 drivers/mtd/spi/fujitsu.c       |   47 +
 drivers/mtd/spi/gigadevice.c    |  141 ++
 drivers/mtd/spi/issi.c          |   84 ++
 drivers/mtd/spi/macronix.c      |  154 +++
 drivers/mtd/spi/micron-st.c     |  169 +++
 drivers/mtd/spi/puya.c          |   56 +
 drivers/mtd/spi/sandbox.c       |   33 +-
 drivers/mtd/spi/sf_internal.h   |  137 +-
 drivers/mtd/spi/sfdp.c          |  720 ++++++++++
 drivers/mtd/spi/sfdp.h          |  152 +++
 drivers/mtd/spi/siliconkaiser.c |   18 +
 drivers/mtd/spi/spansion.c      |  700 ++++++++++
 drivers/mtd/spi/spi-nor-core.c  | 2753 +++++++--------------------------------
 drivers/mtd/spi/spi-nor-ids.c   |  756 +----------
 drivers/mtd/spi/spi-nor-tiny.c  |   11 +-
 drivers/mtd/spi/sst.c           |   34 +
 drivers/mtd/spi/winbond.c       |  250 ++++
 drivers/mtd/spi/xmc.c           |   27 +
 drivers/mtd/spi/xtx.c           |   54 +
 drivers/mtd/spi/zbit.c          |   19 +
 include/linux/mtd/spi-nor.h     |    2 +
 25 files changed, 3428 insertions(+), 2985 deletions(-)
---
base-commit: 709a97a05df66e394f40d249105d0baade46f107
change-id: 20261016-split-sfdp-id-v3-f5602435a540

Best regards,
-- 
Takahiro Kuwano <takahiro.kuwano@infineon.com>

