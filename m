From: Kyle Farnung <kfarnung@gmail.com>
Date: Wed, 13 May 2026 21:52:12 -0700
Subject: [PATCH] wifi: ath11k: clear shared SRNG pointer state on restart
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260513-kfarnung-ath11k-srng-clear-pointer-state-v1-1-bc700dd8b333@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2NywrCQAwAf6XkbGCzUl+/Ih5im7ahkpZkFaH03
 128zVxmNghxlYBbs4HLR0MXq0KHBrqJbRTUvjrklE+ppSPOA7u9bUQuE9GM4ZW7l7DjuqgVcYz
 CRfBK/YWf6SytZKi51WXQ7391f+z7D53Sk4N6AAAA
X-Change-ID: 20260513-kfarnung-ath11k-srng-clear-pointer-state-91d8ab07e5e2
To: Jeff Johnson <jjohnson@kernel.org>, 
 Muhammad Usama Anjum <usama.anjum@arm.com>, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>
Cc: Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, santiagorr@riseup.net, stable@vger.kernel.org, 
 Kyle Farnung <kfarnung@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778734359; l=3434;
 i=kfarnung@gmail.com; s=20260330; h=from:subject:message-id;
 bh=XJuJhNZPkZzqwmUgFybWgxjzGDftVSfNEsebbvGwSDA=;
 b=uj7RAdlKe6Dq/MwIimfTIXag4PerG+bL1bff/qD6gwXGRjbtWzbh36slDaJOSLak3IznIwRpm
 ar/zYfA0NsxAGXHHHBc4Xm9CJt9sATCa6ej8etG2xVD+0f9x5qdbc0l
X-Developer-Key: i=kfarnung@gmail.com; a=ed25519;
 pk=47jis5OdLKFgZynNQVqkx1mTGiEgFTUX+MecmG9rbmE=
X-Endpoint-Received: by B4 Relay for kfarnung@gmail.com/20260330 with auth_id=706
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

LMAC rings reuse the shared rdp/wrp pointer buffers without going
through the normal SRNG hw-init path that zeros non-LMAC ring
pointers. After restart, ath11k_hal_srng_clear() can therefore hand
stale hp/tp state from the previous firmware instance back to the new
one.

Clear the shared pointer buffers while keeping the allocations in
place so restart still avoids reallocating SRNG DMA memory, but starts
with fresh ring-pointer state.

Fixes: 32be3ca4cf78b ("wifi: ath11k: HAL SRNG: don't deinitialize and re-initialize again")
Cc: stable@vger.kernel.org
Link: https://lore.kernel.org/all/CAOPSVF04q6uvVdq8GTRLHBrVMdpt9=o9wVcFMc6f-yhmSBcZqQ@mail.gmail.com/
Signed-off-by: Kyle Farnung <kfarnung@gmail.com>
---
This patch is the result of investigating suspend/resume failures on a
Lenovo ThinkPad P14s Gen 5 AMD with ath11k.

I originally proposed extending the existing ath11k PM quirk for this
platform, but after discussion in [1] and bisection the issue appears to
be a regression introduced by [2]. There is also a parallel report in [3]
that appears consistent with the same root cause. This patch keeps the
intended no-reallocation behavior from that change, but clears the
preserved shared SRNG pointer state so restart begins from a clean state.

Testing so far has been limited to local suspend/resume cycling on the
affected system. The issue was originally reproduced on v7.0.4, and the
patch was also built and tested on top of ath-current with repeated
suspend/resume cycles on a Lenovo ThinkPad P14s Gen 5 AMD.

[1] https://lore.kernel.org/all/CAOPSVF04q6uvVdq8GTRLHBrVMdpt9=o9wVcFMc6f-yhmSBcZqQ@mail.gmail.com/
[2] 32be3ca4cf78b ("wifi: ath11k: HAL SRNG: don't deinitialize and re-initialize again")
[3] https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1132343
---
 drivers/net/wireless/ath/ath11k/hal.c | 13 ++++++++++---
 1 file changed, 10 insertions(+), 3 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/hal.c b/drivers/net/wireless/ath/ath11k/hal.c
index e821e5a62c1c0..0c0aeb803018e 100644
--- a/drivers/net/wireless/ath/ath11k/hal.c
+++ b/drivers/net/wireless/ath/ath11k/hal.c
@@ -1387,14 +1387,21 @@ EXPORT_SYMBOL(ath11k_hal_srng_deinit);
 
 void ath11k_hal_srng_clear(struct ath11k_base *ab)
 {
-	/* No need to memset rdp and wrp memory since each individual
-	 * segment would get cleared in ath11k_hal_srng_src_hw_init()
-	 * and ath11k_hal_srng_dst_hw_init().
+	/* Preserve the shared pointer buffers, but clear the previous
+	 * firmware instance's hp/tp state before handing them back to FW.
+	 * LMAC rings reuse this shared memory without going through the
+	 * normal SRNG hw-init path that zeros non-LMAC ring pointers.
 	 */
 	memset(ab->hal.srng_list, 0,
 	       sizeof(ab->hal.srng_list));
 	memset(ab->hal.shadow_reg_addr, 0,
 	       sizeof(ab->hal.shadow_reg_addr));
+	if (ab->hal.rdp.vaddr)
+		memset(ab->hal.rdp.vaddr, 0,
+		       sizeof(*ab->hal.rdp.vaddr) * HAL_SRNG_RING_ID_MAX);
+	if (ab->hal.wrp.vaddr)
+		memset(ab->hal.wrp.vaddr, 0,
+		       sizeof(*ab->hal.wrp.vaddr) * HAL_SRNG_NUM_LMAC_RINGS);
 	ab->hal.avail_blk_resource = 0;
 	ab->hal.current_blk_index = 0;
 	ab->hal.num_shadow_reg_configured = 0;

---
base-commit: 54a5b38e4396530e5b2f12b54d3844e860ab6784
change-id: 20260513-kfarnung-ath11k-srng-clear-pointer-state-91d8ab07e5e2

Best regards,
-- 
Kyle Farnung <kfarnung@gmail.com>

