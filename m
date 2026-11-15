From: Alireza Asgari <alireza@asgari.net>
Subject: [PATCH RFC nf-next 0/9] netfilter: nfqueue: account queued memory
 and reserve capacity
Date: Sun, 15 Nov 2026 22:34:40 +0000
Message-Id: <20261115-b4-nfqueue-memory-accounting-v1-0-b9cc30819997@asgari.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIAz+moC/zWNywrCMBBFf6XM2oGm1aJuBT/ArbhI0kkboRPNQ
 yql/26iuDz3wD0LBPKWAhyrBTy9bLCOM4hNBXqUPBDaPjM0ddMJIXaotsjmmSgRTjQ5/0aptUs
 cLQ/YdC3Ve2Gobw+QLx6ejJ2/91e4nE9lY4NMc4Tbz4ek7qRjaRSrZCBUXrIey/RPeaOxKFjXD
 xaR2OyzAAAA
X-Change-ID: 20261115-b4-nfqueue-memory-accounting-263e081fed39
To: netfilter-devel@vger.kernel.org, linux-mm@kvack.org
Cc: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, 
 Pablo Neira Ayuso <pablo@netfilter.org>, Florian Westphal <fw@strlen.de>, 
 Phil Sutter <phil@nwl.cc>, Shuah Khan <shuah@kernel.org>, 
 Tejun Heo <tj@kernel.org>, Vladimir Davydov <vdavydov.dev@gmail.com>, 
 Chris Down <chris@chrisdown.name>, 
 Zhang Jiao <zhangjiao2@cmss.chinamobile.com>, Song Hu <husong@kylinos.cn>, 
 cgroups@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Alireza Asgari <alireza@asgari.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794782082; l=13967;
 i=alireza@asgari.net; s=alireza-kernel; h=from:subject:message-id;
 bh=sVOSxPCzcEKroZLT1ZB9+sb2ybkatBgpO2arBKaZ8+4=;
 b=3uQlX/uMIet9NBQ6XX0JnEs3Zgeg5QXNzvkTvykx/9+hCP5948PgDFqlXEVntuBqz6pJYPlEP
 acswL1OybwABc3DPr1ipaoEEyU/NyteoCbzVeFpocgu7jl7TcF+3TGA
X-Developer-Key: i=alireza@asgari.net; a=ed25519;
 pk=wuQ0/M69FqoVnrCMUJ13EQCwrCwVjCrtz75k15vW8tw=
X-Endpoint-Received: by B4 Relay for alireza@asgari.net/alireza-kernel with auth_id=1055
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

NFQUEUE limits pending packets by count, although packet buffers can have
substantially different memory costs. Large skbs and GSO aggregates can
therefore consume much more memory than the packet-count limit suggests.
Independent queue limits also allow userspace to multiply the available
capacity by creating many queues.

This series implements the approach suggested by Florian Westphal in the
NFQUEUE memory-exhaustion discussion [1]: add a per-queue byte allowance
and reserve queue capacity against a memory cgroup. His message proposed
the overall approach; the ownership, reservation interface, and failure
policies below are implementation choices proposed for discussion in this
RFC.

The byte allowance is derived from the existing maximum queue length:

    (u64)queue_maxlen * (SKB_DATA_ALIGN(sizeof(struct sk_buff)) + 2048)

The 2048-byte contribution represents a nominal complete skb head,
including its shared-info area. The shell contribution follows skb
accounting alignment. The allowance is pooled across the queue, and the
existing packet-count limit remains enforced. Large skbs can exhaust the
byte allowance before the packet limit is reached. Existing drop and
FAIL_OPEN dispositions are preserved. No new userspace configuration
attribute is introduced.

The nominal head size is a policy choice, not a bound on ordinary receive
buffers. For example, mvneta can build a small packet's skb around a whole
page. On a 4 KiB-page system its initial cost is the aligned shell plus
4096 bytes, so it cannot enter an empty length-one queue under this policy.
With FAIL_OPEN disabled it is dropped; with FAIL_OPEN enabled it bypasses
that queue daemon's inspection and continues through reinjection. Later
Netfilter processing can still drop it. An independently configurable byte
limit could accommodate such buffers without increasing packet depth, but
the default for applications that omit it would also need agreement.

Each admitted entry saves its skb's admission-time truesize. That charge
remains through detachment from the pending list, including batch verdicts,
and is released when NFQUEUE reinjection processing begins. Failed
notification delivery rolls back admission and its charge. This ledger
measures saved accounting costs, rather than every allocation associated
with a packet; transient allocations and later payload expansion are
outside that measure.

The local byte limit applies in every network namespace. Outside the
initial network namespace, BIND captures an accounting owner from the
configuring task. The queue initially uses COPY_NONE and reserves no
capacity. Userspace can set its packet limit before enabling COPY_META or
COPY_PACKET; that first activation obtains the complete reservation before
enabling admission. A failed activation leaves the queue's prior limits,
mode, and flags intact. This allows a separate BIND, smaller-limit, and
enable sequence without first paying for the default queue size.

A BIND that includes configuration prepares the new instance privately,
including any activation reservation, and publishes it only on success.
Failed creation releases the private instance without exposing an inactive
queue to packet readers. In particular, a rule that bypasses an absent
queue cannot encounter a temporarily visible COPY_NONE queue while its
bundled creation is obtaining capacity. Standalone BIND still publishes an
inactive queue with its accounting owner captured.

Once activated, the queue retains its reservation policy even if userspace
later selects COPY_NONE. Resizing retains the BIND-time owner even if the
configuring task moves cgroups, subject to normal cgroup reparenting. The
charge makes queues owned within a constrained cgroup compete for its
budget. Reservations consume budget even for empty activated queues; they
do not preallocate packet storage or replace ordinary allocation charges.
Reservations captured with root ownership or disabled kmem accounting are
uncharged. A finite aggregate ceiling requires a constraining memory-cgroup
limit.

Charged capacity growth requires a 64-bit kernel. On 32-bit kernels,
in-range positive growth with a captured accounting owner fails with
-EOPNOTSUPP before charging or publishing a new configuration. Inactive
BIND and limit configuration remain possible; activating an affected queue
or increasing its existing reservation fails. Bundling activation into BIND
can therefore fail as well. The feature does not silently omit the charge.
Initial-network-namespace queues and reservations captured without a
chargeable owner remain supported. This restriction avoids making the
shared 32-bit page counters' arithmetic limits reachable with large virtual
charges; a per-queue maximum would not bound the aggregate hierarchy.

Using ordinary memcg charges means unused capacity contributes to
memory.current, kernel-memory statistics, and peak accounting. It can
affect configured memory.min/memory.low protection, memory.high pressure,
and the budget available to other allocations. Precharging makes capacity
refusal visible during configuration and avoids a new memcg charge
operation at packet admission. Charging retained bytes on admission instead
would avoid paying for unused capacity, but would move charging work and
possible refusal into the packet path. Neither approach reserves physical
memory or guarantees that later allocations succeed.

Increasing capacity obtains the additional reservation before publishing
the new limit. Failure leaves the existing configuration intact. Shrinking
preserves queued packets and retains page-rounded backing for the greater
of the configured allowance and outstanding saved charges. Excess capacity
is refunded as entries drain, with refund work serialized against resizing
and coordinated with queue destruction. Refunds settle the actual memory
counters as well as statistics, including charges inherited by root after
an owner's removal. On supported kernels, later growth under root ownership
remains uncharged and is excluded from those refunds.

The series also saturates the task's deferred memory.high page counter
instead of letting repeated nonblocking charges wrap it to zero. Large
virtual reservations can accumulate that debt before returning to userspace
without allocating corresponding physical pages. Saturation preserves
pending pressure handling; it does not change the owner-selection policy.

A separate MM prerequisite makes the memory.high delay calculation safe
across its scaling and multiplication steps, including consumption of the
deferred page debt. It corrects overflow and premature 32-bit truncation
while preserving the intended fixed-point rounding and previous
non-overflowing final delay results on 64-bit kernels. Large results remain
bounded at the existing maximum delay. This correction applies on both
32-bit and 64-bit kernels; it does not remove the reservation interface's
separate 64-bit restriction.

The arithmetic prerequisite overlaps Zhang Jiao's October submission [2]
and the earlier report from Song Hu [3]. Its description links the
associated MM review. The implementation here also covers the scaled
numerator and debt multiplication, and preserves sub-batch delay results.
The two generic MM fixes and their tests are separated from the reservation
interface for independent review; the arithmetic patch is an alternative
for discussion, not a revision of Zhang's submission.

The series introduces a bulk page-reservation interface in the memory
controller, with a referenced owner, transactional resizing, and module
support. Reservation growth uses GFP_NOWAIT and rejects PF_MEMALLOC growth,
avoiding direct reclaim, memcg OOM invocation, and forced overcharging.
This avoids repeated reclaim while queue configuration is serialized, but
permits refusal despite reclaimable memory. Deferred memory.high handling
remains possible, with an existing ownership limitation: the charge path
records deferred work on the current task, and the later handler selects
the cgroup from that task's memory context. If a queue bound in cgroup A is
enlarged after the task moves to sibling B, A is charged but deferred
handling can target B. A's memory.max remains enforced; handling A's
memory.high excess is not guaranteed by this path. The interface documents
this best-effort behavior rather than providing owner-aware pressure
handling on the stated base.

Shakeel Butt's queued memory.high enforcement series [4] changes this
behavior: remote charges schedule reclaim against the charged hierarchy
through high_work. It does not guarantee throttling of the configuring
task, and a fast charger can outrun that worker. That work is not included
in this nf-next base or attributed to this series. Its interaction with
reservations is assessed separately from the base tests.

I am posting this as RFC particularly for feedback on:

1. Whether packet depth and byte allowance should be independently
   configurable, and what default should apply to existing applications
   that only set NFQA_CFG_QUEUE_MAXLEN. Is the proposed 2 KiB head policy
   acceptable given its full-page-buffer and FAIL_OPEN consequences?

2. Whether configured capacity should consume ordinary memcg usage, or
   whether retained bytes should be charged at admission instead. Are the
   BIND-time owner and initial-network-namespace exception appropriate?

3. Whether the proposed bulk reservation interface is an appropriate MM
   interface for this use, including the explicit restriction of charged
   growth to 64-bit kernels. Is this compatibility tradeoff acceptable for
   the initial interface?

4. Whether non-reclaiming reservation growth is the desired failure policy.

5. Whether the queued MM work's best-effort background reclaim is
   sufficient for saved-owner capacity reservations, or stronger pressure
   semantics are needed. On the stated base, the existing owner mismatch
   described above remains.

The patched kernel passed three KUnit suites and the cgroup-enabled network
selftest in an x86-64 guest with two CPUs online, KASAN, and lockdep.
Coverage includes deferred-high saturation and delay arithmetic, creation
publication ordering, separate and bundled activation, refused activation,
retained accounting after COPY_NONE, actual root-counter refunds,
page-backed skbs, payload replacement, and bounded concurrent resizing,
verdicts, teardown, refunds, and queue reuse. The applicable KUnit cases
also passed on x86-32, with two charged-growth cases skipped as expected.
The delay tests exercise the production helpers; they do not reproduce the
complete reclaim-and-throttle path.

A separate probe requiring owner-aware memory.high handling failed: after
the task moved from the owner to its original/root cgroup, growth still
charged the owner but produced no new owner high events. This reproduces
the limitation described above, without establishing a bypass of
memory.max.

In a separate compatibility checkout with Shakeel's queued changes, that
probe observed an owner high event after migration. The growth operation
still returned promptly, consistent with background reclaim rather than
configuring-task throttling. That checkout also incorporates Pablo Neira
Ayuso's pending NFQUEUE reinjection series, with saved-charge releases
adapted to its terminal paths. Its KUnit and network tests passed. These
results concern the dependency integration, not the stated nf-next base.

Receive-driver/GRO behavior and throughput effects have not been evaluated.
Feedback is particularly requested on the allowance policy and reservation
interface, including the full-page-buffer, architecture-support, and
saved-owner memory.high behavior described above.

AI coding tools assisted with investigation, implementation, test
development, review, and drafting this RFC. I take responsibility for the
submitted changes and their technical justification.

[1] https://lists.openwall.net/netdev/2026/11/06/366
[2] https://lore.kernel.org/20261029073857.974-1-zhangjiao2@cmss.chinamobile.com/
[3] https://lore.kernel.org/20260818012115.65838-1-husong@kylinos.cn/
[4] https://lore.kernel.org/20261030205418.341214-1-shakeel.butt@linux.dev/

---
Alireza Asgari (9):
      memcg: saturate deferred memory.high page debt
      memcg: bound memory.high delay arithmetic
      memcg: add KUnit coverage for memory.high accounting
      memcg: add an owner-bound capacity reservation interface
      memcg: test capacity reservation rollback and refunds
      netfilter: nfqueue: account saved skb bytes per queue
      netfilter: nfqueue: reserve capacity against the bound owner
      netfilter: nfqueue: add KUnit memory accounting coverage
      selftests: netfilter: exercise nfqueue memory accounting

 include/linux/memcontrol.h                         |  35 ++
 include/net/netfilter/nf_queue.h                   |   1 +
 mm/Kconfig                                         |  21 +
 mm/memcontrol.c                                    | 216 +++++++++-
 mm/memcontrol_high_test.c                          | 162 ++++++++
 mm/memcontrol_reservation_test.c                   | 232 +++++++++++
 net/netfilter/Kconfig                              |  10 +
 net/netfilter/nfnetlink_queue.c                    | 281 +++++++++----
 net/netfilter/nfnetlink_queue_test.c               | 338 +++++++++++++++
 tools/testing/selftests/net/netfilter/Makefile     |   1 +
 .../selftests/net/netfilter/nft_queue_memory.py    | 460 +++++++++++++++++++++
 11 files changed, 1677 insertions(+), 80 deletions(-)
---
base-commit: 4810f60b9f0e9111cd0dcbfd2ca7a7c591a57464
change-id: 20261115-b4-nfqueue-memory-accounting-263e081fed39

Best regards,
--  
Alireza Asgari <alireza@asgari.net>

