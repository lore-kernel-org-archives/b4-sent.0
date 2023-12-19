From: Sam Ravnborg <sam@ravnborg.org>
Date: Tue, 19 Dec 2023 23:03:18 +0100
Subject: [PATCH 13/27] sparc32: Drop unused function __get_{phys,iospace}
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231219-sam-sparc32-sunset-v3-v1-13-64bb44b598c5@ravnborg.org>
References: <20231219-sam-sparc32-sunset-v3-v1-0-64bb44b598c5@ravnborg.org>
In-Reply-To: <20231219-sam-sparc32-sunset-v3-v1-0-64bb44b598c5@ravnborg.org>
To: "David S. Miller" <davem@davemloft.net>, 
 Arnd Bergmann <arnd@kernel.org>, Andreas Larsson <andreas@gaisler.com>
Cc: Helge Deller <deller@gmx.de>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Alan Stern <stern@rowland.harvard.edu>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, sparclinux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-sound@vger.kernel.org, Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1703023392; l=1970;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=E0Vh64/XjG0Um8pqx4pfsGK0FeX+R72wUc/BzUbmKDY=;
 b=wcpWwsTyWY02ja6To5kFELiblsY7eCvn92LTyIteU8JScRw9rKK4BLrishuuIo6zaZGwblJuujCO
 W7KiPfkCDAA5sPkUC1yGvZPC9BwmwtiJohyPHsK3jjTfRswBiRbl
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Not used and references stuff that will be dropped later.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: "David S. Miller" <davem@davemloft.net>
Cc: Arnd Bergmann <arnd@kernel.org>
Cc: Andreas Larsson <andreas@gaisler.com>
---
 arch/sparc/include/asm/pgtable_32.h | 24 ------------------------
 arch/sparc/include/asm/pgtsrmmu.h   | 11 -----------
 2 files changed, 35 deletions(-)

diff --git a/arch/sparc/include/asm/pgtable_32.h b/arch/sparc/include/asm/pgtable_32.h
index 9e85d57ac3f2..92b063531d5c 100644
--- a/arch/sparc/include/asm/pgtable_32.h
+++ b/arch/sparc/include/asm/pgtable_32.h
@@ -368,30 +368,6 @@ static inline pte_t pte_swp_clear_exclusive(pte_t pte)
 	return __pte(pte_val(pte) & ~SRMMU_SWP_EXCLUSIVE);
 }
 
-static inline unsigned long
-__get_phys (unsigned long addr)
-{
-	switch (sparc_cpu_model){
-	case sun4m:
-	case sun4d:
-		return ((srmmu_get_pte (addr) & 0xffffff00) << 4);
-	default:
-		return 0;
-	}
-}
-
-static inline int
-__get_iospace (unsigned long addr)
-{
-	switch (sparc_cpu_model){
-	case sun4m:
-	case sun4d:
-		return (srmmu_get_pte (addr) >> 28);
-	default:
-		return -1;
-	}
-}
-
 /*
  * For sparc32&64, the pfn in io_remap_pfn_range() carries <iospace> in
  * its high 4 bits.  These macros/functions put it there or get it from there.
diff --git a/arch/sparc/include/asm/pgtsrmmu.h b/arch/sparc/include/asm/pgtsrmmu.h
index 18e68d43f036..7cb5cbc83211 100644
--- a/arch/sparc/include/asm/pgtsrmmu.h
+++ b/arch/sparc/include/asm/pgtsrmmu.h
@@ -125,17 +125,6 @@ static inline void srmmu_flush_whole_tlb(void)
 
 }
 
-static inline int
-srmmu_get_pte (unsigned long addr)
-{
-	register unsigned long entry;
-        
-	__asm__ __volatile__("\n\tlda [%1] %2,%0\n\t" :
-				"=r" (entry):
-				"r" ((addr & 0xfffff000) | 0x400), "i" (ASI_M_FLUSH_PROBE));
-	return entry;
-}
-
 #endif /* !(__ASSEMBLY__) */
 
 #endif /* !(_SPARC_PGTSRMMU_H) */

-- 
2.34.1

