From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 10 Nov 2026 03:26:03 +0000
Subject: [PATCH bluetooth-next v2] Bluetooth: L2CAP: validate MPS and MTU
 in ECRED connection response
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-bt-ecred-mps-fix-v2-1-48c5ee28fd8a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMqO8moC/3WNTQ6CMBCFr0Jm7RimCoIr72FYQJnCJEBJWwmG9
 O427F2+v+8d4NkJe3hmBzjexItdklCXDPTYLgOj9EmDylVJlFfYBWTtuMd59Whkx7YwVPU6L2+
 qhjRbHSf7RL6hmz4crA0jLrwHaFI+ig/Wfc/Hjc7Wf/hGSMiPO9WdMSVz8RrmVqartjM0McYft
 ExJTMAAAAA=
To: joasantonio108@gmail.com, luiz.dentz@gmail.com, marcel@holtmann.org
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794281162; l=2807;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=41c1pMO3EYoT9jgOM2ha+yJ4QeOIoB1nBmapQHpxbjA=;
 b=xcFp+YVZoXkpoInhPt0D+YQxpcGwAPodG0vle5zTsQrrORzV6s5BVdGGGhmGYgWTTTk/n7iKM
 K+yAGwUSaLbBPEG1F6Bin5TDOEr/ynsOMcViu1mRKVLWjl9SaXZxJVF
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

l2cap_ecred_conn_rsp() stores the MTU and MPS from the peer without
checking them against the minimums required for enhanced credit based
channels.  The other LE and ECRED handlers (l2cap_le_connect_req(),
l2cap_le_connect_rsp(), l2cap_ecred_conn_req(), l2cap_ecred_reconf_req())
all reject values below the minimum.

With an MPS below L2CAP_SDULEN_SIZE, the pdu_len computation in
l2cap_segment_le_sdu() wraps:

	pdu_len = chan->remote_mps - L2CAP_SDULEN_SIZE;

pdu_len is then clamped to the SDU length, which l2cap_chan_send() has
already limited to chan->omtu, so nothing is over-allocated and there is
no memory safety issue.  The result is that the whole SDU is sent as a
single PDU, larger than the MPS the peer announced, and a channel is
established with parameters the specification does not allow.

Apply the same L2CAP_ECRED_MIN_MTU / L2CAP_ECRED_MIN_MPS checks that
l2cap_ecred_conn_req() uses and drop the channel when the response
carries smaller values.

Found by LLM-assisted manual code review.

Fixes: 15f02b910562 ("Bluetooth: L2CAP: Add initial code for Enhanced Credit Based Mode")
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
v1 claimed that a peer-supplied MPS of 0 leads to an oversized skb
allocation and potential memory corruption.  That was wrong, and I
apologize for the noise: in l2cap_segment_le_sdu() the wrapped pdu_len
is clamped to the SDU length, which l2cap_chan_send() has already
limited to chan->omtu, so there is no memory safety impact.  The
remaining problem is conformance only (PDUs larger than the MPS the
peer announced, and inconsistency with the other LE/ECRED handlers).
---
Changes in v2:
- Correct the commit message: no memory safety impact, drop the
  overstated claim from v1
- No code change
- Cc linux-bluetooth, which v1 missed
- Link to v1: https://lore.kernel.org/r/20261108-bt-ecred-mps-fix-v1-1-e7419bff6ee5@gmail.com
---
 net/bluetooth/l2cap_core.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/net/bluetooth/l2cap_core.c b/net/bluetooth/l2cap_core.c
index 4dd56e007..c3b8f0f46 100644
--- a/net/bluetooth/l2cap_core.c
+++ b/net/bluetooth/l2cap_core.c
@@ -5711,6 +5711,16 @@ static inline int l2cap_ecred_conn_rsp(struct l2cap_conn *conn,
 				break;
 			}
 
+			/*
+			 * Validate MPS and MTU per BT Core Spec
+			 * Vol 3 Part A Sec 10.2
+			 */
+			if (mtu < L2CAP_ECRED_MIN_MTU ||
+			    mps < L2CAP_ECRED_MIN_MPS) {
+				l2cap_chan_del(chan, ECONNREFUSED);
+				break;
+			}
+
 			chan->ident = 0;
 			chan->dcid = dcid;
 			chan->omtu = mtu;

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261108-bt-ecred-mps-fix-a5f18dc06329

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

