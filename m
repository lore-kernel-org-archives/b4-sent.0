From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 24 Apr 2026 13:37:53 +0200
Subject: [PATCH RFC 3/5] nvme: Add NVME_AER_ONE_SHOT callback handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260424-jag-cdq-lkml-v1-3-d773343a717c@kernel.org>
References: <20260424-jag-cdq-lkml-v1-0-d773343a717c@kernel.org>
In-Reply-To: <20260424-jag-cdq-lkml-v1-0-d773343a717c@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <chaitanyak@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3053;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=hVV/r0xgERPhDudR4npmn1JJFr+BsWKu5X3JBCDiLsA=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGnrVirLacrNUYell8Uv8VBior6/IA2XFUPih
 BGJqO+aidEjHokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJp61YqAAoJELqXzVK3
 lkFP0dYMAJOxBxsTbTSwPIJXXJ6Emu0lE9y9Uqyx844qHLIhXVuoEmvRbw1lpyfm1XIkx+GRXK7
 ZK6Y7XzQnDmEsIqgkeBFAwNpHQlomGLAqjkr9GcsV+jtovlagXBzKrOFSW/OvT4cm92p5HvlU6b
 1j99YLbeVxVBfK0D0ymWYXey7xw7NpnopLGm/HSZJEkL5wGl7Ei6sbarbR2Xwn6u9qXbLmHb6bv
 1aMVbMMYbDPkYBMq68r6mytD3ZIhwI5/cdRr/IkZz/CA0bFl+ydkv/o6PK/NY8651jHnXcK5HPQ
 OYMLu8KQuVV005PyvL94n+0iv7Ug+gyx2xdqbaaf/UIMzifQRK0tuXnaH0udjnkS+qUPKcMBjhW
 EhMBz/m5NJlrGoYaNNM/sWHjZC0kf8+A9iIFwJ2kHo+/f/nx4M8FLnmZJ25eNOdIjj6ovNwdKqL
 CHyBaR4q9JK/J4IHAnbDGNOan/llKvKh1N8xpM17Lx83U8gkApa+FoaPWjr16DzAJ9gJVq+t4E6
 sI=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for handling NVME_AER_ONE_SHOT asynchronous event
notifications. One-shot events, unlike traditional AERs, are not
requeued and include additional event parameters in the upper 32 bits of
the result.

Add nvme_handle_aen_oneshot() stub to dispatch one-shot events based on
subtype. This will be extended by subsequent patches to handle specific
one-shot event types like CDQ tail pointer events.

Extend nvme_complete_async_event() to handle the NVME_AER_ONE_SHOT case,
extracting the event parameter from the 64-bit result and passing it to
the handler.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/core.c | 20 ++++++++++++++++++++
 include/linux/nvme.h     |  5 +++++
 2 files changed, 25 insertions(+)

diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index 766e9cc4ffca5e269c5e85dd4a0323dc99e5658c..be4807591d2d80d228c10e3c78b6b7dc371b3865 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -4747,6 +4747,16 @@ static u32 nvme_aer_subtype(u32 result)
 	return (result & 0xff00) >> 8;
 }
 
+static bool nvme_handle_aen_oneshot(struct nvme_ctrl *ctrl, u32 result, u32 event_param)
+{
+	u32 aer_subtype = nvme_aer_subtype(result);
+
+	/* Will be extended to handle specific one-shot event types */
+	if (aer_subtype == NVME_AER_ONE_SHOT_CDQ_TAIL_PTR)
+		return -ENOSYS;
+	return false;
+}
+
 static bool nvme_handle_aen_notice(struct nvme_ctrl *ctrl, u32 result)
 {
 	u32 aer_notice_type = nvme_aer_subtype(result);
@@ -4795,6 +4805,7 @@ void nvme_complete_async_event(struct nvme_ctrl *ctrl, __le16 status,
 		volatile union nvme_result *res)
 {
 	u32 result = le32_to_cpu(res->u32);
+	u32 event_param = 0;
 	u32 aer_type = nvme_aer_type(result);
 	u32 aer_subtype = nvme_aer_subtype(result);
 	bool requeue = true;
@@ -4807,6 +4818,15 @@ void nvme_complete_async_event(struct nvme_ctrl *ctrl, __le16 status,
 	case NVME_AER_NOTICE:
 		requeue = nvme_handle_aen_notice(ctrl, result);
 		break;
+	case NVME_AER_ONE_SHOT:
+		/*
+		 * One-shot events like CDQ tail pointer events.
+		 * Extract event parameter from upper 32 bits.
+		 */
+		event_param = le64_to_cpu(res->u64) >> 32;
+		requeue = nvme_handle_aen_oneshot(ctrl, result, event_param);
+		trace_nvme_async_event(ctrl, result);
+		break;
 	case NVME_AER_ERROR:
 		/*
 		 * For a persistent internal error, don't run async_event_work
diff --git a/include/linux/nvme.h b/include/linux/nvme.h
index 4a42f1614de962b9d448193193f68fe1968dfb6f..6948e39842d48dc9974579ea1f9c4d5330238275 100644
--- a/include/linux/nvme.h
+++ b/include/linux/nvme.h
@@ -840,6 +840,7 @@ enum {
 	NVME_AER_ERROR			= 0,
 	NVME_AER_SMART			= 1,
 	NVME_AER_NOTICE			= 2,
+	NVME_AER_ONE_SHOT		= 4,
 	NVME_AER_CSS			= 6,
 	NVME_AER_VS			= 7,
 };
@@ -855,6 +856,10 @@ enum {
 	NVME_AER_NOTICE_DISC_CHANGED	= 0xf0,
 };
 
+enum {
+	NVME_AER_ONE_SHOT_CDQ_TAIL_PTR	= 0x00,
+};
+
 enum {
 	NVME_AEN_BIT_NS_ATTR		= 8,
 	NVME_AEN_BIT_FW_ACT		= 9,

-- 
2.50.1

