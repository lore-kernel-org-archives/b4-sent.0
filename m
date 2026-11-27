From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 03:45:33 +0000
Subject: [PATCH 5.15.y 1/3] sctp: validate cached peer INIT chunk length in
 COOKIE_ECHO processing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-so4-sctp-515-v1-1-bbee1a6af200@certik.com>
References: <20261127-so4-sctp-515-v1-0-bbee1a6af200@certik.com>
In-Reply-To: <20261127-so4-sctp-515-v1-0-bbee1a6af200@certik.com>
To: stable@vger.kernel.org
Cc: Xin Long <lucien.xin@gmail.com>, 
 Marcelo Ricardo Leitner <marcelo.leitner@gmail.com>, 
 linux-sctp@vger.kernel.org, netdev@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795751132; l=2266;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=eEi0YwdkXypuwuA9pjLZfEn7yjYj5qgMN4seHuxYJzQ=;
 b=wN6ijL1szIwA+sIhPm8hqnHjlV160TSQa+7xQ921Wdn/BGFRx5pgVF53lM+m/hFMrhWaepx3X
 jWlpfOCODEfAzJaWoWoYNrj62rBtqJ9Xbaa43c/ktCbnDa2DTg8ifiI
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Xin Long <lucien.xin@gmail.com>

commit 0861615c28de668669d748ef4eb913ea9262d13b upstream.

When a listening SCTP server processes a COOKIE_ECHO chunk, the cached
peer INIT chunk embedded after the cookie is parsed and its parameters
are later walked by sctp_process_init() using sctp_walk_params().

However, the chunk header length of this cached INIT chunk was not
validated against the remaining buffer in the COOKIE_ECHO payload. If
the length field is inflated, the parameter walk can run beyond the
actual received data, leading to out-of-bounds reads and potential
memory corruption during later parameter handling (e.g. STATE_COOKIE
processing and kmemdup() copies).

Add a bounds check in sctp_unpack_cookie() to ensure the cached INIT
chunk length does not exceed the available data in the COOKIE_ECHO
buffer before it is used.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Reported-by: Brian Geffon <bgeffon@google.com>
Signed-off-by: Xin Long <lucien.xin@gmail.com>
Link: https://patch.msgid.link/eb60825fa22d6f9e663c7d4dbb69f397b5d34d42.1780362366.git.lucien.xin@gmail.com
Signed-off-by: Jakub Kicinski <kuba@kernel.org>
[ adapted to 5.15.y: read the cached INIT from peer_init[] ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

 net/sctp/sm_make_chunk.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/net/sctp/sm_make_chunk.c b/net/sctp/sm_make_chunk.c
index c15d62ad24754..b599dd2c15bd4 100644
--- a/net/sctp/sm_make_chunk.c
+++ b/net/sctp/sm_make_chunk.c
@@ -1757,6 +1757,7 @@ struct sctp_association *sctp_unpack_cookie(
 	struct sctp_signed_cookie *cookie;
 	struct sk_buff *skb = chunk->skb;
 	struct sctp_cookie *bear_cookie;
+	struct sctp_chunkhdr *ch;
 	__u8 *digest = ep->digest;
 	enum sctp_scope scope;
 	unsigned int len;
@@ -1787,6 +1788,10 @@ struct sctp_association *sctp_unpack_cookie(
 	cookie = chunk->subh.cookie_hdr;
 	bear_cookie = &cookie->c;
 
+	ch = (struct sctp_chunkhdr *)&bear_cookie->peer_init[0];
+	if (ntohs(ch->length) > len - fixed_size)
+		goto malformed;
+
 	if (!sctp_sk(ep->base.sk)->hmac)
 		goto no_hmac;
 

-- 
2.43.0

