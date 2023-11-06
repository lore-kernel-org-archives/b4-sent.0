From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Nov 2023 07:42:55 -0600
Subject: [PATCH 3/7] powerpc/rtas: Drop declaration of undefined
 call_rtas() function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231106-rtas-trivial-v1-3-61847655c51f@linux.ibm.com>
References: <20231106-rtas-trivial-v1-0-61847655c51f@linux.ibm.com>
In-Reply-To: <20231106-rtas-trivial-v1-0-61847655c51f@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699278208; l=819;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=UucQCjGJjbfL7SCFKJ6ZxnKyesG0uLC3Uuvu74A3Tv4=;
 b=CQbUgxnI9zw0h7Y5LYrKLnfGzCKSz1ZDD/0hSmycp+3MW0slUDRwdn1VF8R06HkmuKZFqgvGb
 X+Fk3lB00t+AgC7i4qyZu4Hmq+yk4uA5AvtWv1JhIdeAUwlwCy36xmK
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The call_rtas() function has never been a part of arch/powerpc, and
its implementation was removed from arch/ppc by 0a26b1364f14 ("ppc:
Remove CHRP, POWER3 and POWER4 support from arch/ppc").

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

