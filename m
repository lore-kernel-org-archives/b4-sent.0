From: Charles Vosburgh <trilobyte777@gmail.com>
Date: Mon, 27 Jul 2026 19:17:30 -0400
Subject: [PATCH net] sctp: validate Adaptation Indication parameter length
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260727-sctp-adaptation-length-v1-1-0ab58b2810a5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAnnZ2oC/yWM0QrCMAxFf2Xk2UBXaQf+ivgQ27hFpJYmE2Hs3
 636eC73nA2Um7DCadig8UtUnqXDeBggLVRmRsmdwTsf3eQn1GQVKVM1sv7FB5fZFiQaYzjGEHx
 20OXa+CbvX/gMhQ0u/1HX652TfZOw7x8wYtPyfwAAAA==
X-Change-ID: 20260727-sctp-adaptation-length-aa16536552d0
To: Marcelo Ricardo Leitner <marcelo.leitner@gmail.com>, 
 Xin Long <lucien.xin@gmail.com>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: linux-sctp@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Charles Vosburgh <trilobyte777@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785194288; l=2040;
 i=trilobyte777@gmail.com; s=20260727; h=from:subject:message-id;
 bh=wCoSIOJR+7EQ3GwZeJvo3MqgXnw0t2pbCcjUroECces=;
 b=iG49uxij7c0cxm0J4SFhCX6CCcut8o/62OJ85HHBOvgSMbS5+yuGeJqhW8xxOCIdDtaM5YwLt
 reLPwDo8JwXAHpbSxFezLK4P0kALVCpkZ+T6oqYE/zBA9kRBouipMSN
X-Developer-Key: i=trilobyte777@gmail.com; a=ed25519;
 pk=kxCwp20gY82hL3ixb5IXlZ2N0X9TDxiKPCpjPcWqN3E=
X-Endpoint-Received: by B4 Relay for trilobyte777@gmail.com/20260727 with auth_id=899
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Adaptation Layer Indication parameter contains a fixed 32-bit
Adaptation Code Point after its parameter header. However,
sctp_verify_param() accepts a header-only parameter because the generic
parameter walker only requires the header to be present.

sctp_process_param() then reads adaptation_ind beyond the declared
parameter. When the malformed parameter is last in an INIT, the read
starts at the receive skb tail, and the value is copied into the state
cookie returned in the INIT ACK. This may disclose four receive-buffer
tail bytes.

Require the declared parameter length to match the fixed structure size
and abort the association through the existing invalid parameter length
path otherwise.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Signed-off-by: Charles Vosburgh <trilobyte777@gmail.com>
---
Runtime-tested against net.git base 53658c6f3682.

The patch passes checkpatch, builds net/sctp/sm_make_chunk.o, completes
a full x86-64 bzImage build, and rejects the malformed header-only
Adaptation Indication while preserving the baseline and valid
eight-byte controls.
---
 net/sctp/sm_make_chunk.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/net/sctp/sm_make_chunk.c b/net/sctp/sm_make_chunk.c
index c02809264075..1f7a097802b4 100644
--- a/net/sctp/sm_make_chunk.c
+++ b/net/sctp/sm_make_chunk.c
@@ -2168,7 +2168,13 @@ static enum sctp_ierror sctp_verify_param(struct net *net,
 	case SCTP_PARAM_HEARTBEAT_INFO:
 	case SCTP_PARAM_UNRECOGNIZED_PARAMETERS:
 	case SCTP_PARAM_ECN_CAPABLE:
+		break;
 	case SCTP_PARAM_ADAPTATION_LAYER_IND:
+		if (ntohs(param.p->length) != sizeof(*param.aind)) {
+			sctp_process_inv_paramlength(asoc, param.p,
+						     chunk, err_chunk);
+			retval = SCTP_IERROR_ABORT;
+		}
 		break;
 
 	case SCTP_PARAM_SUPPORTED_EXT:

---
base-commit: 53658c6f3682967a5e76ed4bc7462c4bdcddaec3
change-id: 20260727-sctp-adaptation-length-aa16536552d0

Best regards,
--  
Charles Vosburgh <trilobyte777@gmail.com>

