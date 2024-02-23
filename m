From: Sam Ravnborg <sam@ravnborg.org>
Subject: [PATCH 0/6] sparc32: build fixes for all{yes,mod}config builds
Date: Fri, 23 Feb 2024 20:36:46 +0100
Message-Id: <20240223-sam-fix-sparc32-all-builds-v1-0-5c60fd5c9250@ravnborg.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM7z2GUC/x3MwQqDMAyA4VeRnA2kqeywV5Edoo0u0FVpmAjiu
 6/s+MHPf4FrNXV4dhdUPcxtKw2h72B+S1kVLTUDEw/EHNHlg4ud6LvUOTJKzjh9LSdHEhoopoe
 GKUIb7FVb+Z+Pr/v+Ae9UgjtsAAAA
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 "Maciej W. Rozycki" <macro@orcam.me.uk>
Cc: sparclinux@vger.kernel.org, linux-parport@lists.infradead.org, 
 "David S. Miller" <davem@davemloft.net>, 
 Andreas Larsson <andreas@gaisler.com>, Randy Dunlap <rdunlap@infradead.org>, 
 Arnd Bergmann <arnd@arndb.de>, linux-kernel@vger.kernel.org, 
 Sam Ravnborg <sam@ravnborg.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708717023; l=1522;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=1FvHo9ZAqFnYQ8+JzpM97RGyfU19vXDAXyiInWFH3to=;
 b=OFnhZ7qFaVRYiAb/ePV4/EKaLsohB7PongJrPCQXAqPZ35oim3gVrrekQ3I1NJ3unFNJfEnR2G6s
 y4Eguzo1Bt73Ka8AN51+alJxGvzS42SSt5Gjy9Nu0m3rc2TXMMGS
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a small set of patches that address build breakage with
allyesconfig / allmodconfig.

This solves some, but not all, build breakage.
The parport fix depends on the previous patch, the rest are independent
fixes.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
Sam Ravnborg (6):
      sparc32: Use generic cmpdi2/ucmpdi2 variants
      sparc32: Fix build with trapbase
      mtd: maps: sun_uflash: Declare uflash_devinit static
      usb: host: uhci-grlib.c: Fix build, add platform_device
      sparc32: Do not select GENERIC_ISA_DMA
      sparc32: Fix parport build with sparc32

 arch/sparc/Kconfig                  |   6 +-
 arch/sparc/include/asm/parport.h    | 259 +-----------------------------------
 arch/sparc/include/asm/parport_64.h | 256 +++++++++++++++++++++++++++++++++++
 arch/sparc/kernel/irq_32.c          |   6 +-
 arch/sparc/kernel/kernel.h          |   8 +-
 arch/sparc/kernel/kgdb_32.c         |   4 +-
 arch/sparc/kernel/leon_smp.c        |   6 +-
 arch/sparc/kernel/setup_32.c        |   4 +-
 arch/sparc/lib/Makefile             |   4 +-
 arch/sparc/lib/cmpdi2.c             |  28 ----
 arch/sparc/lib/ucmpdi2.c            |  20 ---
 drivers/mtd/maps/sun_uflash.c       |   2 +-
 drivers/usb/host/uhci-grlib.c       |   1 +
 13 files changed, 283 insertions(+), 321 deletions(-)
---
base-commit: 626db6ee8ee1edac206610db407114aa83b53fd3
change-id: 20240223-sam-fix-sparc32-all-builds-0a0403d6e1b3

Best regards,
-- 
Sam Ravnborg <sam@ravnborg.org>

