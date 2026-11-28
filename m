MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-ktls-close-v2a-v2-1-68a955cbbbcb@certik.com>
X-B4-Tracking: v=1; b=H4sIAMLgCmsC/yWMQQrCMBBFr1Jm7UA7WgleRVxM0qmNhkQysQild
 zfR5X/89zZQyV4ULt0GWVavPsU66NCBWzjeBf1UN1BP52Egg88SFF1IKrgS45FPM5mxZxkNVOm
 VZfafX/AKUQrc/lDf9iGutFS7Wa6+zRzd0pBKnEpKARuHff8Cu7YRXpcAAAA=
X-Change-ID: 20261128-ktls-close-v2a-3a4f2850ae58
From: Dickson Wu <dickson.wu@certik.com>
Date: Sat, 28 Nov 2026 13:20:00 +0000
Subject: [PATCH net v2] tls: avoid blocking sends from workqueue context
To: netdev@vger.kernel.org
Cc: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, Sabrina Dubroca <sd@queasysnail.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Willem de Bruijn <willemb@google.com>, 
 Simon Horman <horms@kernel.org>, Vakul Garg <vakul.garg@nxp.com>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>, 
 syzbot+ca1345cca66556f3d79b@syzkaller.appspotmail.com, security@kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795875010; l=6182;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=iLvFDZaO9/KgsE/Y4B9g540F2tdGfRjJr0ZiapIJSAs=;
 b=kzfmU9dpLLYJ5eJHQP2aoA6KNV3Nl9W0m0T0YxLvIV7k1iYE63/SFV1K3BDmnhOm6D5TdfJdG
 DxnMJsGtTtgDSHr2YkccZ7KRanD2ePBPRJpa1TMmuSFd2Os/nqCtBhm
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tx_work_handler() calls tls_tx_records(sk, -1), so each record is
pushed with the flags of the sendmsg() call that created it. When a
blocking send returns early and leaves a partially sent record, the
work handler pushes the rest with blocking flags. If sk_sndtimeo is
infinite (the default, or an SO_SNDTIMEO cleared after the partial
send) and the peer keeps its window closed, the worker sleeps in
sk_stream_wait_memory() with no bound. tls_sk_proto_close() then waits
for it in disable_delayed_work_sync(), so the closing task sits in D
state and ignores SIGKILL.

Each such socket holds a system_wq worker. With the tls module loaded,
an unprivileged local user can occupy all events workers on a CPU this
way (1024 on a one-CPU test guest), which stalls
schedule_on_each_cpu() callers.

Pass MSG_DONTWAIT from the work handler. On -EAGAIN the record stays on
tx_list and tls_sw_write_space() schedules the work again when TCP has
room. One case has no such callback: when the TCP write and retransmit
queues are empty, tcp_sendmsg_locked() calls sk_write_space before it
returns, while splicing_pages is still set, so tls_write_space() skips
tls_sw_write_space(). In that case the handler requeues itself one
tick later.

The close flush can block the same way. tls_sw_release_resources_tx()
usually runs in the task calling close(), where a signal ends the wait.
The last fput can also run from delayed_fput, for example when AF_UNIX
garbage collection frees an SCM_RIGHTS cycle, and then a kworker blocks
in sk_stream_wait_memory() and holds up every later delayed fput. Use
MSG_DONTWAIT for the close flush when it runs in a kthread. Records it
cannot push are freed with the rest of tx_list, as they are when a
signal interrupts the flush in a user task. A close() from a user task
keeps the blocking flush. In-kernel TLS users (sunrpc, nvme-tcp) call
kernel_sock_shutdown() before the release on their normal teardown
paths, so the flush has nothing it can send there either way.

The worker no longer applies the saved per-record flags, such as
MSG_MORE or MSG_NOSIGNAL, which belong to a sendmsg() call that has
already returned.

Jiayuan Chen proposed MSG_DONTWAIT for the worker earlier with a new
extra_flags argument to tls_tx_records() (Link below). This version
needs no new argument.

Reported-by: syzbot+ca1345cca66556f3d79b@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=ca1345cca66556f3d79b
Link: https://lore.kernel.org/netdev/20260227063231.168520-1-jiayuan.chen@linux.dev/
Fixes: a42055e8d2c3 ("net/tls: Add support for async encryption of records for performance")
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
Changes in v2:
- Also use MSG_DONTWAIT for the close flush when it runs in a kthread.
  v1 left it blocking, and a delayed_fput kworker could still hang
  there (Sashiko review).
- Requeue the work one tick later after -EAGAIN with empty TCP queues,
  where tls_write_space() skips the TLS callback (Sashiko review).
- Say that the worker wait is unbounded only with an infinite
  sk_sndtimeo.
- v1: https://lore.kernel.org/r/20261127-ktls-close-c-v1-1-1470bb718a8d@certik.com

Tested on x86_64 UML with KASAN at mainline 7cd8495c0f16 (net/main
28a371228d4e has no change in the relevant TLS, TCP or AF_UNIX code),
as uid 1000 with no capabilities or namespaces, over loopback:
- Deferred fput: interrupt a 256 KiB send, then drop the socket
  through an AF_UNIX SCM_RIGHTS cycle that GC frees. Stock and v1
  leave a kworker in sk_stream_wait_memory() under delayed_fput, and a
  later deferred fput waits behind it until the peer reads. v2: no
  blocked worker, and the later fput completes at once.
- The v1 close-hang test: the closer stays in S state in the normal
  close flush, no worker sits in tx_work_handler, and SIGKILL ends it.
- 1900 kTLS pairs, each with a partial send under a 20 ms SO_SNDTIMEO
  that is then reset to infinite, 30 s hold: 0 busy events workers
  (stock 1024), /proc/sys/vm/stat_refresh writes 11-12 ms throughout.
- Controls: an ordinary close delivered all 32768 accepted bytes; with
  the sender idle after the worker got -EAGAIN, a slow reader still got
  all 32768 bytes; an uninterrupted send delivered all 262144 bytes.
- No KASAN, BUG or WARNING in any run.

Not covered: I found the empty-queue requeue gap by reading the code
and did not hit it at runtime, since UML here has only synchronous
crypto. If TCP memory stays exhausted while both queues are empty, the
worker retries once per tick until memory frees up. Async crypto and
device offload were not exercised.

This was found and the fix prepared with AI coding tools (OpenAI Codex
agents, with review by Claude). I went over the analysis, the review
and the patch before signing off.

 net/tls/tls_sw.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/net/tls/tls_sw.c b/net/tls/tls_sw.c
index 226e0f176f..50dc45ad0d 100644
--- a/net/tls/tls_sw.c
+++ b/net/tls/tls_sw.c
@@ -2327,7 +2327,7 @@ void tls_sw_release_resources_tx(struct sock *sk)
 	/* Wait for any pending async encryptions to complete */
 	tls_encrypt_async_wait(ctx);
 
-	tls_tx_records(sk, -1);
+	tls_tx_records(sk, current->flags & PF_KTHREAD ? MSG_DONTWAIT : -1);
 
 	/* Free up un-sent records in tx_list. First, free
 	 * the partially sent record if any at head of tx_list.
@@ -2427,10 +2427,17 @@ static void tx_work_handler(struct work_struct *work)
 		return;
 
 	if (mutex_trylock(&tls_ctx->tx_lock)) {
+		bool retry;
+		int ret;
+
 		lock_sock(sk);
-		tls_tx_records(sk, -1);
+		ret = tls_tx_records(sk, MSG_DONTWAIT);
+		retry = ret == -EAGAIN && tcp_rtx_and_write_queues_empty(sk);
 		release_sock(sk);
 		mutex_unlock(&tls_ctx->tx_lock);
+		if (retry &&
+		    !test_and_set_bit(BIT_TX_SCHEDULED, &ctx->tx_bitmask))
+			schedule_delayed_work(&ctx->tx_work.work, 1);
 	} else if (!test_and_set_bit(BIT_TX_SCHEDULED, &ctx->tx_bitmask)) {
 		/* Someone is holding the tx_lock, they will likely run Tx
 		 * and cancel the work on their way out of the lock section.
-- 
2.43.0

