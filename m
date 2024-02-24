From: Sam Ravnborg <sam@ravnborg.org>
Subject: [PATCH v2 0/7] sparc32: build fixes for all{yes,mod}config builds
Date: Sat, 24 Feb 2024 18:42:21 +0100
Message-Id: <20240224-sam-fix-sparc32-all-builds-v2-0-1f186603c5c4@ravnborg.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH0q2mUC/42NQQ6CMBBFr0Jm7ZhhCiS68h6GRWkLTIJAptpoC
 He3cgIXf/F+ft7fIAaVEOFabKAhSZRlzsCnAtxo5yGg+MzAxBUxG4z2gb28Ma5WnWG004TdSyY
 fkSxVZHwTys5AFqwa8vKQ39vMo8Tnop/jK5W/9i9tKpGwdg31vnYXrummNs3dosM5B9p937//A
 +N+xwAAAA==
To: "Maciej W. Rozycki" <macro@orcam.me.uk>, sparclinux@vger.kernel.org, 
 Andreas Larsson <andreas@gaisler.com>, Randy Dunlap <rdunlap@infradead.org>
Cc: Miquel Raynal <miquel.raynal@bootlin.com>, 
 linux-parport@lists.infradead.org, "David S. Miller" <davem@davemloft.net>, 
 Arnd Bergmann <arnd@arndb.de>, linux-kernel@vger.kernel.org, 
 Sam Ravnborg <sam@ravnborg.org>, stable@vger.kernel.org
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708796545; l=2881;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=X84iKnqqvDs4FSzZwltR/vjttwT6+4gDq5uRYJRa4ms=;
 b=uVUk6SNR2PRIhhlI7FiC0xyC3ybSXRI7dcnt+LpFDLsVFh7E3Dp83/IH/+KkhGiT3yKpvCsCAEaI
 grgWlLGpCRKtOo9ncpF2S37R114cBwqW8wWw68lJvmM+oKHbaQHS
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a small set of patches that address build breakage with
allyesconfig / allmodconfig.

This solves some, but not all, build breakage.
The parport fix depends on the previous patch, the rest are independent
fixes.

With v2 there is a extra patch that drops ZONE_DMA support.
It does not fix any build failure, but a nice cleanup.

Cc: Miquel Raynal <miquel.raynal@bootlin.com>
To: Maciej W. Rozycki <macro@orcam.me.uk>
To:  <sparclinux@vger.kernel.org>
Cc:  <linux-parport@lists.infradead.org>
Cc: David S. Miller <davem@davemloft.net>
To: Andreas Larsson <andreas@gaisler.com>
To: Randy Dunlap <rdunlap@infradead.org>
Cc: Arnd Bergmann <arnd@arndb.de>
Cc:  <linux-kernel@vger.kernel.org>

Changes in v2:
- Added r-b/tested by (thanks to Randy and Maciej)
- Dropped patch for uhci-grlib.c as it is already upstream (Randy)
- Added a few Fixes (Maciej)
- Fixed commit message when dropping GENERIC_ISA_DMA (Maciej)
- Added new patch that drop ZONE_DMA (Maciej)
- Added new patch to fix section mismatch error

In an allmodconfig build I see a lot of:

    modpost: "__udelay" [module] has no CRC!

Similar for a handful of other symbols.
Any hint how to get rid of them would be nice.
I have tried to add the prototype to asm-prototypes.h with no luck.

On top of this the link fails, but I assume this the kernel that grows
too big which is no surprise.

- Link to v1: https://lore.kernel.org/r/20240223-sam-fix-sparc32-all-builds-v1-0-5c60fd5c9250@ravnborg.org

---
Sam Ravnborg (7):
      sparc32: Use generic cmpdi2/ucmpdi2 variants
      sparc32: Fix build with trapbase
      mtd: maps: sun_uflash: Declare uflash_devinit static
      sparc32: Do not select ZONE_DMA
      sparc32: Do not select GENERIC_ISA_DMA
      sparc32: Fix parport build with sparc32
      sparc32: Fix section mismatch in leon_pci_grpci

 arch/sparc/Kconfig                  |   7 +-
 arch/sparc/include/asm/parport.h    | 259 +-----------------------------------
 arch/sparc/include/asm/parport_64.h | 256 +++++++++++++++++++++++++++++++++++
 arch/sparc/kernel/irq_32.c          |   6 +-
 arch/sparc/kernel/kernel.h          |   8 +-
 arch/sparc/kernel/kgdb_32.c         |   4 +-
 arch/sparc/kernel/leon_pci_grpci1.c |   2 +-
 arch/sparc/kernel/leon_pci_grpci2.c |   2 +-
 arch/sparc/kernel/leon_smp.c        |   6 +-
 arch/sparc/kernel/setup_32.c        |   4 +-
 arch/sparc/lib/Makefile             |   4 +-
 arch/sparc/lib/cmpdi2.c             |  28 ----
 arch/sparc/lib/ucmpdi2.c            |  20 ---
 arch/sparc/mm/srmmu.c               |   1 -
 drivers/mtd/maps/sun_uflash.c       |   2 +-
 15 files changed, 284 insertions(+), 325 deletions(-)
---
base-commit: 626db6ee8ee1edac206610db407114aa83b53fd3
change-id: 20240223-sam-fix-sparc32-all-builds-0a0403d6e1b3

Best regards,
-- 
Sam Ravnborg <sam@ravnborg.org>

