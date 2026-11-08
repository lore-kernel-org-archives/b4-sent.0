From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Sun, 08 Nov 2026 18:05:19 +0000
Subject: [PATCH bluetooth-next] Bluetooth: L2CAP: validate MPS and MTU in
 ECRED connection response
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-bt-ecred-mps-fix-v1-1-e7419bff6ee5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAN658GoC/x2MQQqDMBQFryJ/3Q9JRLG9SukiJk/9YBNJ0iKId
 ze4nIGZgzKSINOrOSjhL1liqKAfDbnFhhksvjIZZXqt1cBjYbgEz98t8yQ7227Sg3eqb82TarY
 lVH0v3zSuP5QYy8IBe6HPeV54RjcRcgAAAA==
To: joasantonio108@gmail.com, Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794161118; l=1814;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=34wckLfEEjtqROx8Y8etwAGduFSLltsni91dcXOsWjs=;
 b=JOL67+BGboEO0cbR9h/gnaPrmUWK7g9PvIhV/Xd0Z2eTBLZCTyh4DkN/HYheJ51R09XZuflje
 K8MnIj7UoGvCJb+GiP2XSHauO2csQFIIaNgt/cSfZbNWqqcq4FtvXC6
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

l2cap_ecred_conn_rsp() does not validate the MPS and MTU values from
the peer before storing them. All other L2CAP connection paths
(le_connect_req/rsp, ecred_conn_req, ecred_reconf_req) validate these
values against minimums, but the ECRED connection response handler
assigns them directly to chan->remote_mps and chan->omtu.

When a malicious or buggy peer sends MPS=0, l2cap_segment_le_sdu()
computes pdu_len = chan->remote_mps - L2CAP_SDULEN_SIZE, which
underflows the u16, leading to an oversized skb allocation and
potential memory corruption.

Add the same MPS >= L2CAP_ECRED_MIN_MPS and MTU >= L2CAP_ECRED_MIN_MTU
checks that l2cap_ecred_conn_req() already applies, refusing the
channel if the values are below spec minimums.

Found by LLM-assisted manual code review.

Fixes: 15f02b910562 ("Bluetooth: L2CAP: Add initial code for Enhanced Credit Based Mode")
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
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

