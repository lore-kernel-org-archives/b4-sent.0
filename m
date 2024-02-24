From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 24 Feb 2024 18:42:25 +0100
Subject: [PATCH v2 4/7] sparc32: Do not select ZONE_DMA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240224-sam-fix-sparc32-all-builds-v2-4-1f186603c5c4@ravnborg.org>
References: <20240224-sam-fix-sparc32-all-builds-v2-0-1f186603c5c4@ravnborg.org>
In-Reply-To: <20240224-sam-fix-sparc32-all-builds-v2-0-1f186603c5c4@ravnborg.org>
To: "Maciej W. Rozycki" <macro@orcam.me.uk>, sparclinux@vger.kernel.org, 
 Andreas Larsson <andreas@gaisler.com>, Randy Dunlap <rdunlap@infradead.org>
Cc: Miquel Raynal <miquel.raynal@bootlin.com>, 
 linux-parport@lists.infradead.org, "David S. Miller" <davem@davemloft.net>, 
 Arnd Bergmann <arnd@arndb.de>, linux-kernel@vger.kernel.org, 
 Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708796545; l=1855;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=e4J0zd9pY2ujVasdD/OCfxLoCPAiNjhFop1a9KlpN8Y=;
 b=MVGnDmkOPaAA7gRzYjqyp6PXBzdF71VyxCP8e0uInzrhjO9FFoFgAN2oOm0ccll9Qw/OROQJGh0b
 tBxygqh1CQrVXFSrK/1kydoqp55XdUlRYUubtHR+KhsaSKdOG8NN
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sparc32 has no limited DMA zone so there is no need to select ZONE_DMA.

Based on analysis from Marciej:
"
    Actually I think ZONE_DMA should go too (it's linked to GENERIC_ISA_DMA,
    isn't it? -- cf. commit 5ac6da669e24 ("[PATCH] Set CONFIG_ZONE_DMA for
    arches with GENERIC_ISA_DMA")), and the whole thing use:

    Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")

    The GENERIC_ISA_DMA option itself was added to arch/sparc/config.in with
    2.5.31 as:

        define_bool CONFIG_GENERIC_ISA_DMA y

    despite of:

        define_bool CONFIG_ISA n
"

The sparc32 code did not differ between ZONE_NORMAL and ZONE_DMA,
which confirms the above. This patch drop ZONE_DMA.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Reported-by: "Maciej W. Rozycki" <macro@orcam.me.uk>
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
Cc: Randy Dunlap <rdunlap@infradead.org>
Cc: Maciej W. Rozycki <macro@orcam.me.uk>
Cc: Arnd Bergmann <arnd@arndb.de>
---
 arch/sparc/Kconfig    | 1 -
 arch/sparc/mm/srmmu.c | 1 -
 2 files changed, 2 deletions(-)

diff --git a/arch/sparc/Kconfig b/arch/sparc/Kconfig
index 734f23daecca..bdbde506c01e 100644
--- a/arch/sparc/Kconfig
+++ b/arch/sparc/Kconfig
@@ -62,7 +62,6 @@ config SPARC32
 	select HAVE_UID16
 	select LOCK_MM_AND_FIND_VMA
 	select OLD_SIGACTION
-	select ZONE_DMA
 
 config SPARC64
 	def_bool 64BIT
diff --git a/arch/sparc/mm/srmmu.c b/arch/sparc/mm/srmmu.c
index 852085ada368..7aae2f6f4973 100644
--- a/arch/sparc/mm/srmmu.c
+++ b/arch/sparc/mm/srmmu.c
@@ -975,7 +975,6 @@ void __init srmmu_paging_init(void)
 	{
 		unsigned long max_zone_pfn[MAX_NR_ZONES] = { 0 };
 
-		max_zone_pfn[ZONE_DMA] = max_low_pfn;
 		max_zone_pfn[ZONE_NORMAL] = max_low_pfn;
 		max_zone_pfn[ZONE_HIGHMEM] = highend_pfn;
 

-- 
2.34.1

