From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 24 Feb 2024 18:42:26 +0100
Subject: [PATCH v2 5/7] sparc32: Do not select GENERIC_ISA_DMA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240224-sam-fix-sparc32-all-builds-v2-5-1f186603c5c4@ravnborg.org>
References: <20240224-sam-fix-sparc32-all-builds-v2-0-1f186603c5c4@ravnborg.org>
In-Reply-To: <20240224-sam-fix-sparc32-all-builds-v2-0-1f186603c5c4@ravnborg.org>
To: "Maciej W. Rozycki" <macro@orcam.me.uk>, sparclinux@vger.kernel.org, 
 Andreas Larsson <andreas@gaisler.com>, Randy Dunlap <rdunlap@infradead.org>
Cc: Miquel Raynal <miquel.raynal@bootlin.com>, 
 linux-parport@lists.infradead.org, "David S. Miller" <davem@davemloft.net>, 
 Arnd Bergmann <arnd@arndb.de>, linux-kernel@vger.kernel.org, 
 Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708796545; l=1135;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=OWAinB5URH3jM/Z4sqc7e9m3++OQMwYINtdPlTPG+3w=;
 b=IarfFy+3MHxhNsZ6KvRnK2UXkA3EcCfDklgPPW35n08X0QuMF3S7OCNXV+xsMYB11dgu5G8uxlWu
 oHxA3Ud3BP7eCnoq1lfEMf3GTDc4b3d1ofPjxcyUBNxO04uvCIoj
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sparc32 do not support generic isa dma, so do not select the symbol.

This fixes the following warnings:
dma.c:70:5: error: no previous prototype for 'request_dma' [-Werror=missing-prototypes]
dma.c:88:6: error: no previous prototype for 'free_dma' [-Werror=missing-prototypes]

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Fixes: 0fcb70851fbf ("Makefile.extrawarn: turn on missing-prototypes globally")
Acked-by: Randy Dunlap <rdunlap@infradead.org>
Tested-by: Randy Dunlap <rdunlap@infradead.org> # build-tested
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
Cc: Randy Dunlap <rdunlap@infradead.org>
Cc: Maciej W. Rozycki <macro@orcam.me.uk>
---
 arch/sparc/Kconfig | 4 ----
 1 file changed, 4 deletions(-)

diff --git a/arch/sparc/Kconfig b/arch/sparc/Kconfig
index bdbde506c01e..440e53d37d20 100644
--- a/arch/sparc/Kconfig
+++ b/arch/sparc/Kconfig
@@ -137,10 +137,6 @@ config HIGHMEM
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

