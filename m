MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-ktls-close-c-v1-1-1470bb718a8d@certik.com>
X-B4-Tracking: v=1; b=H4sIAKltCWsC/yWMywrCMBBFf6XM2gETJAV/RVzkMbGjIZFMFKH03
 5vY5T3cc1YQqkwC12mFSl8WLrkPdZrALzY/CDn0DfqsjVJ6xldLgj4VIfRoQoiGzCW4OUJX3pU
 i//65G2RqcD+gfNyTfBuhcXO2267a7JeBhHJopSQcHLZtB/iYhj+VAAAA
X-Change-ID: 20261127-ktls-close-c-6ddf6e64db7f
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 10:08:46 +0000
Subject: [PATCH net] tls: use non-blocking sends in tx_work_handler
To: netdev@vger.kernel.org
Cc: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, Sabrina Dubroca <sd@queasysnail.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Willem de Bruijn <willemb@google.com>, 
 Simon Horman <horms@kernel.org>, Vakul Garg <vakul.garg@nxp.com>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>, 
 syzbot+ca1345cca66556f3d79b@syzkaller.appspotmail.com, security@kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795780009; l=3769;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=+PhrH4oc7Z2Y18ZJgTa1CjrkTC4OCH1ulidgJIEbwDM=;
 b=7r5ZdlysBbZ0RSpAe6vNMdUIAUPHfdPuscSnFlM6LXpKr/iQBNiHQSspFDmpbRAbufN5XZnxi
 Q5rkD6ZMA+GArl6FTWR30ETGj1vq0YE7IXmHt+kNjeqHRl+QDvprBh/
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tx_work_handler() calls tls_tx_records(sk, -1), so each record is
pushed with the flags of the sendmsg() call that created it. When a
blocking send returns early (signal or SO_SNDTIMEO) and leaves a
partially sent record, the work handler pushes the rest with blocking
flags. If the peer keeps its window closed, the worker sleeps in
sk_stream_wait_memory() with no timeout. tls_sk_proto_close() then
waits for it in disable_delayed_work_sync(), so the closing task sits
in D state and ignores SIGKILL.

Each such socket holds a system_wq worker. With the tls module loaded,
an unprivileged local user can occupy all events workers on a CPU this
way (1024 on a one-CPU test guest), which stalls
schedule_on_each_cpu() callers.

Pass MSG_DONTWAIT from the work handler. On -EAGAIN the record stays on
tx_list and tls_sw_write_space() schedules the work again when TCP has
room. The close path does not change: tls_sw_release_resources_tx()
still calls tls_tx_records(sk, -1) from process context, so data
queued before close() is still flushed with the socket's own blocking
semantics and the FIN follows it. The worker no longer applies the
saved per-record flags, such as MSG_MORE or MSG_NOSIGNAL, which belong
to a sendmsg() call that has already returned.

Jiayuan Chen proposed the same approach earlier with a new extra_flags
argument to tls_tx_records() (Link below). This version needs no new
argument, and the close flush that review of that patch focused on is
unchanged.

Reported-by: syzbot+ca1345cca66556f3d79b@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=ca1345cca66556f3d79b
Link: https://lore.kernel.org/netdev/20260227063231.168520-1-jiayuan.chen@linux.dev/
Fixes: a42055e8d2c3 ("net/tls: Add support for async encryption of records for performance")
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
Tested on x86_64 UML with KASAN at v7.4-rc4 (9437ee8b6cf6), as uid 1000
with no capabilities or namespaces, over loopback:
- Interrupted 256 KiB send, peer reads 1 KiB and stops, then close():
  stock and reverted, the closer stays in D state 33 s after SIGKILL
  with the worker in sk_stream_wait_memory(). Patched, the closer is in
  S state in the normal close flush and SIGKILL ends it within 3 s.
- 1900 kTLS pairs, each with a partial send after a 20 ms SO_SNDTIMEO:
  stock and reverted, 1024 busy events workers and a
  /proc/sys/vm/stat_refresh write over 10 s. Patched, 0 busy workers
  and 11 ms.
- Patched controls: an immediate close after an interrupted send
  delivered and decrypted all 32768 accepted bytes. With the sender
  idle (no further send, no close) after the worker got -EAGAIN, the
  next write_space rescheduled it and a slow reader still got all
  32768 bytes. An uninterrupted send delivered all 262144 bytes, and
  plain TCP is unchanged.
- No KASAN, BUG or WARNING in any run. The patch applies unchanged to
  6.1.y, 6.6.y, 6.12.y and 6.18.y.

A reproducer is available if it helps.

This was found and the fix prepared with AI coding tools (OpenAI Codex
agents, with review by Claude). I went over the analysis, the earlier
thread and the patch before signing off.

 net/tls/tls_sw.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/tls/tls_sw.c b/net/tls/tls_sw.c
index 226e0f176..16dcd134e 100644
--- a/net/tls/tls_sw.c
+++ b/net/tls/tls_sw.c
@@ -2428,7 +2428,7 @@ static void tx_work_handler(struct work_struct *work)
 
 	if (mutex_trylock(&tls_ctx->tx_lock)) {
 		lock_sock(sk);
-		tls_tx_records(sk, -1);
+		tls_tx_records(sk, MSG_DONTWAIT);
 		release_sock(sk);
 		mutex_unlock(&tls_ctx->tx_lock);
 	} else if (!test_and_set_bit(BIT_TX_SCHEDULED, &ctx->tx_bitmask)) {
-- 
2.43.0

