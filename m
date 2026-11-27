From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 06:30:27 +0000
Subject: [PATCH 5.15.y] netfilter: flowtable_offload: fix using
 __this_cpu_add in preemptible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-so5-nf-515-v1-1-ce02c323f842@certik.com>
X-B4-Tracking: v=1; b=H4sIAIIjCWsC/0WNwQ7CIBBEf6XZs1uFQG38lcYD0MViDBi2NjVN/
 13Qg8d5mXmzAVMOxHBpNsi0BA4pliAODbjJxBthGEsGeZKdEPKMnDRGj1po7JSxSklv+p6gDJ6
 ZfFi/sgF0K3T7huuP88veyc3VVJvWMKHNJrqpIqY4zik9sPLj/wH2/QPcl1T/oQAAAA==
X-Change-ID: 20261127-so5-nf-515-64ab442fa88e
To: stable@vger.kernel.org
Cc: Xin Long <lucien.xin@gmail.com>, 
 Pablo Neira Ayuso <pablo@netfilter.org>, netfilter-devel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795761026; l=3298;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=DPEyyVIOnnhk/htjRMSlOemmYqz4g1GxjdwvS3F9YOs=;
 b=MeaNcLNv9bCcv5l7LrlZ0n/o/xYXKR9dWAyklAuUAcmIIky9a+iT6ARLq/w+v1/WChbKXDpWz
 N2d7yUEluinBOhhfRNXVbH7zgx6ZgjHsB/COR7BiqJYP2ZmqAy4HP+P
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Xin Long <lucien.xin@gmail.com>

commit a81047154e7ce4eb8769d5d21adcbc9693542a79 upstream.

flow_offload_queue_work() can be called in workqueue without
bh disabled, like the call trace showed in my act_ct testing,
calling NF_FLOW_TABLE_STAT_INC() there would cause a call
trace:

  BUG: using __this_cpu_add() in preemptible [00000000] code: kworker/u4:0/138560
  caller is flow_offload_queue_work+0xec/0x1b0 [nf_flow_table]
  Workqueue: act_ct_workqueue tcf_ct_flow_table_cleanup_work [act_ct]
  Call Trace:
   <TASK>
   dump_stack_lvl+0x33/0x46
   check_preemption_disabled+0xc3/0xf0
   flow_offload_queue_work+0xec/0x1b0 [nf_flow_table]
   nf_flow_table_iterate+0x138/0x170 [nf_flow_table]
   nf_flow_table_free+0x140/0x1a0 [nf_flow_table]
   tcf_ct_flow_table_cleanup_work+0x2f/0x2b0 [act_ct]
   process_one_work+0x6a3/0x1030
   worker_thread+0x8a/0xdf0

This patch fixes it by using NF_FLOW_TABLE_STAT_INC_ATOMIC()
instead in flow_offload_queue_work().

Note that for FLOW_CLS_REPLACE branch in flow_offload_queue_work(),
it may not be called in preemptible path, but it's good to use
NF_FLOW_TABLE_STAT_INC_ATOMIC() for all cases in
flow_offload_queue_work().

Fixes: b038177636f8 ("netfilter: nf_flow_table: count pending offload workqueue tasks")
Signed-off-by: Xin Long <lucien.xin@gmail.com>
Signed-off-by: Pablo Neira Ayuso <pablo@netfilter.org>
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.1.y and newer already have this fix.

Tested on v5.15.226:
- x86_64 allmodconfig W=1 build of net/netfilter/nf_flow_table_offload.o,
  base vs patched, no new warnings
- booted base and patched kernels under QEMU/KVM and ran the netfilter
  software flowtable cases, all passing on both. Hardware offload wasn't
  available, so the offload counters weren't exercised.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

net/netfilter/nf_flow_table_offload.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
---
 net/netfilter/nf_flow_table_offload.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/net/netfilter/nf_flow_table_offload.c b/net/netfilter/nf_flow_table_offload.c
index 60e9c03d697f..3400a31c7df7 100644
--- a/net/netfilter/nf_flow_table_offload.c
+++ b/net/netfilter/nf_flow_table_offload.c
@@ -1056,13 +1056,13 @@ static void flow_offload_queue_work(struct flow_offload_work *offload)
 	struct net *net = read_pnet(&offload->flowtable->net);
 
 	if (offload->cmd == FLOW_CLS_REPLACE) {
-		NF_FLOW_TABLE_STAT_INC(net, count_wq_add);
+		NF_FLOW_TABLE_STAT_INC_ATOMIC(net, count_wq_add);
 		queue_work(nf_flow_offload_add_wq, &offload->work);
 	} else if (offload->cmd == FLOW_CLS_DESTROY) {
-		NF_FLOW_TABLE_STAT_INC(net, count_wq_del);
+		NF_FLOW_TABLE_STAT_INC_ATOMIC(net, count_wq_del);
 		queue_work(nf_flow_offload_del_wq, &offload->work);
 	} else {
-		NF_FLOW_TABLE_STAT_INC(net, count_wq_stats);
+		NF_FLOW_TABLE_STAT_INC_ATOMIC(net, count_wq_stats);
 		queue_work(nf_flow_offload_stats_wq, &offload->work);
 	}
 }

---
base-commit: 4f2df9a01754521fbba3493e8ad91ef65515e68c
change-id: 20261127-so5-nf-515-64ab442fa88e

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

