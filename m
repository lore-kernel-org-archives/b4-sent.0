From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:17:55 -0400
Subject: [PATCH] pmdomain: renesas: rcar-sysc: publish the external request
 mask
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-rcar-sysc-v1-1-fb25996bb2f4@vt.edu>
X-B4-Tracking: v=1; b=H4sIAELXsWoC/yXM0Q6CMAyF4VchvbYGBg7wVQwX66gyE6dphWgI7
 +6Gl1/T86+gLIEVzsUKwkvQ8IwJ1aEAP7l4YwxjMpjS2LI3FT4IxTtB/apHy62lbuybrj5Bmry
 Er+Gz5y7D3zrTnf07N/IHOWUkcdFP+bRzaY91ijawbT+Df2GbkAAAAA==
X-Change-ID: 20260921-mb-rcar-sysc-6e76b8d94835
To: Ulf Hansson <ulfh@kernel.org>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Magnus Damm <magnus.damm@gmail.com>
Cc: linux-pm@vger.kernel.org, linux-renesas-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790039877; l=2526;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=/J+UZmfWmy/IxE0tQAJ0EO14IUIFzykt/G670AOHT38=;
 b=PEN1vUv1FyPiUHVzj+GEzwZkWrshu6uVQzCS8Oh3jmo/jMz+3NIHX13ht9OgFEhnOwxgbOYrU
 4mJIv8BfmPECUc5oJ/dDTQnanqIaT5P44PbJfshWBGFaFSHYakXXXBp
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rcar_sysc_pd_init() maps the SYSC registers and stores rcar_sysc_base,
rcar_sysc_extmask_offs and rcar_sysc_extmask_val with plain stores,
before it registers the power domains. rcar_sysc_power() tests
rcar_sysc_extmask_val and then writes through rcar_sysc_base at that
offset, from genpd on any CPU.

Publish the mask value last with smp_store_release() and read it once
with smp_load_acquire() in rcar_sysc_power().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/pmdomain/renesas/rcar-sysc.c | 17 +++++++++++++----
 1 file changed, 13 insertions(+), 4 deletions(-)

diff --git a/drivers/pmdomain/renesas/rcar-sysc.c b/drivers/pmdomain/renesas/rcar-sysc.c
index bd7bb9cbd..d0eaaeeb9 100644
--- a/drivers/pmdomain/renesas/rcar-sysc.c
+++ b/drivers/pmdomain/renesas/rcar-sysc.c
@@ -106,15 +106,19 @@ static int rcar_sysc_power(const struct rcar_sysc_pd *pd, bool on)
 	unsigned int chan_mask = BIT(pd->chan_bit);
 	unsigned int status, k;
 	unsigned long flags;
+	u32 extmask_val;
 	int ret;
 
 	spin_lock_irqsave(&rcar_sysc_lock, flags);
 
+	/* Pairs with the smp_store_release() in rcar_sysc_pd_init(). */
+	extmask_val = smp_load_acquire(&rcar_sysc_extmask_val);
+
 	/*
 	 * Mask external power requests for CPU or 3DG domains
 	 */
-	if (rcar_sysc_extmask_val) {
-		iowrite32(rcar_sysc_extmask_val,
+	if (extmask_val) {
+		iowrite32(extmask_val,
 			  rcar_sysc_base + rcar_sysc_extmask_offs);
 	}
 
@@ -157,7 +161,7 @@ static int rcar_sysc_power(const struct rcar_sysc_pd *pd, bool on)
 	iowrite32(isr_mask, rcar_sysc_base + SYSCISCR);
 
  out:
-	if (rcar_sysc_extmask_val)
+	if (extmask_val)
 		iowrite32(0, rcar_sysc_base + rcar_sysc_extmask_offs);
 
 	spin_unlock_irqrestore(&rcar_sysc_lock, flags);
@@ -381,7 +385,12 @@ static int __init rcar_sysc_pd_init(void)
 
 	/* Optional External Request Mask Register */
 	rcar_sysc_extmask_offs = info->extmask_offs;
-	rcar_sysc_extmask_val = info->extmask_val;
+	/*
+	 * rcar_sysc_power() tests rcar_sysc_extmask_val and then uses
+	 * rcar_sysc_base and the offset, so publish the value last, with
+	 * release semantics.
+	 */
+	smp_store_release(&rcar_sysc_extmask_val, info->extmask_val);
 
 	domains = kzalloc_obj(*domains);
 	if (!domains) {

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-rcar-sysc-6e76b8d94835

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

