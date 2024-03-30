From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 30 Mar 2024 10:57:44 +0100
Subject: [PATCH 08/10] sparc64: Fix prototype warning for sched_clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240330-sparc64-warnings-v1-8-37201023ee2f@ravnborg.org>
References: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
In-Reply-To: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
To: Andreas Larsson <andreas@gaisler.com>, 
 "David S. Miller" <davem@davemloft.net>, sparclinux@vger.kernel.org
Cc: Nick Bowler <nbowler@draconx.ca>, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711792675; l=793;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=LqRShLF2pPHi8lE2rdN92NEyqocrs1j4uVYYbMfSLj4=;
 b=PMlAy600lZhsdddNHFih9ANgCUb2ySEAKULe4KxaXQj8cNuE9rH8bUgekUv0O74HWlQK3QFI8FQT
 6K32pHisBTZybIa4zA2VFCw4AylacJr627XuYudCqRPoXxaNfq7O
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following warning:
arch/sparc/kernel/time_64.c:880:20: warning: no previous prototype for ‘sched_clock’

Add the missing include to pick up the prototype.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
---
 arch/sparc/kernel/time_64.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/sparc/kernel/time_64.c b/arch/sparc/kernel/time_64.c
index 89fb05f90609..60f1c8cc5363 100644
--- a/arch/sparc/kernel/time_64.c
+++ b/arch/sparc/kernel/time_64.c
@@ -33,6 +33,7 @@
 #include <linux/clockchips.h>
 #include <linux/clocksource.h>
 #include <linux/platform_device.h>
+#include <linux/sched/clock.h>
 #include <linux/ftrace.h>
 
 #include <asm/oplib.h>

-- 
2.34.1

