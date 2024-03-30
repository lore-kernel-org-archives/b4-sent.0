From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 30 Mar 2024 10:57:39 +0100
Subject: [PATCH 03/10] sparc64: Fix prototype warning for vmemmap_free
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240330-sparc64-warnings-v1-3-37201023ee2f@ravnborg.org>
References: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
In-Reply-To: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
To: Andreas Larsson <andreas@gaisler.com>, 
 "David S. Miller" <davem@davemloft.net>, sparclinux@vger.kernel.org
Cc: Nick Bowler <nbowler@draconx.ca>, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711792675; l=1023;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=+iIEu1z65nIiaVFud5jDAU2EF2qjq+E//QvstvA1vGg=;
 b=5VSMXsJDe14dfB5oOTmmYLuyPXBP0AEI7kkhlo+yFPQJH9hBDtSPFVLukEaLXfZBrY9t+daDfF0L
 L8uXsXFQCPOI5uioh9DGaOBI8cOkimdx9zSDJ9alHiqMpCCrM+VV
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following warning:
arch/sparc/mm/init_64.c:2644:6: warning: no previous prototype for ‘vmemmap_free’

The function vmemmap_free() is only used for systems with
CONFIG_MEMORY_HOTPLUG defined - and sparc64 do not support this.
Drop the empty function as it has no users.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
---
 arch/sparc/mm/init_64.c | 5 -----
 1 file changed, 5 deletions(-)

diff --git a/arch/sparc/mm/init_64.c b/arch/sparc/mm/init_64.c
index f83017992eaa..5444b515815a 100644
--- a/arch/sparc/mm/init_64.c
+++ b/arch/sparc/mm/init_64.c
@@ -2640,11 +2640,6 @@ int __meminit vmemmap_populate(unsigned long vstart, unsigned long vend,
 
 	return 0;
 }
-
-void vmemmap_free(unsigned long start, unsigned long end,
-		struct vmem_altmap *altmap)
-{
-}
 #endif /* CONFIG_SPARSEMEM_VMEMMAP */
 
 /* These are actually filled in at boot time by sun4{u,v}_pgprot_init() */

-- 
2.34.1

