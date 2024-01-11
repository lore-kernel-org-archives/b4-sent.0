From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 11 Jan 2024 17:47:32 -0600
Subject: [PATCH RFC] powerpc/pseries: exploit H_PAGE_SET_UNUSED for
 partition migration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240111-h_page_set_unused-for-lpm-v1-1-cd56184ad608@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIABN+oGUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDQ0ND3Yz4gsT01Pji1JL40rzS4tQU3bT8It2cglzdFEsDI/NkM3OjtFQ
 LJaD+gqLUtMwKsNnRSkFuzkqxtbUAEWfkUHAAAAA=
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 "Aneesh Kumar K.V" <aneesh.kumar@linux.ibm.com>, 
 "Naveen N. Rao" <naveen.n.rao@linux.ibm.com>, 
 Brian King <brking@linux.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705016866; l=3110;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=QCi+aYIXD+KJwHE/NMLCXj3RgfCu6hT6HPoTPMEKTQE=;
 b=ugyi1ajuyIEOgMBZepRH2Zmbq/HsnGw8iKFxVOLzqV7gXBzP5wWbYUoPQOi7JQCvAyLeAOYHR
 AJVUYmJL3z3AStEOIn11pdccvX/eUsdw119WUzr9imQxQTBXGDalPYO
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Although the H_PAGE_INIT hcall's H_PAGE_SET_UNUSED historically has
been tied to the cooperative memory overcommit (CMO) platform feature,
the flag also is treated by the PowerVM hypervisor as a hint that the
page contents need not be copied to the destination during a live
partition migration.

Use the "ibm,migratable-partition" root node property to determine
whether this partition/guest can be migrated. Mark freed pages unused
if so (or if CMO is in use, as before).

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
Several things yet to improve here:

* powerpc's arch_free_page()/HAVE_ARCH_FREE_PAGE should be decoupled
  from CONFIG_PPC_SMLPAR.

* powerpc's arch_free_page() could be made to use a static key if
  justified.

* I have not yet measured the overhead this introduces, nor have I
  measured the benefit to a live migration.

To date, I have smoke tested it by doing a live migration and
performing a build on a kernel with the change, to ensure it doesn't
introduce obvious memory corruption or anything. It hasn't blown up
yet :-)

This will be a possibly significant behavior change in that we will be
flagging pages unused where we typically did not before. Until now,
having CMO enabled was the only way to do this, and I don't think that
feature is used all that much?

Posting this as RFC to see if there are any major concerns.
---
 arch/powerpc/platforms/pseries/lpar.c | 21 +++++++++++++++------
 1 file changed, 15 insertions(+), 6 deletions(-)

diff --git a/arch/powerpc/platforms/pseries/lpar.c b/arch/powerpc/platforms/pseries/lpar.c
index 4561667832ed..b264371d8e12 100644
--- a/arch/powerpc/platforms/pseries/lpar.c
+++ b/arch/powerpc/platforms/pseries/lpar.c
@@ -16,6 +16,7 @@
 #include <linux/export.h>
 #include <linux/jump_label.h>
 #include <linux/delay.h>
+#include <linux/of.h>
 #include <linux/stop_machine.h>
 #include <linux/spinlock.h>
 #include <linux/cpuhotplug.h>
@@ -1772,17 +1773,25 @@ static void pSeries_set_page_state(struct page *page, int order,
 	}
 }
 
+static bool migratable_partition;
+
 void arch_free_page(struct page *page, int order)
 {
-	if (radix_enabled())
-		return;
-	if (!cmo_free_hint_flag || !firmware_has_feature(FW_FEATURE_CMO))
-		return;
-
-	pSeries_set_page_state(page, order, H_PAGE_SET_UNUSED);
+	if (migratable_partition ||
+	    (firmware_has_feature(FW_FEATURE_CMO) && cmo_free_hint_flag))
+		pSeries_set_page_state(page, order, H_PAGE_SET_UNUSED);
 }
 EXPORT_SYMBOL(arch_free_page);
 
+static int __init check_migratable_partition(void)
+{
+	struct device_node *root = of_find_node_by_path("/");
+	migratable_partition = !!of_find_property(root, "ibm,migratable-partition", NULL);
+	of_node_put(root);
+	return 0;
+}
+machine_device_initcall(pseries, check_migratable_partition);
+
 #endif /* CONFIG_PPC_SMLPAR */
 #endif /* CONFIG_PPC_BOOK3S_64 */
 

---
base-commit: 44a1aad2fe6c10bfe0589d8047057b10a4c18a19
change-id: 20240111-h_page_set_unused-for-lpm-d9027c672fe8

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

