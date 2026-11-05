From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Thu, 05 Nov 2026 11:22:58 -0600
Subject: [PATCH v18 05/13] scsi: ibmvfc: fix resource leaks on partial
 queue allocation failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-ibmvfc-fpin-support-v18-5-d683b74736a3@linux.ibm.com>
References: <20261105-ibmvfc-fpin-support-v18-0-d683b74736a3@linux.ibm.com>
In-Reply-To: <20261105-ibmvfc-fpin-support-v18-0-d683b74736a3@linux.ibm.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793899377; l=2725;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=9C1Drt4rDISp5hUU8r+SsNmnCRtIPklwJLn7Jdj0Gy4=;
 b=wJW2KbN8vNcFA4WEBiJc26sKNHKVulRqTr29biqOKrbVOYJ+CcARW9C0jIV9/CFgO6hX5+dV8
 MZbv9GNJnv0CUdm6vui53dfwFrzbmzS1XSbYNa02svo7EPddVkHggqz
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ibmvfc_free_queue() unconditionally calls dma_unmap_single() and
free_page() but does not guard either call against a partially or
never-initialized queue. If ibmvfc_alloc_queue() fails before the DMA
mapping is established (e.g. get_zeroed_page() fails or
dma_mapping_error()), msgs.handle and msg_token are both zero/NULL.
Calling dma_unmap_single() with address 0 is unsafe on many
architectures.

Guard dma_unmap_single() and free_page() together under a msgs.handle
check so ibmvfc_free_queue() is safe to call on a partially or
never-initialized queue.

ibmvfc_alloc_queue() also leaks the event pool on both failure paths
after ibmvfc_init_event_pool() succeeds: neither the get_zeroed_page()
failure path nor the dma_mapping_error() failure path calls
ibmvfc_free_event_pool(). No caller compensates, since
ibmvfc_init_crq() returns immediately on ibmvfc_alloc_queue() failure,
ibmvfc_alloc_channels() only unwinds previously succeeded queues, and
ibmvfc_alloc_mem() jumps to a label that does not free the failed queue.
Add ibmvfc_free_event_pool() calls on both error paths in
ibmvfc_alloc_queue() to close the leak.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index 77c685f6f959..e04c80050b98 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -914,9 +914,11 @@ static void ibmvfc_free_queue(struct ibmvfc_host *vhost,
 {
 	struct device *dev = vhost->dev;
 
-	dma_unmap_single(dev, queue->msg_token, PAGE_SIZE, DMA_BIDIRECTIONAL);
-	free_page((unsigned long)queue->msgs.handle);
-	queue->msgs.handle = NULL;
+	if (queue->msgs.handle) {
+		dma_unmap_single(dev, queue->msg_token, PAGE_SIZE, DMA_BIDIRECTIONAL);
+		free_page((unsigned long)queue->msgs.handle);
+		queue->msgs.handle = NULL;
+	}
 
 	ibmvfc_free_event_pool(vhost, queue);
 }
@@ -6303,8 +6305,10 @@ static int ibmvfc_alloc_queue(struct ibmvfc_host *vhost,
 	}
 
 	queue->msgs.handle = (void *)get_zeroed_page(GFP_KERNEL);
-	if (!queue->msgs.handle)
+	if (!queue->msgs.handle) {
+		ibmvfc_free_event_pool(vhost, queue);
 		return -ENOMEM;
+	}
 
 	queue->msg_token = dma_map_single(dev, queue->msgs.handle, PAGE_SIZE,
 					  DMA_BIDIRECTIONAL);
@@ -6312,6 +6316,7 @@ static int ibmvfc_alloc_queue(struct ibmvfc_host *vhost,
 	if (dma_mapping_error(dev, queue->msg_token)) {
 		free_page((unsigned long)queue->msgs.handle);
 		queue->msgs.handle = NULL;
+		ibmvfc_free_event_pool(vhost, queue);
 		return -ENOMEM;
 	}
 

-- 
2.56.0

