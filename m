From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 14 Jul 2025 11:15:33 +0200
Subject: [PATCH RFC 2/8] nvme: Add cdq data structure to nvme_ctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250714-jag-cdq-v1-2-01e027d256d5@kernel.org>
References: <20250714-jag-cdq-v1-0-01e027d256d5@kernel.org>
In-Reply-To: <20250714-jag-cdq-v1-0-01e027d256d5@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>
Cc: Klaus Jensen <k.jensen@samsung.com>, linux-nvme@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2081;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=eL+MfX1V8Mfw/6f5jaBeMGhJRWRE2FDY6L9HT7HNVLw=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGh0yuoiMgo9kvgQ2onuXE5Bzm5EOPldHUWSc
 djDt0GXzv++i4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJodMrqAAoJELqXzVK3
 lkFP7x8L/RbyrP9gWDYhZxH9l/ZFBQRLh1tU1lEpjnC+0l19BplIU233ls4Nb8jufwEnNM7UXmN
 f34Xd5pqD5X40TutgIT8NCx6ZAplYlm9cvfQN3nfMhJrOXNGFWrDh0SkoKAEikhlRDdbVJndHWF
 mppIYEWpeOoeJ1zPkyAx1tZE6luI6kkewQQVx9rCcRZyWd3oIceHT9EGPHsbOcJmXPUbtZrLE+h
 QXZUiib2GpEy7fV+FC6SjUCmbGlF8uX6lb6S1FkEX5qwYJc+1tk6THS4WelQDLvzcMOz2Bd8agG
 GCUVM2syC+eJ90IExrl4TOnJvouuzVBVY15ZnouJAs+PoQoIYSuC/RprqqbEer9SILxB5rQ/N0e
 rMlK4zTRYFWu4HJuptuMg8TMhkFJckLIA17dcGvxHgi8dTWm7AMlCbrKBAteyvQWPasB5nsUi/K
 4hHwBLWURwHEQuJLDr9OTSGPBX6b7QcLUnvujeCj42X5ZJ/+a4HfF2MswcEi9uLEQkmzqe8+rI5
 Jo=
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

