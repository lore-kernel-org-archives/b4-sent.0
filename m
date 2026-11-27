MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-ktls-recwait-v1-1-81155599e61e@certik.com>
X-B4-Tracking: v=1; b=H4sIAIS3CWsC/yWMSw7CMAwFr1J5jSUSBFG5CmLhJIYaqgTF4SNVv
 TsJLGf03iygXIQVjsMChV+iklMDsxkgTJSujBIbg93agzHW4b3OioXDm6QiOed24z6YSCO0y6P
 wRT6/3AkSVzj/pT79jUPtoT7zpIy+UApTV8op1pxn7B7W9QtzdyRplQAAAA==
X-Change-ID: 20261127-ktls-recwait-a777395c1da9
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 14:01:16 +0000
Subject: [PATCH net] tls: avoid recursion in tls_rx_rec_wait()
To: netdev@vger.kernel.org
Cc: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, Sabrina Dubroca <sd@queasysnail.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Willem de Bruijn <willemb@google.com>, 
 Simon Horman <horms@kernel.org>, security@kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795798916; l=3158;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=rZeJn4EPp2cBQrhNXU2Mo53D8TwNxpANd8sKyNzy5mg=;
 b=iJwGOSvpnsl63KLZjPggQM5WQoytsb/8muG0PrCwGhIo2o3ucGkTRk1+eiQEomg/LzkrmD5Jf
 lqAxYgl2dJmBUPR6qOoDLjUNBGrWxmTTqE4l+HgnwmkyBHIly9WK3MK
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a ready record disappears from the TCP receive queue while the
socket lock is released, tls_strp_msg_load() returns false and
tls_rx_rec_wait() retries by calling itself.

The self-call was expected to become a loop, but the wait entry is
address-taken and live across the call, so the compiler keeps a real
call. GCC 13.3 and Clang 18.1 both do this on x86_64 defconfig and on a
distro config, with and without KASAN, costing 128 to 288 bytes of
stack per retry. A local user can keep draining the queue with
TCP_ZEROCOPY_RECEIVE while a reader waits and overflow the kernel
stack. With CONFIG_VMAP_STACK that hits the guard page and panics.

Go back to the top of the function instead, as suggested when the
retry was added, resetting released and ret to what the recursive call
used.

Suggested-by: Paolo Abeni <pabeni@redhat.com>
Link: https://lore.kernel.org/netdev/b3a83032-8ed4-4d5d-9df9-6dbd02acac1c@redhat.com/
Fixes: 6db015fc4b5d ("tls: handle data disappearing from under the TLS ULP")
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
Tested under x86_64 UML (VMAP_STACK, 16 KiB stack, PANIC_ON_OOPS) with a
small UML-only change so the guard page hit gets reported, networking
code otherwise stock:

- Stock and with the patch reverted: an unprivileged process (uid
  1000, also tried as uid 65534 in its own user and net namespace)
  draining a waiting kTLS reader with TCP_ZEROCOPY_RECEIVE hit the
  stack guard page within 50 retry cycles under KASAN, and within 100
  cycles on a non-KASAN GCC build.
- Patched: the same driver completed 5000 drains, up to 743 in a row
  inside a single recvmsg() call, with no panic.
- Blocking, non-blocking, MSG_WAITALL, MSG_PEEK, a 4 MiB transfer and
  EOF on close behave the same on stock and patched.
- W=1 build of net/tls/ is clean.

The tls module has to be built in or already loaded, since an
unprivileged TCP_ULP setsockopt won't autoload it. A reproducer is
available if it helps.

This was found and the fix prepared with AI coding tools (OpenAI Codex
agents, with review by Claude). I went over the analysis and the patch
before signing off.

diff --git a/net/tls/tls_sw.c b/net/tls/tls_sw.c
index 226e0f176fdc..363aae36ac69 100644
--- a/net/tls/tls_sw.c
+++ b/net/tls/tls_sw.c
@@ -1104,9 +1104,11 @@ tls_rx_rec_wait(struct sock *sk, bool nonblock, bool released, bool has_copied)
 	struct tls_context *tls_ctx = tls_get_ctx(sk);
 	struct tls_sw_context_rx *ctx = tls_sw_ctx_rx(tls_ctx);
 	DEFINE_WAIT_FUNC(wait, woken_wake_function);
-	int ret = 0;
+	int ret;
 	long timeo;
 
+retry:
+	ret = 0;
 	/* a rekey is pending, let userspace deal with it */
 	if (unlikely(ctx->key_update_pending))
 		return -EKEYEXPIRED;
@@ -1167,8 +1169,10 @@ tls_rx_rec_wait(struct sock *sk, bool nonblock, bool released, bool has_copied)
 			return sock_intr_errno(timeo);
 	}
 
-	if (unlikely(!tls_strp_msg_load(&ctx->strp, released)))
-		return tls_rx_rec_wait(sk, nonblock, false, has_copied);
+	if (unlikely(!tls_strp_msg_load(&ctx->strp, released))) {
+		released = false;
+		goto retry;
+	}
 
 	return 1;
 }
-- 
2.43.0

