From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 24 Feb 2024 18:42:22 +0100
Subject: [PATCH v2 1/7] sparc32: Use generic cmpdi2/ucmpdi2 variants
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240224-sam-fix-sparc32-all-builds-v2-1-1f186603c5c4@ravnborg.org>
References: <20240224-sam-fix-sparc32-all-builds-v2-0-1f186603c5c4@ravnborg.org>
In-Reply-To: <20240224-sam-fix-sparc32-all-builds-v2-0-1f186603c5c4@ravnborg.org>
To: "Maciej W. Rozycki" <macro@orcam.me.uk>, sparclinux@vger.kernel.org, 
 Andreas Larsson <andreas@gaisler.com>, Randy Dunlap <rdunlap@infradead.org>
Cc: Miquel Raynal <miquel.raynal@bootlin.com>, 
 linux-parport@lists.infradead.org, "David S. Miller" <davem@davemloft.net>, 
 Arnd Bergmann <arnd@arndb.de>, linux-kernel@vger.kernel.org, 
 Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708796545; l=3720;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=J7PFWlRTGPOE40ffjTuq4qFkXa+HB/VYE+coSnVem7c=;
 b=vbgHBac6mbEYrKMqmpY/6A/xQZQwbFq2qJIc/DAzPT9BwFc2LOH7g4a6bo2kBYCR6oflCdIeHFdn
 r3Zmm3YPC8JijWXAcCsTfvRh+UV4vm59dTk7YY+6QFT67fdRb6ej
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the generic variants - the implementation is the same.
As a nice side-effect fix the following warnings:

cmpdi2.c: warning: no previous prototype for '__cmpdi2' [-Wmissing-prototypes]
ucmpdi2.c: warning: no previous prototype for '__ucmpdi2' [-Wmissing-prototypes]

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Fixes: 0fcb70851fbf ("Makefile.extrawarn: turn on missing-prototypes globally")
Reviewed-by: Randy Dunlap <rdunlap@infradead.org>
Tested-by: Randy Dunlap <rdunlap@infradead.org> # build-tested
Reviewed-by: Maciej W. Rozycki <macro@orcam.me.uk>
Tested-by: Maciej W. Rozycki <macro@orcam.me.uk> # build-tested
Cc: "David S. Miller" <davem@davemloft.net>
Cc: Andreas Larsson <andreas@gaisler.com>
---
 arch/sparc/Kconfig       |  2 ++
 arch/sparc/lib/Makefile  |  4 ++--
 arch/sparc/lib/cmpdi2.c  | 28 ----------------------------
 arch/sparc/lib/ucmpdi2.c | 20 --------------------
 4 files changed, 4 insertions(+), 50 deletions(-)

diff --git a/arch/sparc/Kconfig b/arch/sparc/Kconfig
index b087d4fe00af..734f23daecca 100644
--- a/arch/sparc/Kconfig
+++ b/arch/sparc/Kconfig
@@ -57,6 +57,8 @@ config SPARC32
 	select CLZ_TAB
 	select DMA_DIRECT_REMAP
 	select GENERIC_ATOMIC64
+	select GENERIC_LIB_CMPDI2
+	select GENERIC_LIB_UCMPDI2
 	select HAVE_UID16
 	select LOCK_MM_AND_FIND_VMA
 	select OLD_SIGACTION
diff --git a/arch/sparc/lib/Makefile b/arch/sparc/lib/Makefile
index 59669ebddd4e..ee5091dd67ed 100644
--- a/arch/sparc/lib/Makefile
+++ b/arch/sparc/lib/Makefile
@@ -14,7 +14,7 @@ lib-$(CONFIG_SPARC32) += divdi3.o udivdi3.o
 lib-$(CONFIG_SPARC32) += copy_user.o locks.o
 lib-$(CONFIG_SPARC64) += atomic_64.o
 lib-$(CONFIG_SPARC32) += lshrdi3.o ashldi3.o
-lib-$(CONFIG_SPARC32) += muldi3.o bitext.o cmpdi2.o
+lib-$(CONFIG_SPARC32) += muldi3.o bitext.o
 lib-$(CONFIG_SPARC64) += multi3.o
 lib-$(CONFIG_SPARC64) += fls.o
 lib-$(CONFIG_SPARC64) += fls64.o
@@ -51,5 +51,5 @@ lib-$(CONFIG_SPARC64) += copy_in_user.o memmove.o
 lib-$(CONFIG_SPARC64) += mcount.o ipcsum.o xor.o hweight.o ffs.o
 
 obj-$(CONFIG_SPARC64) += iomap.o
-obj-$(CONFIG_SPARC32) += atomic32.o ucmpdi2.o
+obj-$(CONFIG_SPARC32) += atomic32.o
 obj-$(CONFIG_SPARC64) += PeeCeeI.o
diff --git a/arch/sparc/lib/cmpdi2.c b/arch/sparc/lib/cmpdi2.c
deleted file mode 100644
index 333367fe7353..000000000000
--- a/arch/sparc/lib/cmpdi2.c
+++ /dev/null
@@ -1,28 +0,0 @@
-// SPDX-License-Identifier: GPL-2.0
-#include <linux/module.h>
-
-#include "libgcc.h"
-
-word_type __cmpdi2(long long a, long long b)
-{
-	const DWunion au = {
-		.ll = a
-	};
-	const DWunion bu = {
-		.ll = b
-	};
-
-	if (au.s.high < bu.s.high)
-		return 0;
-	else if (au.s.high > bu.s.high)
-		return 2;
-
-	if ((unsigned int) au.s.low < (unsigned int) bu.s.low)
-		return 0;
-	else if ((unsigned int) au.s.low > (unsigned int) bu.s.low)
-		return 2;
-
-	return 1;
-}
-
-EXPORT_SYMBOL(__cmpdi2);
diff --git a/arch/sparc/lib/ucmpdi2.c b/arch/sparc/lib/ucmpdi2.c
deleted file mode 100644
index 82c1cccb1264..000000000000
--- a/arch/sparc/lib/ucmpdi2.c
+++ /dev/null
@@ -1,20 +0,0 @@
-// SPDX-License-Identifier: GPL-2.0
-#include <linux/module.h>
-#include "libgcc.h"
-
-word_type __ucmpdi2(unsigned long long a, unsigned long long b)
-{
-	const DWunion au = {.ll = a};
-	const DWunion bu = {.ll = b};
-
-	if ((unsigned int) au.s.high < (unsigned int) bu.s.high)
-		return 0;
-	else if ((unsigned int) au.s.high > (unsigned int) bu.s.high)
-		return 2;
-	if ((unsigned int) au.s.low < (unsigned int) bu.s.low)
-		return 0;
-	else if ((unsigned int) au.s.low > (unsigned int) bu.s.low)
-		return 2;
-	return 1;
-}
-EXPORT_SYMBOL(__ucmpdi2);

-- 
2.34.1

