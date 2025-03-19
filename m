From: Nikhil Jha <njha@janestreet.com>
Date: Wed, 19 Mar 2025 13:02:40 -0400
Subject: [PATCH v2 2/2] sunrpc: don't immediately retransmit on seqno miss
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-rfc2203-seqnum-cache-v2-2-2c98b859f2dd@janestreet.com>
References: <20250319-rfc2203-seqnum-cache-v2-0-2c98b859f2dd@janestreet.com>
In-Reply-To: <20250319-rfc2203-seqnum-cache-v2-0-2c98b859f2dd@janestreet.com>
To: Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 Chuck Lever <chuck.lever@oracle.com>, Jeff Layton <jlayton@kernel.org>, 
 Neil Brown <neilb@suse.de>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>
Cc: linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 Nikhil Jha <njha@janestreet.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742403794; l=1835;
 i=njha@janestreet.com; s=20250314; h=from:subject:message-id;
 bh=BUY6rJprONjD4kvNKWmmzFeJCgyo6ppGGxibOm8/Kxc=;
 b=xdX2yxAJ/6/gUy68y6Q9cvESRYHhyp5Lpb4S5e+WaYic8JxfVG7+vTuPjx6Py8ArM1tFBwawI
 LNh8oa3AoLGCNQmi/ZEwy7FJYnAsDDey9LdNm+FHLGHn8/GiRCaQvPz
X-Developer-Key: i=njha@janestreet.com; a=ed25519;
 pk=92gWYi0ImmcatlW+pFEFh9viqpRf/PE8phYeWuNeGaA=
X-Endpoint-Received: by B4 Relay for njha@janestreet.com/20250314 with auth_id=360
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

RFC2203 requires that retransmitted messages use a new gss sequence
number, but the same XID. This means that if the server is just slow
(e.x. overloaded), the client might receive a response using an older
seqno than the one it has recorded.

Currently, Linux's client immediately retransmits in this case. However,
this leads to a lot of wasted retransmits until the server eventually
responds faster than the client can resend.

Client -> SEQ 1 -> Server
Client -> SEQ 2 -> Server
Client <- SEQ 1 <- Server (misses, expecting seqno = 2)
Client -> SEQ 3 -> Server (immediate retransmission on miss)
Client <- SEQ 2 <- Server (misses, expecting seqno = 3)
Client -> SEQ 4 -> Server (immediate retransmission on miss)
... and so on ...

This commit makes it so that we ignore messages with bad checksums
due to seqnum mismatch, and rely on the usual timeout behavior for
retransmission instead of doing so immediately.

Signed-off-by: Nikhil Jha <njha@janestreet.com>
---
 net/sunrpc/clnt.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/net/sunrpc/clnt.c b/net/sunrpc/clnt.c
index 2fe88ea79a70c134e58abfb03fca230883eddf1f..98c0880ec18a8b80371e20f65e7a57a8d9244f7f 100644
--- a/net/sunrpc/clnt.c
+++ b/net/sunrpc/clnt.c
@@ -2760,8 +2760,13 @@ rpc_decode_header(struct rpc_task *task, struct xdr_stream *xdr)
 	case -EPROTONOSUPPORT:
 		goto out_err;
 	case -EACCES:
-		/* Re-encode with a fresh cred */
-		fallthrough;
+		/* possible RPCSEC_GSS out-of-sequence event (RFC2203),
+		 * reset recv state and keep waiting, don't retransmit
+		 */
+		task->tk_rqstp->rq_reply_bytes_recvd = 0;
+		task->tk_status = xprt_request_enqueue_receive(task);
+		task->tk_action = call_transmit_status;
+		return -EBADMSG;
 	default:
 		goto out_garbage;
 	}

-- 
2.43.5

