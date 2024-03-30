From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 30 Mar 2024 10:57:40 +0100
Subject: [PATCH 04/10] sparc64: Fix prototype warning for
 alloc_irqstack_bootmem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240330-sparc64-warnings-v1-4-37201023ee2f@ravnborg.org>
References: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
In-Reply-To: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
To: Andreas Larsson <andreas@gaisler.com>, 
 "David S. Miller" <davem@davemloft.net>, sparclinux@vger.kernel.org
Cc: Nick Bowler <nbowler@draconx.ca>, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711792675; l=877;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=hR1E8vg8CGDYDik5XN2GQOk33c8EjJhA30OsWe34a5M=;
 b=5y52pp+9cWGwXXEVdYXKKaopN1VKfX8WuRlPMgDaXdoQ0CqhfOyr9569kP/JZSl9fR9ZcPdeOem5
 5YiL5Ib2DKwFLPLfipiRNfAvXMwNmevHWCfz6YrVABfnmoBVIau8
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following warning:
arch/sparc/kernel/setup_64.c:602:13: warning: no previous prototype for ‘alloc_irqstack_bootmem’

The function alloc_irqstack_bootmem had no users outside setup_64.c so
declare it static.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
---
 arch/sparc/kernel/setup_64.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/sparc/kernel/setup_64.c b/arch/sparc/kernel/setup_64.c
index 6a4797dec34b..1d519f18d2b2 100644
--- a/arch/sparc/kernel/setup_64.c
+++ b/arch/sparc/kernel/setup_64.c
@@ -599,7 +599,7 @@ static void __init init_sparc64_elf_hwcap(void)
 		pause_patch();
 }
 
-void __init alloc_irqstack_bootmem(void)
+static void __init alloc_irqstack_bootmem(void)
 {
 	unsigned int i, node;
 

-- 
2.34.1

