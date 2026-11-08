From: Weidong Wang <weidongw@illinois.edu>
Date: Sun, 08 Nov 2026 03:01:08 -0600
Subject: [PATCH] scsi: libfc: Fix rport kref leak in fc_rport_enter_ready()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-h123-send-v1-1-b7672ff849f0@illinois.edu>
X-B4-Tracking: v=1; b=H4sIAFQ68GoC/yXMTQ5AMBBA4avIrDVpK62fq4gFNRiLkg4iEXdXL
 L/k5V3AGAgZquSCgAcxLT5CpQm4qfUjCuqjQUttlZKFmJTOBKPvRa6zFjtjjLQlxH4NOND5ver
 mN+/djG57B3DfD6dLQpptAAAA
X-Change-ID: 20261108-h123-send-723aeb555069
To: Hannes Reinecke <hare@suse.de>, "Martin K. Petersen" <mkp@kernel.org>
Cc: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Weidong Wang <weidongw@illinois.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794128488; l=3067;
 i=weidongw@illinois.edu; s=20261108; h=from:subject:message-id;
 bh=xRn4o4Xo2uz0/atqmK0OD/T0n88c9mKnmN8e3Rc+YrY=;
 b=ngBmio2Hk2lkCkJjxTpsOfHS9AbXORBCnJtDD9yLk5LY7hbmvytIqliR2ttZ/XpS895htJMUv
 dse4I3xbIYjAOwbCFYb3gErrliNJKx5rQ1Es4Ysza6RL/Hu/WnCgjLQ
X-Developer-Key: i=weidongw@illinois.edu; a=ed25519;
 pk=DR2S1xPEa5sELrWPfOpvUphJQ2VHC+MDc/wJavE/ifg=
X-Endpoint-Received: by B4 Relay for weidongw@illinois.edu/20261108 with auth_id=1449
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fc_rport_enter_ready() takes a reference on the rport unconditionally,
but only queues event_work, whose handler drops that reference, when no
event is pending. If rdata->event is already set, the && short-circuits
past both queue_work() and the compensating kref_put(), so the reference
is leaked and the fc_rport_priv is never freed.

This is reachable from the wire: a PLOGI from a well-known address goes
straight to fc_rport_enter_ready(), and a second PLOGI for the same
S_ID while RPORT_EV_READY is still pending enters it again. After the
rport is logged out, kmemleak reports:

  unreferenced object 0xffff888... (size 512):
  backtrace:
    __kmalloc_noprof
    fc_rport_create
    fc_rport_recv_req
    fc_lport_recv_els_req
    fc_lport_recv
    fcoe_receive_work

Commit 823a65409c89 ("scsi: libfc: Skip additional kref updating work
event") fixed the same pattern in fc_rport_enter_delete(). Do the same
here: only take the reference when no event is pending, i.e. when the
work is actually going to be queued.

The issue was found with an LLM-based bug-finding tool; the reproducer,
fix and changelog were drafted with AI assistance (Claude), then
reviewed and tested by the submitter.

Fixes: 4d2095cc42a2 ("scsi: libfc: Revisit kref handling")
Cc: stable@vger.kernel.org
Signed-off-by: Weidong Wang <weidongw@illinois.edu>
---
Tested on v7.4-rc1 (05441d697f7f), x86_64, KASAN + kmemleak, QEMU/KVM.
Reproducer: software FCoE instance on lo; raw FCoE ELS frames injected
with AF_PACKET (PLOGI from well-known S_IDs 0xfffc01.., a second PLOGI
for the same S_ID while RPORT_EV_READY is pending, then LOGO), 120 rports.

                   2nd enter_ready with    kmemleak unreferenced
                   event pending           fc_rport_priv (512 B)
  unpatched        116                     99
  patched          104                     0

READY/delete work events are processed the same with and without the
patch; no KASAN/UBSAN/WARN splats. checkpatch clean, no new W=1 warnings.
The reproducer can be shared on request.
---
 drivers/scsi/libfc/fc_rport.c | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/drivers/scsi/libfc/fc_rport.c b/drivers/scsi/libfc/fc_rport.c
index c25979d96..7b0938544 100644
--- a/drivers/scsi/libfc/fc_rport.c
+++ b/drivers/scsi/libfc/fc_rport.c
@@ -550,10 +550,11 @@ static void fc_rport_enter_ready(struct fc_rport_priv *rdata)
 
 	FC_RPORT_DBG(rdata, "Port is Ready\n");
 
-	kref_get(&rdata->kref);
-	if (rdata->event == RPORT_EV_NONE &&
-	    !queue_work(rport_event_queue, &rdata->event_work))
-		kref_put(&rdata->kref, fc_rport_destroy);
+	if (rdata->event == RPORT_EV_NONE) {
+		kref_get(&rdata->kref);
+		if (!queue_work(rport_event_queue, &rdata->event_work))
+			kref_put(&rdata->kref, fc_rport_destroy);
+	}
 
 	rdata->event = RPORT_EV_READY;
 }

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261108-h123-send-723aeb555069

Best regards,
--  
Weidong Wang <weidongw@illinois.edu>

