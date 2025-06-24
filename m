From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 24 Jun 2025 22:05:49 +0200
Subject: [PATCH RFC 2/7] nvme: Add cdq data structure to nvme_ctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250624-jag-cdq-v1-2-6d88476c9165@kernel.org>
References: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
In-Reply-To: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
To: joshi.k@samsung.com
Cc: Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2081;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=eL+MfX1V8Mfw/6f5jaBeMGhJRWRE2FDY6L9HT7HNVLw=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhbBR4p5F6zwTMm8qMwLM/AExCyNkcvPCQ/g
 r/WwgjRuHyTL4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoWwUeAAoJELqXzVK3
 lkFP0U8L/1Ns5b2QEr23wB20VwlOSJ9RMvxGxgrSCug9IwJ67hEoPyZIy2kBK4Aan2KE91vKhHw
 uXztC0ePFYmKceGws64c9qEgSX9rRnBHI1KTa/GLNFhRqLl75nvwqfcFJ1+ZGNRcFRelH1Gt0Ki
 ug3cGPALWywGQHT/5h0SLRa52qSKuDnVFBkwCJFiogsU1/3ic3SJMDKzZsO8fRUw437Rn1Yv6dk
 JCPahmO9fF9leFr83CcS+2pDN01WD0vrhk1WN6rPwH+wgMiW+R8vofCqDgUC+MIpX93kp4iQtxg
 /1vluoBYrgeTOIlC/Ct8y2wtWpgJPdBBCMZgkC9aS6Rq/1Jk+G/vavKe3JzkFjVLq6u/kBqjodH
 JJYI9KgoNLYw1hIjCpoowe7w8cIrLh97KFtUGBpzuaXSNPYYBG4Iqgdvex9kx1VQgRwshvzv3jb
 QrJnLzPAwSQyA9OmEC4zz9nL5rapR36KrMwzssu/OzpLcXa4wm0oIlfZ4Oy1OqSVaYVtVXvsD63
 kQ=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a CDQ xarray to nvme_ctrl allowing for several CDQs per controller
(as per specification). The structure will house a pointer to its
controller (*ctrl), a pointer to the entry memory (*entries), number and
size of entries, current entry and phase bit value, the location of the
phase bit value within an entry, dma address, CDQ id and the file
pointer where the reading will be taking place.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/core.c |  1 +
 drivers/nvme/host/nvme.h | 15 +++++++++++++++
 2 files changed, 16 insertions(+)

diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index 7be6b42a1adcc3fdb3cec2e2d0e73fcf74244590..9b2de74d62f7a65aea2d28bbbed6681195d9afcd 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -4868,6 +4868,7 @@ int nvme_init_ctrl(struct nvme_ctrl *ctrl, struct device *dev,
 	mutex_init(&ctrl->scan_lock);
 	INIT_LIST_HEAD(&ctrl->namespaces);
 	xa_init(&ctrl->cels);
+	xa_init(&ctrl->cdqs);
 	ctrl->dev = dev;
 	ctrl->ops = ops;
 	ctrl->quirks = quirks;
diff --git a/drivers/nvme/host/nvme.h b/drivers/nvme/host/nvme.h
index 8fc4683418a3a6929311c7b56da90ebcbbe16d86..800970a0bb87f7a3b6e855f56a2493a7deed1ecd 100644
--- a/drivers/nvme/host/nvme.h
+++ b/drivers/nvme/host/nvme.h
@@ -411,6 +411,7 @@ struct nvme_ctrl {
 	enum nvme_ctrl_type cntrltype;
 	enum nvme_dctype dctype;
 	u16 awupf; /* 0's based value. */
+	struct xarray cdqs; /* Controller Data Queue */
 };
 
 static inline enum nvme_ctrl_state nvme_ctrl_state(struct nvme_ctrl *ctrl)
@@ -553,6 +554,20 @@ static inline bool nvme_ns_has_pi(struct nvme_ns_head *head)
 	return head->pi_type && head->ms == head->pi_size;
 }
 
+struct cdq_nvme_queue {
+	struct nvme_ctrl *ctrl;
+	void *entries;
+	u32 entry_nbyte;
+	u32 entry_nr;
+	u32 curr_entry;
+	u8 curr_cdqp;
+	uint cdqp_offset;
+	uint cdqp_mask;
+	dma_addr_t entries_dma_addr;
+	u16 cdq_id;
+	struct file *filep;
+};
+
 struct nvme_ctrl_ops {
 	const char *name;
 	struct module *module;

-- 
2.47.2

