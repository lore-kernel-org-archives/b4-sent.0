From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 20:47:08 -0400
Subject: [PATCH] soc: fsl: qbman: order the probed flags with
 release/acquire
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-qbman-v1-1-35f3321aa330@vt.edu>
X-B4-Tracking: v=1; b=H4sIAAvQsWoC/yXMQQ7CMAwEwK9UPmOUhlAKX0Ec4uBQIzWAAxVS1
 b+TlOOsdneGzCqc4dTMoDxJlkcqaDcNhMGnG6Nci8Ea25mjbXEkfNHoE/Yu7juOJvYuQKk/laN
 816vz5e/8oTuHd93XBvnMSOpTGGq0cjpsd6jBwbL8APRh8cuMAAAA
X-Change-ID: 20260921-mb-qbman-84f56ef0f84c
To: "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>
Cc: linuxppc-dev@lists.ozlabs.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790038031; l=5060;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=fT0InRMlMFbZ9CKVfdOgEtwLmnpvFnvqHzVcYJmm3RA=;
 b=dfSMjLLaNzAGsFr3S0RP9Qjbm7gVRjFVsP27ngUULTv6uXzFilh88P58W/+zlBX4bIuxmW63r
 m/PPbt94y/+BJ1+VKHc5/9AurqvVnFu/NlOkiHhF/JBjoaZ+uOYOS8F
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dpaa_eth, caam and the portal drivers poll qman_is_probed(),
bman_is_probed(), qman_portals_probed() and bman_portals_probed() before
they touch the state the probe functions set up: qman_ip_rev, the CCSR
and portal register maps, the FQD and PFDR bases, affine_portals and the
pool allocators.

Each flag is set with a plain store at the end of its probe function and
read with a plain load in the exported accessor. The stores that build
the state are not ordered before the store to the flag, and the
consumer's load of the flag is not ordered before its loads of the
state. A consumer probing on another CPU can see the flag set and then
read state that is still stale or zeroed, and program the hardware with
it.

Set the flags with smp_store_release() and read them with
smp_load_acquire(). The error paths storing -1 keep their plain stores:
a consumer that sees -1 fails its own probe without touching the state.

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/soc/fsl/qbman/bman_ccsr.c   |  6 ++++--
 drivers/soc/fsl/qbman/bman_portal.c |  6 ++++--
 drivers/soc/fsl/qbman/qman_ccsr.c   | 11 +++++++++--
 drivers/soc/fsl/qbman/qman_portal.c |  6 ++++--
 4 files changed, 21 insertions(+), 8 deletions(-)

diff --git a/drivers/soc/fsl/qbman/bman_ccsr.c b/drivers/soc/fsl/qbman/bman_ccsr.c
index b0f26f6f7..c5be35aba 100644
--- a/drivers/soc/fsl/qbman/bman_ccsr.c
+++ b/drivers/soc/fsl/qbman/bman_ccsr.c
@@ -180,7 +180,8 @@ static irqreturn_t bman_isr(int irq, void *ptr)
 
 int bman_is_probed(void)
 {
-	return __bman_probed;
+	/* Pairs with smp_store_release() in fsl_bman_probe(). */
+	return smp_load_acquire(&__bman_probed);
 }
 EXPORT_SYMBOL_GPL(bman_is_probed);
 
@@ -279,7 +280,8 @@ static int fsl_bman_probe(struct platform_device *pdev)
 		return ret;
 	}
 
-	__bman_probed = 1;
+	/* Order bm_ccsr_start, bman_ip_rev and the pool allocator before the flag. */
+	smp_store_release(&__bman_probed, 1);
 
 	return 0;
 };
diff --git a/drivers/soc/fsl/qbman/bman_portal.c b/drivers/soc/fsl/qbman/bman_portal.c
index 4d7b9caee..056fe3fbb 100644
--- a/drivers/soc/fsl/qbman/bman_portal.c
+++ b/drivers/soc/fsl/qbman/bman_portal.c
@@ -90,7 +90,8 @@ static int bman_online_cpu(unsigned int cpu)
 
 int bman_portals_probed(void)
 {
-	return __bman_portals_probed;
+	/* Pairs with smp_store_release() in bman_portal_probe(). */
+	return smp_load_acquire(&__bman_portals_probed);
 }
 EXPORT_SYMBOL_GPL(bman_portals_probed);
 
@@ -157,7 +158,8 @@ static int bman_portal_probe(struct platform_device *pdev)
 	spin_lock(&bman_lock);
 	cpu = cpumask_first_zero(&portal_cpus);
 	if (cpu >= nr_cpu_ids) {
-		__bman_portals_probed = 1;
+		/* All CPU-bound portals are initialised and in affine_bportals. */
+		smp_store_release(&__bman_portals_probed, 1);
 		/* unassigned portal, skip init */
 		spin_unlock(&bman_lock);
 		goto check_cleanup;
diff --git a/drivers/soc/fsl/qbman/qman_ccsr.c b/drivers/soc/fsl/qbman/qman_ccsr.c
index aa5348f49..b46cfb964 100644
--- a/drivers/soc/fsl/qbman/qman_ccsr.c
+++ b/drivers/soc/fsl/qbman/qman_ccsr.c
@@ -711,7 +711,8 @@ static int qman_resource_init(struct device *dev)
 
 int qman_is_probed(void)
 {
-	return __qman_probed;
+	/* Pairs with smp_store_release() in fsl_qman_probe(). */
+	return smp_load_acquire(&__qman_probed);
 }
 EXPORT_SYMBOL_GPL(qman_is_probed);
 
@@ -864,7 +865,13 @@ static int fsl_qman_probe(struct platform_device *pdev)
 	if (ret)
 		return ret;
 
-	__qman_probed = 1;
+	/*
+	 * Publish the flag only after every store made above (qman_ip_rev,
+	 * qm_ccsr_start, the FQD/PFDR bases, the work queue) is visible to
+	 * the consumers that poll qman_is_probed() and then call into
+	 * qman_set_sdest(), qman_liodn_fixup(), qman_alloc_*().
+	 */
+	smp_store_release(&__qman_probed, 1);
 
 	return 0;
 }
diff --git a/drivers/soc/fsl/qbman/qman_portal.c b/drivers/soc/fsl/qbman/qman_portal.c
index 456ef5d5c..181c0f373 100644
--- a/drivers/soc/fsl/qbman/qman_portal.c
+++ b/drivers/soc/fsl/qbman/qman_portal.c
@@ -175,7 +175,8 @@ static int qman_online_cpu(unsigned int cpu)
 
 int qman_portals_probed(void)
 {
-	return __qman_portals_probed;
+	/* Pairs with smp_store_release() in qman_portal_probe(). */
+	return smp_load_acquire(&__qman_portals_probed);
 }
 EXPORT_SYMBOL_GPL(qman_portals_probed);
 
@@ -251,7 +252,8 @@ static int qman_portal_probe(struct platform_device *pdev)
 	spin_lock(&qman_lock);
 	cpu = cpumask_first_zero(&portal_cpus);
 	if (cpu >= nr_cpu_ids) {
-		__qman_portals_probed = 1;
+		/* All CPU-bound portals are initialised and in affine_portals. */
+		smp_store_release(&__qman_portals_probed, 1);
 		/* unassigned portal, skip init */
 		spin_unlock(&qman_lock);
 		goto check_cleanup;

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-qbman-84f56ef0f84c

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

