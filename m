From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Tue, 14 Nov 2023 11:22:25 -0600
Subject: [PATCH v2 1/5] powerpc/rtas: Drop declaration of undefined
 call_rtas() function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231114-rtas-trivial-v2-1-59cbab208d57@linux.ibm.com>
References: <20231114-rtas-trivial-v2-0-59cbab208d57@linux.ibm.com>
In-Reply-To: <20231114-rtas-trivial-v2-0-59cbab208d57@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: Andrew Donnellan <ajd@linux.ibm.com>, 
 Hari Bathini <hbathini@linux.ibm.com>, 
 Mahesh Salgaonkar <mahesh@linux.ibm.com>, linuxppc-dev@lists.ozlabs.org, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699982560; l=826;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=yqYsNNWpscBBnfwIq3gGBTDwPfEYG5PijEQAt12Z9Ug=;
 b=bb4l3eSK0ecBknMjqfI6rvh+mZO6l0BVH3Bpv+qtwmpkzjzIS31A+yj6l5qtnW63iemnV2tmA
 kYgd3SJOn8kBGeue8Cp/Qd/lXJzJKBw4XtjseLOk4dyiAI/FTNITYOH
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The call_rtas() function has never been a part of arch/powerpc, and
its implementation was removed from arch/ppc by commit 0a26b1364f14
("ppc: Remove CHRP, POWER3 and POWER4 support from arch/ppc").

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/include/asm/rtas.h | 2 --
 1 file changed, 2 deletions(-)

diff --git a/arch/powerpc/include/asm/rtas.h b/arch/powerpc/include/asm/rtas.h
index c697c3c74694..3bf7f0a4b07e 100644
--- a/arch/powerpc/include/asm/rtas.h
+++ b/arch/powerpc/include/asm/rtas.h
@@ -542,8 +542,6 @@ static inline void pSeries_coalesce_init(void) { }
 static inline void rtas_initialize(void) { }
 #endif
 
-extern int call_rtas(const char *, int, int, unsigned long *, ...);
-
 #ifdef CONFIG_HV_PERF_CTRS
 void read_24x7_sys_info(void);
 #else

-- 
2.41.0

