From: Sam Ravnborg <sam@ravnborg.org>
Date: Fri, 23 Feb 2024 20:36:51 +0100
Subject: [PATCH 5/6] sparc32: Do not select GENERIC_ISA_DMA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240223-sam-fix-sparc32-all-builds-v1-5-5c60fd5c9250@ravnborg.org>
References: <20240223-sam-fix-sparc32-all-builds-v1-0-5c60fd5c9250@ravnborg.org>
In-Reply-To: <20240223-sam-fix-sparc32-all-builds-v1-0-5c60fd5c9250@ravnborg.org>
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 "Maciej W. Rozycki" <macro@orcam.me.uk>
Cc: sparclinux@vger.kernel.org, linux-parport@lists.infradead.org, 
 "David S. Miller" <davem@davemloft.net>, 
 Andreas Larsson <andreas@gaisler.com>, Randy Dunlap <rdunlap@infradead.org>, 
 Arnd Bergmann <arnd@arndb.de>, linux-kernel@vger.kernel.org, 
 Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708717023; l=889;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=lMxXdOPMpDx1tzgAvR97ar00I1WhL1W/uCEBzu9wvkY=;
 b=ggGkf5ePuxoN77uiKL1N8qedIdOOw6npYIMJDxI/0wfpWe9GpS7/PQuyPyLuCNWZG1R1N2uUkMUu
 7tJF7mj6AdTslYKT4aZkP2h+GawJFdO/y/vRle52oc2KWM7LBg7E
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sparc32 do not support generic isa dma, so do not select the symbol.
Without this fix, the following patch would break the build with a
missing prototype.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
Cc: Randy Dunlap <rdunlap@infradead.org>
Cc: Maciej W. Rozycki <macro@orcam.me.uk>
Fixes: 66bcd06099bb ("parport_pc: Also enable driver for PCI systems")
---
 arch/sparc/Kconfig | 4 ----
 1 file changed, 4 deletions(-)

diff --git a/arch/sparc/Kconfig b/arch/sparc/Kconfig
index 734f23daecca..d08a5662ea60 100644
--- a/arch/sparc/Kconfig
+++ b/arch/sparc/Kconfig
@@ -138,10 +138,6 @@ config HIGHMEM
 	default y if SPARC32
 	select KMAP_LOCAL
 
-config GENERIC_ISA_DMA
-	bool
-	default y if SPARC32
-
 config PGTABLE_LEVELS
 	default 4 if 64BIT
 	default 3

-- 
2.34.1

