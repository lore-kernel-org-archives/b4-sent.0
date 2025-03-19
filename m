From: Nikhil Jha <njha@janestreet.com>
Subject: [PATCH v2 0/2] fix gss seqno handling to be more rfc-compliant
Date: Wed, 19 Mar 2025 13:02:38 -0400
Message-Id: <20250319-rfc2203-seqnum-cache-v2-0-2c98b859f2dd@janestreet.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAK742mcC/x3MTQ5AMBBA4avIrE1SU/V3FbGQmjILRRsiEXfXW
 H6L9x6IHIQjdNkDgS+JsvkEyjOwy+hnRpmSgRQZpYsSg7NESmPkw58r2tEujIZ0005F6UxVQ0r
 3wE7uf9sP7/sBx9CHy2YAAAA=
X-Change-ID: 20250314-rfc2203-seqnum-cache-52389d14f567
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742403794; l=2309;
 i=njha@janestreet.com; s=20250314; h=from:subject:message-id;
 bh=aEenN2rtAVG/y027IH9IeDfb7ILU1h7EudrieTStR2Y=;
 b=G5nQT809qbEmXwOvoaSrMtCSMogF7ODItEYkYescwgV3YjoixFzV6RzTnGWdsI8AjlXkLzyJq
 FZ0MZHZGAuwBJf4+nCLEaL8KvzVKIsmuwHkHlGD4X1DapwUl28dpjkT
X-Developer-Key: i=njha@janestreet.com; a=ed25519;
 pk=92gWYi0ImmcatlW+pFEFh9viqpRf/PE8phYeWuNeGaA=
X-Endpoint-Received: by B4 Relay for njha@janestreet.com/20250314 with auth_id=360
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the client retransmits an operation (for example, because the
server is slow to respond), a new GSS sequence number is associated with
the XID. In the current kernel code the original sequence number is
discarded. Subsequently, if a response to the original request is
received there will be a GSS sequence number mismatch. A mismatch will
trigger another retransmit, possibly repeating the cycle, and after some
number of failed retries EACCES is returned.

RFC2203, section 5.3.3.1 suggests a possible solution... “cache the
RPCSEC_GSS sequence number of each request it sends” and "compute the
checksum of each sequence number in the cache to try to match the
checksum in the reply's verifier." This is what FreeBSD’s implementation
does (rpc_gss_validate in sys/rpc/rpcsec_gss/rpcsec_gss.c).

However, even with this cache, retransmits directly caused by a seqno
mismatch can still cause a bad message interleaving that results in this
bug. The RFC already suggests ignoring incorrect seqnos on the server
side, and this seems symmetric, so this patchset also applies that
behavior to the client.

These two patches are *not* dependent on each other. I tested them by
delaying packets with a Python script hooked up to NFQUEUE. If it would
be helpful I can send this script along as well.

Signed-off-by: Nikhil Jha <njha@janestreet.com>
---
Changes since v1:
 * Maintain the invariant that the first seqno is always first in
   rq_seqnos, so that it doesn't need to be stored twice.
 * Minor formatting, and resending with proper mailing-list headers so the
   patches are easier to work with.

---
Nikhil Jha (2):
      sunrpc: implement rfc2203 rpcsec_gss seqnum cache
      sunrpc: don't immediately retransmit on seqno miss

 include/linux/sunrpc/xprt.h    | 17 +++++++++++-
 include/trace/events/rpcgss.h  |  4 +--
 include/trace/events/sunrpc.h  |  2 +-
 net/sunrpc/auth_gss/auth_gss.c | 59 ++++++++++++++++++++++++++----------------
 net/sunrpc/clnt.c              |  9 +++++--
 net/sunrpc/xprt.c              |  3 ++-
 6 files changed, 64 insertions(+), 30 deletions(-)
---
base-commit: 7eb172143d5508b4da468ed59ee857c6e5e01da6
change-id: 20250314-rfc2203-seqnum-cache-52389d14f567

Best regards,
-- 
Nikhil Jha <njha@janestreet.com>

