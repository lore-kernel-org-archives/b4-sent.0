From: Suyuan Wang <shyckless@gmail.com>
Date: Wed, 18 Nov 2026 13:57:41 +0000
Subject: [PATCH] scsi: ibmvfc: Unmap scatterlists before completing BSG
 jobs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-ibmvfc-v1-1-3115f5901130@gmail.com>
X-B4-Tracking: v=1; b=H4sIANSu/WoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0ML3cyk3LK0ZF1TU9OkRItk4+Sk5DQloOKCotS0zAqwQdGxEH5xaVJ
 WanIJSLdSbS0Ax0wl/2oAAAA=
X-Change-ID: 20261118-ibmvfc-555ba8c3cbcf
To: tyreld@linux.ibm.com
Cc: linux-kernel@vger.kernel.org, linux-scsi@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795010260; l=2020;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=N0Tx4tKvk+IGw2iXqqTkUq8ZEOCSQRNuciGKIswz/Gg=;
 b=gfulJ5sTCNkCHuEG89KYs141VHVOJihg1jGg25SYidOMf4HKeizUjAnBk4ijAwqXuQBi+EnWy
 EG8irAzLWPhAgwj5bHaoFp5FuwKcgOpmAAtUB5Qtne6wavXO8KaJRNI
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

ibmvfc_bsg_request() calls bsg_job_done() before unmapping the request
and reply scatterlists.

bsg_job_done() starts block request completion, which can run
bsg_teardown_job() and free both scatterlists before the following
dma_unmap_sg() calls. The unmaps can then read freed memory.

Complete the job after the common DMA cleanup instead. The completion
path has already saved the operation result in bsg_reply and set rc to
zero; paths that return an error keep their existing cleanup and leave
completion to the FC transport. passthru_mutex stays held until after
the completion call.

Found with a static analysis tool and checked by hand.

Fixes: d31429e1517c ("[SCSI] ibmvfc: Add FC Passthru support")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on powerpc with clang (W=1, no new warnings). I don't
have IBM Power virtual FC hardware.
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index aa7ae81df41b..6dce72cb80b5 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -2392,14 +2392,15 @@ static int ibmvfc_bsg_request(struct bsg_job *job)
 	ibmvfc_free_event(evt);
 	spin_unlock_irqrestore(&vhost->host->host_lock, flags);
 	bsg_reply->result = rc;
-	bsg_job_done(job, bsg_reply->result,
-		       bsg_reply->reply_payload_rcv_len);
 	rc = 0;
 out:
 	dma_unmap_sg(vhost->dev, job->request_payload.sg_list,
 		     job->request_payload.sg_cnt, DMA_TO_DEVICE);
 	dma_unmap_sg(vhost->dev, job->reply_payload.sg_list,
 		     job->reply_payload.sg_cnt, DMA_FROM_DEVICE);
+	if (!rc)
+		bsg_job_done(job, bsg_reply->result,
+			     bsg_reply->reply_payload_rcv_len);
 	mutex_unlock(&vhost->passthru_mutex);
 	LEAVE;
 	return rc;



