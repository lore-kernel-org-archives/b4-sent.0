From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Tue, 14 Nov 2023 11:01:55 -0600
Subject: [PATCH 3/3] powerpc/pseries/memhp: Log more error conditions in
 add path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231114-pseries-memhp-fixes-v1-3-fb8f2bb7c557@linux.ibm.com>
References: <20231114-pseries-memhp-fixes-v1-0-fb8f2bb7c557@linux.ibm.com>
In-Reply-To: <20231114-pseries-memhp-fixes-v1-0-fb8f2bb7c557@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: Nick Child <nnac123@linux.ibm.com>, 
 "Aneesh Kumar K.V" <aneesh.kumar@linux.ibm.com>, 
 Scott Cheloha <cheloha@linux.ibm.com>, linuxppc-dev@lists.ozlabs.org, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699981353; l=1765;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=OECSKa6t5Y+xw/dFXWQT+ZAW2UYSta5I9dOlL6VIXK0=;
 b=dpLpHPs0Ley06//CDlZvN2nxA6S6q9hWibBMvLImKezkUooMo/To8Nz4w7f9NF1NDFO4tSZQJ
 lHvRUjelc0uC0qO9H7SwQ0dRFb9b/CXrmYMyKBpqf+7OEIbQO8M83zw
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When an add operation for multiple LMBs fails, there is currently
little indication from the kernel of what went wrong. Be a little more
verbose about error conditions in the add paths.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/platforms/pseries/hotplug-memory.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/arch/powerpc/platforms/pseries/hotplug-memory.c b/arch/powerpc/platforms/pseries/hotplug-memory.c
index ba883c1b9f6d..4896920514f3 100644
--- a/arch/powerpc/platforms/pseries/hotplug-memory.c
+++ b/arch/powerpc/platforms/pseries/hotplug-memory.c
@@ -208,8 +208,10 @@ static int dlpar_change_lmb_state(struct drmem_lmb *lmb, bool online)
 	int rc;
 
 	mem_block = lmb_to_memblock(lmb);
-	if (!mem_block)
+	if (!mem_block) {
+		pr_err("Failed memory block lookup for LMB 0x%x\n", lmb->drc_index);
 		return -EINVAL;
+	}
 
 	if (online && mem_block->dev.offline)
 		rc = device_online(&mem_block->dev);
@@ -575,6 +577,7 @@ static int dlpar_add_lmb(struct drmem_lmb *lmb)
 
 	rc = update_lmb_associativity_index(lmb);
 	if (rc) {
+		pr_err("Failed to configure LMB 0x%x\n", lmb->drc_index);
 		return rc;
 	}
 
@@ -588,12 +591,14 @@ static int dlpar_add_lmb(struct drmem_lmb *lmb)
 	/* Add the memory */
 	rc = __add_memory(nid, lmb->base_addr, block_sz, MHP_MEMMAP_ON_MEMORY);
 	if (rc) {
+		pr_err("Failed to add LMB 0x%x to node %u", lmb->drc_index, nid);
 		invalidate_lmb_associativity_index(lmb);
 		return rc;
 	}
 
 	rc = dlpar_online_lmb(lmb);
 	if (rc) {
+		pr_err("Failed to online LMB 0x%x on node %u\n", lmb->drc_index, nid);
 		__remove_memory(lmb->base_addr, block_sz);
 		invalidate_lmb_associativity_index(lmb);
 	} else {

-- 
2.41.0

