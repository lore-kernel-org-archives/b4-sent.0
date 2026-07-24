From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 24 Jul 2026 13:11:02 +0200
Subject: [PATCH RFC v2 08/14] nvme: Submit track send command to start/stop
 the CDQ
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-jag-cdq-lkml-v2-8-659a7449e849@kernel.org>
References: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
In-Reply-To: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <chaitanyak@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1887;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=ypeS95ojXjYSmQZdAQ3ygCTtEie40Z+4aoiipnBi1C4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGpjSF3qt02lMyoQAxLyN+Ufsbey5R1oBWRge
 s76TvRR5comzIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqY0hdAAoJELqXzVK3
 lkFP0IUMAIQJ5olp+m448keWCoxcK9QwftwDHNiRBHzNCtDgZlvYKDrDm6iLr5YfxenmuyuGJZr
 89fBbGE2uufTVQhXPijxwU3g34FdeFXFjc554+0Cmx2S6qtrG9rTrv5qfVX/86mCvW5ajbf437r
 a4U5G5RjiHIk10XR61wxSs56BmjyUlwZepqCdgFtR7qWSX0kO5Lk5oPB8lWRJ/7KsAsRhZrpP/W
 l/SwnyDhTDLPsHPpJmAjU68RFtnWm4Bw7W5GTRu3FnwWpyLeZkyOirQDmrv6/wFpXabkAp5/Ws3
 sLzCFfZjVAVJsH5H7VAFyHHWonvwVeEtpNh8exlpBSUcRP0lKwf4t0yp+7X8YPLL/lIY/9Ut4iS
 PuPTEHpn6VK5QkdGIbOmgspdhwNSAnhP/ulto/0gECxeiyGayi62dzLQoehaPTFnCJ6ZgILEeBQ
 PmYgmBAPQ19yGwvHLK5NOoHpP+mEsXn1OHozeElu7ycIj5Z09ckFbC5YGnwDXp2efHZ5R79TeI8
 is=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Send the start command at the end of Controller Data Queue creation.
Send the stop before sending the "delete" message to the controller.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/cdq.c | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/drivers/nvme/host/cdq.c b/drivers/nvme/host/cdq.c
index b1776637191db5747053bdcf4bdf97ef44a66566..0f01b58a9c3145faae83a81627fa5a93cfc03cf4 100644
--- a/drivers/nvme/host/cdq.c
+++ b/drivers/nvme/host/cdq.c
@@ -243,9 +243,27 @@ static int nvme_submit_delete_cdq_cmd(const struct cdq_nvme_queue *cdq)
 	return __nvme_submit_sync_cmd(cdq->ctrl->admin_q, &c, NULL, NULL, 0, NVME_QID_ANY, 0);
 }
 
+static int nvme_submit_startstop_cdq_cmd(struct cdq_nvme_queue *cdq, uint startstop)
+{
+	struct nvme_command c = {
+		.track_send.opcode = nvme_admin_track_send,
+		.track_send.sel = NVME_TRSND_CMD_MGMT_LOG_USR_DATA,
+		.track_send.mos = cpu_to_le16(startstop),
+		.track_send.dw11 = cpu_to_le32((u32)cdq->id)
+	};
+
+	return  __nvme_submit_sync_cmd(cdq->ctrl->admin_q, &c, NULL, NULL, 0, NVME_QID_ANY, 0);
+}
+#define nvme_start_cdq(cdq) \
+	nvme_submit_startstop_cdq_cmd(cdq, NVME_TRSND_CMD_MGMT_LOG_USR_DATA_START)
+#define nvme_stop_cdq(cdq) \
+	nvme_submit_startstop_cdq_cmd(cdq, NVME_TRSND_CMD_MGMT_LOG_USR_DATA_STOP)
+
 /* Sends a CDQ delete NVMe cmd */
 static void nvme_delete_cdq_ctrl(struct cdq_nvme_queue *cdq)
 {
+	if (nvme_stop_cdq(cdq))
+		WARN_ONCE(1, "Failed to stop CDQ (id: %d)", cdq->id);
 	if (nvme_submit_delete_cdq_cmd(cdq))
 		WARN_ONCE(1, "Failed delete CDQ (id: %d)", cdq->id);
 }
@@ -337,6 +355,9 @@ int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id)
 	if (ret)
 		goto del_xarray;
 
+	ret = nvme_start_cdq(cdq);
+	if (ret)
+		goto del_xarray;
 	return 0;
 
 del_xarray:

-- 
2.50.1

