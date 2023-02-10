From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 10 Feb 2023 12:41:55 -0600
Subject: [PATCH v3 07/20] powerpc/pseries: drop RTAS-based timebase
 synchronization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230125-b4-powerpc-rtas-queue-v3-7-26929c8cce78@linux.ibm.com>
References: <20230125-b4-powerpc-rtas-queue-v3-0-26929c8cce78@linux.ibm.com>
In-Reply-To: <20230125-b4-powerpc-rtas-queue-v3-0-26929c8cce78@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Kajol Jain <kjain@linux.ibm.com>, Laurent Dufour <ldufour@linux.ibm.com>, 
 Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Andrew Donnellan <ajd@linux.ibm.com>, Nick Child <nnac123@linux.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1676054526; l=1232;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=tFcGWQ1AkW6nsQJJK1c3LerD+9XTZywFqC0rfZVIXdk=;
 b=073kWWTozS7BkWAgIlJfebvtMnw02sIqmZeNfn5fYkl5mJdlvRZzf6NQnMl6rc2qvYWEdaxI1
 WZssuATaRnyC06PtvxQpyWoP1dDArR8Ppcq7cS5YDcnSRQsKMZcA/Do
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

The pseries platform has been LPAR-only for several generations, and
the PAPR spec:

* Guarantees that timebase synchronization is performed by
  the platform ("The timebase registers are synchronized by the
  platform before CPUs are given to the OS" - 7.3.8 SMP Support).

* Completely omits the RTAS freeze-time-base and thaw-time-base RTAS
  functions, which are CHRP artifacts.

This code is effectively unused on currently supported models, so drop
it.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/platforms/pseries/smp.c | 6 ------
 1 file changed, 6 deletions(-)

diff --git a/arch/powerpc/platforms/pseries/smp.c b/arch/powerpc/platforms/pseries/smp.c
index fd2174edfa1d..2bcfee86ff87 100644
--- a/arch/powerpc/platforms/pseries/smp.c
+++ b/arch/powerpc/platforms/pseries/smp.c
@@ -278,11 +278,5 @@ void __init smp_init_pseries(void)
 		cpumask_clear_cpu(boot_cpuid, of_spin_mask);
 	}
 
-	/* Non-lpar has additional take/give timebase */
-	if (rtas_token("freeze-time-base") != RTAS_UNKNOWN_SERVICE) {
-		smp_ops->give_timebase = rtas_give_timebase;
-		smp_ops->take_timebase = rtas_take_timebase;
-	}
-
 	pr_debug(" <- smp_init_pSeries()\n");
 }

-- 
2.39.1

