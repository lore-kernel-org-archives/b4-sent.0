From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 30 Mar 2024 10:57:46 +0100
Subject: [PATCH 10/10] sparc64: Fix prototype warnings for vdso
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240330-sparc64-warnings-v1-10-37201023ee2f@ravnborg.org>
References: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
In-Reply-To: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
To: Andreas Larsson <andreas@gaisler.com>, 
 "David S. Miller" <davem@davemloft.net>, sparclinux@vger.kernel.org
Cc: Nick Bowler <nbowler@draconx.ca>, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711792675; l=2638;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=R3MJg/E/GhMxnu0wstTitJ5mJt9vPs+kNGIj3nVyBSg=;
 b=4VEx0rmCrYuq7fkcXCME2F2VaTvqyGizSK4moRhBlf1ov0rAPRrYYeczpL2dZngQSGnIn9AKOHKW
 VHWtcmrbCPy4hZGFW+ksDOU06O+Ax51RL6YmSQBF7KdC78OA3ryF
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following warnings:
arch/sparc/vdso/vclock_gettime.c:254:1: error: no previous prototype for ‘__vdso_clock_gettime’
arch/sparc/vdso/vclock_gettime.c:282:1: error: no previous prototype for ‘__vdso_clock_gettime_stick’
arch/sparc/vdso/vclock_gettime.c:307:1: error: no previous prototype for ‘__vdso_gettimeofday’
arch/sparc/vdso/vclock_gettime.c:343:1: error: no previous prototype for ‘__vdso_gettimeofday_stick’
arch/sparc/vdso/vdso32/../vclock_gettime.c:254:1: error: no previous prototype for ‘__vdso_clock_gettime’
arch/sparc/vdso/vdso32/../vclock_gettime.c:282:1: error: no previous prototype for ‘__vdso_clock_gettime_stick’
arch/sparc/vdso/vdso32/../vclock_gettime.c:307:1: error: no previous prototype for ‘__vdso_gettimeofday’
arch/sparc/vdso/vdso32/../vclock_gettime.c:343:1: error: no previous prototype for ‘__vdso_gettimeofday_stick’

The warnings were fixed by adding the proper prototypes to asm/vdso.h.
The better fix would be to convert sparc to be y2038 compliant so the
generic variant of vdso.h could be used.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
Cc: Arnd Bergmann <arnd@arndb.de>
---
 arch/sparc/include/asm/vdso.h    | 10 ++++++++++
 arch/sparc/vdso/vclock_gettime.c |  1 +
 2 files changed, 11 insertions(+)

diff --git a/arch/sparc/include/asm/vdso.h b/arch/sparc/include/asm/vdso.h
index 59e79d35cd73..af630cad185c 100644
--- a/arch/sparc/include/asm/vdso.h
+++ b/arch/sparc/include/asm/vdso.h
@@ -5,6 +5,16 @@
 #ifndef _ASM_SPARC_VDSO_H
 #define _ASM_SPARC_VDSO_H
 
+#include <linux/linkage.h>
+#include <linux/time.h>
+#include <linux/time_types.h>
+#include <linux/types.h>
+
+notrace int __vdso_clock_gettime(clockid_t clock, struct __kernel_old_timespec *ts);
+notrace int __vdso_clock_gettime_stick(clockid_t clock, struct __kernel_old_timespec *ts);
+notrace int __vdso_gettimeofday(struct __kernel_old_timeval *tv, struct timezone *tz);
+notrace int __vdso_gettimeofday_stick(struct __kernel_old_timeval *tv, struct timezone *tz);
+
 struct vdso_image {
 	void *data;
 	unsigned long size;   /* Always a multiple of PAGE_SIZE */
diff --git a/arch/sparc/vdso/vclock_gettime.c b/arch/sparc/vdso/vclock_gettime.c
index e794edde6755..a3f85d9cea52 100644
--- a/arch/sparc/vdso/vclock_gettime.c
+++ b/arch/sparc/vdso/vclock_gettime.c
@@ -19,6 +19,7 @@
 #include <asm/unistd.h>
 #include <asm/timex.h>
 #include <asm/clocksource.h>
+#include <asm/vdso.h>
 #include <asm/vvar.h>
 
 #ifdef	CONFIG_SPARC64

-- 
2.34.1

