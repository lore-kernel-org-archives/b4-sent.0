From: Charles Vosburgh <trilobyte777@gmail.com>
Date: Wed, 29 Jul 2026 10:53:41 -0400
Subject: [PATCH net] sctp: validate Cookie Preservative parameter length
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-sctp-cookie-preservative-length-v1-1-1ade32e42668@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPQTamoC/yWNwQrCMBBEf6Xs2YW6FIP+inhI46ZdlaRk0yCU/
 rurHt8w82YD5SKscOk2KNxEJSeD46GDMPs0McrdGKinU+/ojBrqgiHnpzAuhW3efJXG+OI01Rl
 j9MPgiBzFEcxinSjv38MVEle4/UNdxweH+nXDvn8A+bGtE4gAAAA=
X-Change-ID: 20260729-sctp-cookie-preservative-length-ffa4472272fb
To: Marcelo Ricardo Leitner <marcelo.leitner@gmail.com>, 
 Xin Long <lucien.xin@gmail.com>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: linux-sctp@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Charles Vosburgh <trilobyte777@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785336880; l=2510;
 i=trilobyte777@gmail.com; s=20260727; h=from:subject:message-id;
 bh=vg+pRzQHtqmDcldA7wmoJprrLJOFDAz+bHKBOZZASV8=;
 b=gnu/YmwrNjWnv84AcUmadJFMhxPGwQQcfX/VhEnVwrCu9DRmhwVrpntewjtkIfYj48bQnVhfR
 lV4nsEAO+eLD9QR6aX2Q+YgC0m1iNFJjo/bpYvIS2kLL+Yw9BUlDJeq
X-Developer-Key: i=trilobyte777@gmail.com; a=ed25519;
 pk=kxCwp20gY82hL3ixb5IXlZ2N0X9TDxiKPCpjPcWqN3E=
X-Endpoint-Received: by B4 Relay for trilobyte777@gmail.com/20260727 with auth_id=899
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Cookie Preservative parameter contains a fixed 32-bit Suggested
Cookie Life-span Increment after its parameter header. However,
sctp_verify_param() accepts a header-only parameter because the generic
parameter walker only requires the header to be present.

sctp_process_param() then reads lifespan_increment beyond the declared
parameter and adds the value to asoc->cookie_life. When the malformed
parameter is last in an INIT, the read starts at the receive skb tail,
and the resulting value changes the expiration in the State Cookie
returned in the INIT ACK.

Require the declared parameter length to match the fixed structure size
and abort the association through the existing invalid parameter length
path otherwise.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Suggested-by: Xin Long <lucien.xin@gmail.com>
Cc: stable@vger.kernel.org
Signed-off-by: Charles Vosburgh <trilobyte777@gmail.com>
---
This follows Xin Long's review of "[PATCH net] sctp: validate Adaptation
Indication parameter length", which noted that
SCTP_PARAM_COOKIE_PRESERVATIVE has the same fixed-format validation issue.

Runtime-tested in KVM/QEMU. The unchanged reproducer accepts header-only
and overlong Cookie Preservative parameters on the unpatched kernel. With
this patch applied to net.git base 51b093a7ba27, both malformed forms are
rejected while the baseline and valid eight-byte controls still pass.

The patch passes checkpatch --strict, builds net/sctp/sm_make_chunk.o,
and completes a full x86-64 bzImage build.
---
 net/sctp/sm_make_chunk.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/net/sctp/sm_make_chunk.c b/net/sctp/sm_make_chunk.c
index a1c0334a1038..eb9cff77759b 100644
--- a/net/sctp/sm_make_chunk.c
+++ b/net/sctp/sm_make_chunk.c
@@ -2165,7 +2165,14 @@ static enum sctp_ierror sctp_verify_param(struct net *net,
 	switch (param.p->type) {
 	case SCTP_PARAM_IPV4_ADDRESS:
 	case SCTP_PARAM_IPV6_ADDRESS:
+		break;
 	case SCTP_PARAM_COOKIE_PRESERVATIVE:
+		if (ntohs(param.p->length) != sizeof(*param.life)) {
+			sctp_process_inv_paramlength(asoc, param.p,
+						     chunk, err_chunk);
+			retval = SCTP_IERROR_ABORT;
+		}
+		break;
 	case SCTP_PARAM_SUPPORTED_ADDRESS_TYPES:
 	case SCTP_PARAM_STATE_COOKIE:
 	case SCTP_PARAM_HEARTBEAT_INFO:

---
base-commit: 51b093a7ba27476e1f639455f005e8d2e75390e4
change-id: 20260729-sctp-cookie-preservative-length-ffa4472272fb

Best regards,
--  
Charles Vosburgh <trilobyte777@gmail.com>

