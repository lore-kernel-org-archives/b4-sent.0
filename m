From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Tue, 24 Nov 2026 10:16:46 -0600
Subject: [PATCH v19 05/13] scsi: ibmvfc: fix resource leaks on partial
 queue allocation failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-ibmvfc-fpin-support-v19-5-2aaffe5fe7d2@linux.ibm.com>
References: <20261124-ibmvfc-fpin-support-v19-0-2aaffe5fe7d2@linux.ibm.com>
In-Reply-To: <20261124-ibmvfc-fpin-support-v19-0-2aaffe5fe7d2@linux.ibm.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795537005; l=2781;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=wxC/5k+1fH+x2U7saJs/+NtXgLmv0/MHv+liqk2H5Nc=;
 b=Xn25L7tzoxW0DFJ3eERDPFphWEVHFe/ITk20wzD06/5d+OKYEwsZpDZGbwaQ7ADxiG7rLpFr/
 r4kQNj5xp2hDiGr2U2oA+IOXVqPVG6wLVbxgqMjfut7iWa47qQxopFa
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ibmvfc_alloc_queue() leaks the event pool on both failure paths
after ibmvfc_init_event_pool() succeeds: neither the
get_zeroed_page() failure path nor the dma_mapping_error() failure
path calls ibmvfc_free_event_pool(). No caller compensates, since
ibmvfc_init_crq() returns immediately on ibmvfc_alloc_queue()
failure, ibmvfc_alloc_channels() only unwinds previously succeeded
queues, and ibmvfc_alloc_mem() jumps to a label that does not free
the failed queue. Add ibmvfc_free_event_pool() calls on both error
paths in ibmvfc_alloc_queue() to close the leak.

ibmvfc_free_queue() also unconditionally calls dma_unmap_single()
and free_page(), even if the message page was never allocated. In
that case msgs.handle and msg_token are both zero/NULL, and calling
dma_unmap_single() with address 0 is unsafe on many architectures.
Guard dma_unmap_single() and free_page() together under a
msgs.handle check.

ibmvfc_alloc_queue() releases everything it allocated when it
fails, so a queue it failed to allocate must not be passed to
ibmvfc_free_queue(): ibmvfc_free_event_pool() does not reset the
pool size or pointers, so the stale values would be used again. No
caller does this.

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
2.56.1

