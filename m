From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH 0/2] net/sched: finish the qdisc_dequeue_peeked conversion
 (taprio, multiq)
Date: Thu, 25 Jun 2026 04:51:18 -0500
Message-Id: <20260625-b4-disp-31bcb279-v1-0-85c40b83c529@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABb6PGoC/x3MTQqAIBBA4avErBuwMe3nKtFCc6rZVChEIN09a
 fkt3suQOAonGKsMkW9Jch4FTV3BsrtjY5RQDKTIKksGfYtB0oW68YunbkDVE5vBaee0hZJdkVd
 5/uU0v+8Hn0+1GGIAAAA=
To: Vinicius Costa Gomes <vinicius.gomes@intel.com>, 
 Paolo Abeni <pabeni@redhat.com>, Jamal Hadi Salim <jhs@mojatatu.com>, 
 Jiri Pirko <jiri@resnulli.us>, Jakub Kicinski <kuba@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>
Cc: Simon Horman <horms@kernel.org>, netdev@vger.kernel.org, 
 Jarek Poplawski <jarkao2@gmail.com>, 
 Vladimir Oltean <vladimir.oltean@nxp.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782381078; l=4699;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=B7/s9d6mVek1Q/XNG+xw8Tpj1nPLed6zevlG4m/N6iQ=;
 b=r833+U02l28X7VE9MKQUlfqmiACBRaY/LH1TePDXczr8Q2WauMtTMHgCt+8yOwMaTu5tKOoWn
 w4+EgQKEOVXCJEl+t5zjFPXe+ou9m8m8TbfRjhpHqm1p3SE9T6h7T8a
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 77be155cba4e added peek emulation: a non-work-conserving qdisc's
->peek dequeues one skb and stashes it in the child's gso_skb. A parent
that peeks such a child must then take the packet with
qdisc_dequeue_peeked(), not a direct ->dequeue(), or the stashed skb is
bypassed and the child's qlen/backlog desync. sch_red and sch_sfb were
just fixed for this; taprio and multiq still take the direct path.

With a qfq child the desync re-enters qfq_dequeue on an emptied aggregate
list and dereferences NULL, panicking from softirq on ordinary egress.
taprio reaches it on its own (root-only software path, all gates open);
multiq reaches it when a peeking parent such as tbf wraps it over a
non-work-conserving grandchild. Both need only CAP_NET_ADMIN.

Confirmed under KASAN: the unpatched arm panics, the patched arm is
clean, and a work-conserving-child control is clean. The reproducers and
splats for both are below; the per-patch changes are one line each.

taprio reproducer (self-triggering, no parent qdisc needed):

  ip link add dummy0 numtxqueues 4 type dummy; ip link set dummy0 up
  ip addr add 10.10.11.10/24 dev dummy0
  tc qdisc add dev dummy0 root handle 1: taprio num_tc 2 \
     map 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 queues 1@0 1@1 \
     base-time 9000000000000000000 sched-entry S 03 200000 flags 0x0 clockid CLOCK_TAI
  tc qdisc replace dev dummy0 parent 1:1 handle 3: qfq
  tc class  add dev dummy0 classid 3:1 parent 3: qfq maxpkt 512 weight 1
  tc filter add dev dummy0 parent 3: protocol ip prio 1 matchall classid 3:1
  ping -c1 10.10.11.99 -I dummy0

[  903.769174] Oops: general protection fault, probably for non-canonical address 0xdffffc0000000009: 0000 [#1] SMP KASAN NOPTI
[  903.769953] KASAN: null-ptr-deref in range [0x0000000000000048-0x000000000000004f]
[  903.770456] CPU: 7 UID: 0 PID: 16162 Comm: ping Not tainted 7.1.0-rc5 #1 PREEMPT(lazy)
[  903.771725] RIP: 0010:qfq_dequeue+0x362/0x1580 [sch_qfq]
[  903.777452] Call Trace:
[  903.778311]  taprio_dequeue_from_txq+0x383/0x680 [sch_taprio]
[  903.778685]  taprio_dequeue_tc_priority+0x19a/0x330 [sch_taprio]
[  903.779645]  taprio_dequeue+0xa6/0x330 [sch_taprio]
[  903.780299]  __qdisc_run+0x16c/0x1890
[  903.780854]  __dev_queue_xmit+0x1ece/0x3390
[  903.784109]  ip_finish_output2+0x571/0x1da0
[  903.785996]  ip_output+0x26c/0x4d0
[  903.789572]  ping_v4_sendmsg+0xd22/0x12b0
[  903.796118]  __x64_sys_sendto+0xe0/0x1c0
[  903.796612]  do_syscall_64+0xee/0x590
[  903.818669] Kernel panic - not syncing: Fatal exception in interrupt

multiq reproducer (needs a peeking parent over a stashing child; tbf
values chosen to force it to throttle):

  ip link add dummy0 numtxqueues 2 type dummy; ip link set dummy0 up
  ip addr add 10.10.11.10/24 dev dummy0
  tc qdisc add dev dummy0 root handle 1: tbf rate 88bit burst 1661b \
     peakrate 2257333 minburst 1024 limit 7b
  tc qdisc add dev dummy0 parent 1: handle 2: multiq
  for b in 1 2; do                          # qfq on every band
    tc qdisc  add dev dummy0 parent 2:$b handle 3$b: qfq
    tc class  add dev dummy0 classid 3$b:1 parent 3$b: qfq maxpkt 512 weight 1
    tc filter add dev dummy0 parent 3$b: protocol ip prio 1 matchall classid 3$b:1
  done
  ping -c12 10.10.11.99 -I dummy0

[ 1066.385097] Oops: general protection fault, probably for non-canonical address 0xdffffc0000000009: 0000 [#1] SMP KASAN NOPTI
[ 1066.386385] KASAN: null-ptr-deref in range [0x0000000000000048-0x000000000000004f]
[ 1066.387227] CPU: 1 UID: 0 PID: 5357 Comm: ping Not tainted 7.1.0-rc5 #1 PREEMPT(lazy)
[ 1066.389183] RIP: 0010:qfq_dequeue+0x362/0x1580 [sch_qfq]
[ 1066.396316] Call Trace:
[ 1066.396768]  multiq_dequeue+0x163/0x360 [sch_multiq]
[ 1066.397885]  tbf_dequeue+0x6b9/0xf17 [sch_tbf]
[ 1066.398269]  __qdisc_run+0x16c/0x1890
[ 1066.399315]  __dev_queue_xmit+0x1ece/0x3390
[ 1066.403276]  ip_finish_output2+0x571/0x1da0
[ 1066.404818]  ip_output+0x26c/0x4d0
[ 1066.408620]  ping_v4_sendmsg+0xd22/0x12b0
[ 1066.415264]  __x64_sys_sendto+0xe0/0x1c0
[ 1066.416251]  do_syscall_64+0xee/0x590
[ 1066.441210] Kernel panic - not syncing: Fatal exception in interrupt

---
Bryam Vargas (2):
      net/sched: sch_taprio: Replace direct dequeue call with peek and qdisc_dequeue_peeked
      net/sched: sch_multiq: Replace direct dequeue call with peek and qdisc_dequeue_peeked

 net/sched/sch_multiq.c | 2 +-
 net/sched/sch_taprio.c | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
---
base-commit: 02f144fbb4c86c360495d33debe307cb46a57f95
change-id: 20260625-b4-disp-31bcb279-082e59a3aa36

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

