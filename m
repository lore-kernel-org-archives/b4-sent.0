From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Mon, 26 Oct 2026 11:12:36 -0500
Subject: [PATCH v16 04/12] scsi: ibmvfc: fix unguarded dma_unmap_single()
 in ibmvfc_free_queue()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-ibmvfc-fpin-support-v16-4-a900aa657ed5@linux.ibm.com>
References: <20261026-ibmvfc-fpin-support-v16-0-a900aa657ed5@linux.ibm.com>
In-Reply-To: <20261026-ibmvfc-fpin-support-v16-0-a900aa657ed5@linux.ibm.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793031155; l=1500;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=K8OwCqpjIdXQs2e8AVALRObhwpPT1iTdETPfLazYtSc=;
 b=Dexqw2leNcpZewS1JC4j/KbcXR0M45KWWZfi/aW99Wip/kOL7bdhSIpZO0Bf//5EsxgwI6RiP
 4hRHTXobUPcDVvH5YQXhoNaq9KIdsqcNMovr0KY0raEpYZi5KJ10o5A
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ibmvfc_free_queue() unconditionally calls dma_unmap_single() before
freeing the queue page, but only guards free_page() behind a
queue->msgs.handle check. If ibmvfc_alloc_queue() fails before the
DMA mapping is established (e.g. get_zeroed_page() fails or
ibmvfc_init_event_pool() fails), msgs.handle and msg_token are both
zero/NULL. Calling dma_unmap_single() with address 0 is unsafe on
many architectures.

Guard dma_unmap_single() and free_page() together under the existing
msgs.handle check so ibmvfc_free_queue() is safe to call on a
partially or never-initialized queue.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index f0502d748210..b63b341efb07 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -913,9 +913,11 @@ static void ibmvfc_free_queue(struct ibmvfc_host *vhost,
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

-- 
2.56.0

