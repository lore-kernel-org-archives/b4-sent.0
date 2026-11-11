From: Weidong Wang <weidongw@illinois.edu>
Date: Wed, 11 Nov 2026 14:27:28 -0600
Subject: [PATCH net] net/rds: tcp: bound the message length announced by
 the peer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-h047-send-v1-1-2727a38dbfcd@illinois.edu>
X-B4-Tracking: v=1; b=H4sIALDP9GoC/yWMQQ7CIBQFr0LeWhKgoMarGBdt+S3fBRp+NSakd
 y+2y5lMpkKoMAluqqLQl4VfuYE9KYypzzNpjo3hjDtba41Oxl+0UI46NBei9+7qOrT+XWji3/6
 6I9OCxyHlMzxpXP4XrOsGARgGNHIAAAA=
X-Change-ID: 20261110-h047-send-52025d442823
To: Allison Henderson <achender@kernel.org>
Cc: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 netdev@vger.kernel.org, linux-rdma@vger.kernel.org, 
 rds-devel@oss.oracle.com, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Zijie Zhao <zijie4@illinois.edu>, 
 Weidong Wang <weidongw@illinois.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794428911; l=3897;
 i=weidongw@illinois.edu; s=20261108; h=from:subject:message-id;
 bh=1rMOxnrBK7wy6KAVesScdDJ1MghCm+cPgQRTPaFaXQk=;
 b=VbzedWxmkJGCPF1wkXLDwAkKq6e+6vzQkgf60JbkS/QnFUdwExDzi+sEynvRmZIazgJr+hAUm
 zNPE4eTD8fdDAPomMgp9MWq9GHCrxhcxnQHdRYj14lPjYILvT/GJmto
X-Developer-Key: i=weidongw@illinois.edu; a=ed25519;
 pk=DR2S1xPEa5sELrWPfOpvUphJQ2VHC+MDc/wJavE/ifg=
X-Endpoint-Received: by B4 Relay for weidongw@illinois.edu/20261108 with auth_id=1449
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rds_tcp_data_recv() takes the payload length of an incoming message from
the peer's header and queues pskb_extract() clones of the received data
on the incoming message until that many bytes have arrived. Nothing
checks the length, so a peer that announces h_len = 0xffffffff and keeps
sending makes the receiver hold up to 4 GiB per connection. The clones
are no longer on the socket's receive queue, so they are not charged to
the socket and TCP keeps the receive window open.

Senders are limited to RDS_MAX_MSG_SIZE in rds_sendmsg(). Apply the same
limit on receive and drop the connection when a header exceeds it. That
limit has been enforced on send since v4.11; a peer running an older
kernel could still send larger messages over TCP, and such connections
are now dropped.

The issue was discovered by an AI code review agent (an LLM-based
bug-finding tool developed by Zijie Zhao and the submitter) and
confirmed by triggering it on an unmodified kernel, without error
injection, on x86_64 under QEMU: a plain TCP client in a second network
namespace connects to the rds_tcp listener (port 16385), sends one RDS
header with h_len = 0xffffffff and then 1 GiB of payload. The receiver
held about 1.1 GiB until the connection was closed; the same 1 GiB sent
as 1 MiB messages held about 60 MiB.

With this patch the connection is dropped right after the header and
nothing is held, while the 1 MiB messages are processed as before. The
RDS selftest (tools/testing/selftests/net/rds, rds_run.sh -T tcp, also
with -l 10 -c 10 -u 10) passes with the patch applied.

The reproducer, fix and changelog were drafted with AI assistance
(Claude), then reviewed and tested by the submitter.

Fixes: 70041088e3b9 ("RDS: Add TCP transport to RDS")
Cc: stable@vger.kernel.org
Cc: Zijie Zhao <zijie4@illinois.edu>
Signed-off-by: Weidong Wang <weidongw@illinois.edu>
---
Tested on v7.4-rc1 (05441d697f7f) and on net (ae89f2724e), x86_64,
KASAN, QEMU/KVM, 3 GiB guest. Setup: rds_tcp listener in the initial
netns (10.0.0.2); a plain TCP client (no AF_RDS) in a second netns
(10.0.0.1) over a veth pair.

                   1 GiB after one header     1 GiB as 1 MiB
                   with h_len = 0xffffffff    messages (control)
  unpatched        ~1.1 GiB held until close  ~60 MiB
  patched          connection reset after     ~60 MiB, processed
                   the header, nothing held   as before

selftests/net/rds: rds_run.sh -T tcp and rds_run.sh -T tcp -l 10 -c 10
-u 10 pass on both trees with the patch. No KASAN/UBSAN reports;
checkpatch clean.

The limit is per connection; a peer with several source addresses gets
one connection per address. The reproducer is not attached (AI-found
issue, see security-bugs.rst) and can be shared on request.
---
 net/rds/tcp_recv.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/net/rds/tcp_recv.c b/net/rds/tcp_recv.c
index ffe843ca2..29db73df8 100644
--- a/net/rds/tcp_recv.c
+++ b/net/rds/tcp_recv.c
@@ -213,6 +213,20 @@ static int rds_tcp_data_recv(read_descriptor_t *desc, struct sk_buff *skb,
 			}
 		}
 
+		/*
+		 * The payload is queued on tinc until the whole message has
+		 * arrived, so a peer must not announce more than a sender is
+		 * allowed to send. Check on every pass, not only when the
+		 * header completes: the drop is asynchronous and more data
+		 * can arrive before the connection is shut down.
+		 */
+		if (!tc->t_tinc_hdr_rem &&
+		    tc->t_tinc_data_rem > RDS_MAX_MSG_SIZE) {
+			rds_conn_path_drop(cp, false);
+			desc->error = -EPROTO;
+			goto out;
+		}
+
 		if (left && tc->t_tinc_data_rem) {
 			to_copy = min(tc->t_tinc_data_rem, left);
 

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261110-h047-send-52025d442823

Best regards,
--  
Weidong Wang <weidongw@illinois.edu>

