From: Mark Amirkan <markdamirkan@gmail.com>
Date: Sun, 13 Sep 2026 10:31:43 +0000
Subject: [PATCH net] net/packet: preserve TX_RING progress on a later frame
 error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260913-b4-send-packet-tx-progress-v1-1-01b99569cda6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAI57pmoC/yXMwQrCMAyA4VcZORvo6izOV5Edli7OKHQlqTIYe
 3erHv//8G1grMIGl2YD5beYLKlGe2gg3sc0M8pUG7zzwfXtEalD4zRhHuOTC5YVsy6zshl6cvF
 MgbpTH6ACWfkm6w+/QuICw3/aix4cy5eFff8AiKklT4MAAAA=
X-Change-ID: 20260913-b4-send-packet-tx-progress-2b0c8b6b4596
To: netdev@vger.kernel.org, 
 Willem de Bruijn <willemdebruijn.kernel@gmail.com>
Cc: Paolo Abeni <pabeni@redhat.com>, linux-kernel@vger.kernel.org, 
 Johann Baudy <johann.baudy@gnu-log.net>, Simon Horman <horms@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789295522; l=1484;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=dhnk2shFALnyl3JxYCIX5pXwOJ09oReH25daGsUO0Vc=;
 b=k5VhyfjCXOqw7mmi8aVQ9fDYsibiMVtyKGHetYprQ+zcj4h7HwcmM/cZvjL7TBO8DHAgwKfzJ
 nUslr5E5LyRA2HbZQU4BRTIjfdfLa6ZuH1xBNmbwvaKLW9RmZsZhCso
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tpacket_snd() can transmit one or more frames before a later frame fails
validation.  The failing frame is marked TP_STATUS_WRONG_FORMAT, but its
error replaces len_sum, so send() reports failure despite the earlier
transmission.

Return the completed byte count when it is nonzero, as the allocation
failure path already does.  Keep TP_STATUS_WRONG_FORMAT on the bad frame
so userspace can identify it.

In a two-frame TPACKET_V2 test, a valid 60-byte frame followed by an
oversized frame sends the first frame but returns -EMSGSIZE.  With this
change, send() returns 60 and the second frame remains marked
TP_STATUS_WRONG_FORMAT.

Fixes: 69e3c75f4d54 ("net: TX_RING and packet mmap")
Cc: stable@vger.kernel.org
Assisted-by: Symbolic
Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
---
 net/packet/af_packet.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/packet/af_packet.c b/net/packet/af_packet.c
index 76bde7906d..b7e1848b61 100644
--- a/net/packet/af_packet.c
+++ b/net/packet/af_packet.c
@@ -2893,7 +2893,7 @@ static int tpacket_snd(struct packet_sock *po, struct msghdr *msg)
 				continue;
 			} else {
 				status = TP_STATUS_WRONG_FORMAT;
-				err = tp_len;
+				err = len_sum ? : tp_len;
 				goto out_status;
 			}
 		}

---
base-commit: e6b6078ea1731b05b3b552497b3bce4bf8b014ae
change-id: 20260913-b4-send-packet-tx-progress-2b0c8b6b4596

Best regards,
--  
Mark Amirkan <markdamirkan@gmail.com>

