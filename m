From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Nov 2023 07:42:53 -0600
Subject: [PATCH 1/7] powerpc/pseries/rtas-work-area: Fix
 rtas_work_area_reserve_arena() kernel-doc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231106-rtas-trivial-v1-1-61847655c51f@linux.ibm.com>
References: <20231106-rtas-trivial-v1-0-61847655c51f@linux.ibm.com>
In-Reply-To: <20231106-rtas-trivial-v1-0-61847655c51f@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>, 
 kernel test robot <lkp@intel.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699278208; l=1096;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=SPblNQSOeY7KfFeIri1eXB1+jA3JaMamORCx6F8Rpj8=;
 b=ClSDmi29HMUQ/80JEN74l2GYbpkCJCraOELVtZVWM4BcHjR7EoGR+7y05tlobqs+rzevFc2hq
 6MLMgp4jhM2Boo7+J9i7RqIMaewoL1EYzk+C1iev6c+dYScV+gBgK7z
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From a W=1 build:

>> arch/powerpc/platforms/pseries/rtas-work-area.c:189: warning: Function parameter or member 'limit' not
>> described in 'rtas_work_area_reserve_arena'

Add the missing description of the limit parameter.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202309131221.Bm1pg96n-lkp@intel.com/
---
 arch/powerpc/platforms/pseries/rtas-work-area.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/powerpc/platforms/pseries/rtas-work-area.c b/arch/powerpc/platforms/pseries/rtas-work-area.c
index b37d52f40360..7fe34bee84d8 100644
--- a/arch/powerpc/platforms/pseries/rtas-work-area.c
+++ b/arch/powerpc/platforms/pseries/rtas-work-area.c
@@ -184,6 +184,7 @@ machine_arch_initcall(pseries, rtas_work_area_allocator_init);
 
 /**
  * rtas_work_area_reserve_arena() - Reserve memory suitable for RTAS work areas.
+ * @limit: Upper limit for memblock allocation.
  */
 void __init rtas_work_area_reserve_arena(const phys_addr_t limit)
 {

-- 
2.41.0

