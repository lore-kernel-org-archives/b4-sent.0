From: Quanye Yang <quanyeyang@proton.me>
Date: Mon, 07 Sep 2026 23:12:51 +0800
Subject: [PATCH mptcp-net v4] mptcp: fix data-race in
 mptcp_subflow_get_send / tcp_ack
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260907-mptcp-snd-una-race-v4-1-6cd76668a8e3@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22OQQ6CMBREr0L+2m9qERBW3sOwaMtHakLbtIVoC
 He3gEuXk5k3MwsE8poCNNkCnmYdtDVJXE8ZqEGYJ6HukgbOeMlqVuLoonIYTIeTEeiFIpSUTE4
 3LusKEug89fq9lz7gyBuK0B5WmOSLVNxKt/CgQ7T+sx+Y8x35bVX/tuYcGZaFFKwresb55e68j
 dacR4J2Xdcv/EH+QdEAAAA=
X-Change-ID: 20260906-mptcp-snd-una-race-be0262e82b97
To: mptcp@lists.linux.dev
Cc: pabeni@redhat.com, geliang@kernel.org, matttbe@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788793985; l=6105;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=16sVBMvvNv6uANW5wJoXGNVKFp/tLZOlBxzNyVXE+ZU=;
 b=cMCKmQ/Nut9txGLlioDVDOFB/Td36+nX56XfNq1BgBMyYamO5K4Xp9NOaMURxMvq9mnkPmRhd
 rwx5MoEq4TpA2BdeRp8hh+gCzXQDPMLKloFXJaaRCK9IeT1MVMBV+iq
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Syzkaller found this data-race:

  BUG: KCSAN: data-race in mptcp_subflow_get_send / tcp_ack

  write (marked) to 0xffff88800ea00eaa of 1 bytes by interrupt on cpu 1:
   inet_csk_clear_xmit_timer include/net/inet_connection_sock.h:209 [inline]
   tcp_rearm_rto net/ipv4/tcp_input.c:3536 [inline]
   tcp_set_xmit_timer net/ipv4/tcp_input.c:3556 [inline]
   tcp_ack+0x2d3f/0x4240 net/ipv4/tcp_input.c:4430
   tcp_rcv_established+0x46e/0x1fb0 net/ipv4/tcp_input.c:6678
   tcp_v4_do_rcv+0x356/0x6e0 net/ipv4/tcp_ipv4.c:1854
   tcp_v4_rcv+0x1b04/0x26b0 net/ipv4/tcp_ipv4.c:2248
   ip_protocol_deliver_rcu+0x42/0x280 net/ipv4/ip_input.c:207
   ip_local_deliver_finish+0x18d/0x270 net/ipv4/ip_input.c:241
   NF_HOOK include/linux/netfilter.h:325 [inline]
   NF_HOOK include/linux/netfilter.h:319 [inline]
   ip_local_deliver+0xdb/0x200 net/ipv4/ip_input.c:262
   dst_input include/net/dst.h:480 [inline]
   ip_rcv_finish net/ipv4/ip_input.c:492 [inline]
   NF_HOOK include/linux/netfilter.h:325 [inline]
   NF_HOOK include/linux/netfilter.h:319 [inline]
   ip_rcv+0x206/0x230 net/ipv4/ip_input.c:612
   __netif_receive_skb_one_core+0xe9/0x110 net/core/dev.c:6264
   __netif_receive_skb+0x1d/0xd0 net/core/dev.c:6377
   process_backlog+0x16d/0x360 net/core/dev.c:6728
   __napi_poll+0x73/0x3a0 net/core/dev.c:7787
   napi_poll net/core/dev.c:7850 [inline]
   net_rx_action+0x6ee/0x800 net/core/dev.c:8007
   handle_softirqs+0xc1/0x260 kernel/softirq.c:645
   do_softirq kernel/softirq.c:546 [inline]
   do_softirq+0x40/0x60 kernel/softirq.c:533
   __local_bh_enable_ip+0x65/0x70 kernel/softirq.c:473
   __raw_spin_unlock_bh include/linux/spinlock_api_smp.h:237 [inline]
   _raw_spin_unlock_bh+0x1f/0x30 kernel/locking/spinlock.c:245
   spin_unlock_bh include/linux/spinlock.h:407 [inline]
   unlock_sock_fast include/net/sock.h:1773 [inline]
   mptcp_subflow_cleanup_rbuf net/mptcp/protocol.c:659 [inline]
   mptcp_cleanup_rbuf+0x300/0x380 net/mptcp/protocol.c:690
   mptcp_recvmsg+0x6bb/0xd50 net/mptcp/protocol.c:2495
   inet_recvmsg+0x204/0x210 net/ipv4/af_inet.c:894
   sock_recvmsg_nosec net/socket.c:1151 [inline]
   sock_recvmsg+0x11a/0x140 net/socket.c:1173
   __sys_recvfrom+0x178/0x240 net/socket.c:2331
   __do_sys_recvfrom net/socket.c:2346 [inline]
   __se_sys_recvfrom net/socket.c:2342 [inline]
   __x64_sys_recvfrom+0x76/0x90 net/socket.c:2342
   x64_sys_call+0x199f/0x1ca0 arch/x86/include/generated/asm/syscalls_64.h:46
   do_syscall_x64 arch/x86/entry/syscall_64.c:61 [inline]
   do_syscall_64+0xde/0x3d0 arch/x86/entry/syscall_64.c:84
   entry_SYSCALL_64_after_hwframe+0x77/0x7f

  read to 0xffff88800ea00eaa of 1 bytes by task 2523 on cpu 0:
   mptcp_timeout_from_subflow net/mptcp/protocol.c:609 [inline]
   mptcp_subflow_get_send+0x120/0x600 net/mptcp/protocol.c:1651
   mptcp_sched_default_get_send net/mptcp/sched.c:23 [inline]
   mptcp_sched_get_send+0x276/0x2b0 net/mptcp/sched.c:191
   __mptcp_push_pending+0xa6/0x370 net/mptcp/protocol.c:1802
   mptcp_release_cb+0x3b6/0x900 net/mptcp/protocol.c:3885
   release_sock+0x100/0x150 net/core/sock.c:3863
   sk_stream_wait_memory+0x4ea/0x9d0 net/core/stream.c:148
   mptcp_sendmsg+0x8fc/0x1220 net/mptcp/protocol.c:2145
   inet6_sendmsg+0xda/0xe0 net/ipv6/af_inet6.c:641
   sock_sendmsg_nosec net/socket.c:800 [inline]
   __sock_sendmsg net/socket.c:815 [inline]
   ____sys_sendmsg+0x409/0x680 net/socket.c:2713
   ___sys_sendmsg+0x11d/0x160 net/socket.c:2767
   __sys_sendmsg+0xde/0x160 net/socket.c:2799
   __do_sys_sendmsg net/socket.c:2804 [inline]
   __se_sys_sendmsg net/socket.c:2802 [inline]
   __x64_sys_sendmsg+0x45/0x50 net/socket.c:2802
   x64_sys_call+0x7aa/0x1ca0 arch/x86/include/generated/asm/syscalls_64.h:47
   do_syscall_x64 arch/x86/entry/syscall_64.c:61 [inline]
   do_syscall_64+0xde/0x3d0 arch/x86/entry/syscall_64.c:84
   entry_SYSCALL_64_after_hwframe+0x77/0x7f

  value changed: 0x05 -> 0x00

Reported by Kernel Concurrency Sanitizer on:
CPU: 0 UID: 0 PID: 2523 Comm: syz.2.3 Not tainted 7.2.0-g39d4f32c5d53 #76 PREEMPT(full)

The write is tcp_ack() dropping ICSK_TIME_LOSS_PROBE (0x05) with
smp_store_release() on icsk_pending, from the subflow receive path
after unlock_sock_fast().

The read is mptcp_timeout_from_subflow(), called from
mptcp_subflow_get_send() while holding the MPTCP socket lock. That
lock does not cover the TCP subflow's icsk_pending.

Use smp_load_acquire() to pair with TCP's store-release updates and
with the other lockless readers of this field.

Fixes: 33d41c9cd74c ("mptcp: more accurate timeout")
Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/627
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
Changes in v4:
- drop the snd_una patch (already fixed by 96d846e3e2a7)
- drop the generic sk_err patch (will be sent separately to net)
- include the full KCSAN splat
- Link to v3: https://patch.msgid.link/20260907-mptcp-snd-una-race-v3-0-65ba0d5f0221@proton.me

Changes in v3:
- rebase on the MPTCP export branch
- wrap the snd_una field comment to satisfy checkpatch
- add fixes for the reported icsk_pending and sk_err races
- exclude the unrelated workqueue and timekeeping reports
---
 net/mptcp/protocol.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/net/mptcp/protocol.c b/net/mptcp/protocol.c
index 0b24e0afedfb..f4f63df9d787 100644
--- a/net/mptcp/protocol.c
+++ b/net/mptcp/protocol.c
@@ -606,7 +606,9 @@ static long mptcp_timeout_from_subflow(const struct mptcp_subflow_context *subfl
 {
 	const struct sock *ssk = mptcp_subflow_tcp_sock(subflow);
 
-	return inet_csk(ssk)->icsk_pending && !subflow->stale_count ?
+	/* Pair this lockless read with TCP's store-release updates. */
+	return smp_load_acquire(&inet_csk(ssk)->icsk_pending) &&
+	       !subflow->stale_count ?
 	       tcp_timeout_expires(ssk) - jiffies : 0;
 }
 

---
base-commit: 45f7c939f8b155208c7447517e588c9fb133388c
change-id: 20260906-mptcp-snd-una-race-be0262e82b97

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

