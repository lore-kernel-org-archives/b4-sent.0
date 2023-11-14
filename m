From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Tue, 14 Nov 2023 11:01:54 -0600
Subject: [PATCH 2/3] powerpc/pseries/memhp: Remove unbalanced
 dlpar_release_drc() call
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231114-pseries-memhp-fixes-v1-2-fb8f2bb7c557@linux.ibm.com>
References: <20231114-pseries-memhp-fixes-v1-0-fb8f2bb7c557@linux.ibm.com>
In-Reply-To: <20231114-pseries-memhp-fixes-v1-0-fb8f2bb7c557@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: Nick Child <nnac123@linux.ibm.com>, 
 "Aneesh Kumar K.V" <aneesh.kumar@linux.ibm.com>, 
 Scott Cheloha <cheloha@linux.ibm.com>, linuxppc-dev@lists.ozlabs.org, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699981353; l=1128;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=SI5VGXmes014ZZ4j4BIRL6/6dqnnjMkcnKTZDpxpV2w=;
 b=2AhfoR+rD1s1cjLBKO45hF/+ru+QUnDy7mVNZKNqRvbw4b7+zc0/PUkaadg0Jll9ofFLEsdQc
 R3Dedf8N6e8Bboe/IRvhD3ogSDn/il0f5ZGmZJhr2FwyL8sE/WZWDrk
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Callers of dlpar_add_lmb() are responsible for first acquiring the DRC
and releasing it if dlpar_add_lmb() fails.

However, dlpar_add_lmb() performs a dlpar_release_drc() in one error
branch.  There is no corresponding dlpar_acquire_drc() in the
function, nor is there any stated justification. None of the other
error paths in dlpar_add_lmb() release the DRC.

This is a potential source of redundant attempts to release DRCs,
which is likely benign, but is confusing and inconsistent. Remove it.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/platforms/pseries/hotplug-memory.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/powerpc/platforms/pseries/hotplug-memory.c b/arch/powerpc/platforms/pseries/hotplug-memory.c
index 6f2eebae7bee..ba883c1b9f6d 100644
--- a/arch/powerpc/platforms/pseries/hotplug-memory.c
+++ b/arch/powerpc/platforms/pseries/hotplug-memory.c
@@ -575,7 +575,6 @@ static int dlpar_add_lmb(struct drmem_lmb *lmb)
 
 	rc = update_lmb_associativity_index(lmb);
 	if (rc) {
-		dlpar_release_drc(lmb->drc_index);
 		return rc;
 	}
 

-- 
2.41.0

