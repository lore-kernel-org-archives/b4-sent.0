From: Alireza Asgari <alireza@asgari.net>
Subject: [PATCH RFC net 0/3] netfilter: nfnetlink_queue: handle packet ID
 reuse and large gaps
Date: Fri, 06 Nov 2026 00:37:03 +0000
Message-Id: <20261106-nfqueue-review-v1-0-b6c933f44943@asgari.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAC8h7WoC/yWMvQrCMBSFX6Xc2WAStIibFMRRxE0ckvbERvCqS
 aNC6bub6HT4zt9IEcEj0roaKeDlo79zBjWrqO0NXyB8l5m01LVSshbsngkJopTxFmq1kFhqGNd
 ZyqNHgPOf3+GJ9ptjsyvuYdsUYQx0/pdisle0Q7kuiTURwgbDbV8sdvOb8UzT9AUz8xZioQAAA
 A==
X-Change-ID: 20261106-nfqueue-review-1840e52eafdb
To: Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>
Cc: Phil Sutter <phil@nwl.cc>, netfilter-devel@vger.kernel.org, 
 netdev@vger.kernel.org, kunit-dev@googlegroups.com, 
 Alireza Asgari <alireza@asgari.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793925516; l=4056;
 i=alireza@asgari.net; s=nfqueue-20261106-d5b860a0; h=from:subject:message-id;
 bh=tuCkgFrwK5f7smUTKpW5TAvqKyfXSKAYkonELYpnhDw=;
 b=wBYL/NIh5Us2wzgUM7gomOy1wCItO0ebDh6oLGZUDtQsHLvS8QOpdBRYWg16BQwIudtD1SA2f
 1qREgCu1rmZBdXOp+P7aKVie8N+YHCEDrXmVUuEEjlUa6tLrchyYTtX
X-Developer-Key: i=alireza@asgari.net; a=ed25519;
 pk=zQFqyM4zwBHzads8dtEOnNQiQQ1pktgndpKPB3TI+AE=
X-Endpoint-Received: by B4 Relay for alireza@asgari.net/nfqueue-20261106-d5b860a0 with auth_id=1424
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series addresses packet-ID reuse and batch-verdict ordering in
NFQUEUE. I am posting it as an RFC to discuss the handling of ambiguous
batch boundaries and the additional sequence state used to resolve them.

An old packet can remain queued while newer packets receive individual
verdicts. Queue length therefore does not bound the distance between
pending packet IDs. After a complete 32-bit ID cycle, two pending packets
can have the same ID, making verdict lookup ambiguous. Even before reuse,
the signed 32-bit comparison in the batch handler can select the wrong
FIFO prefix when IDs are separated by half an ID cycle or more.

For example, with pending IDs [1, 0x80000002], a batch verdict through 1
currently selects both packets instead of only the first. If the queue
contains [1, 2, 0x80000003], removing 2 individually and then batching
through 2 also selects both remaining packets instead of only 1. These
cases are covered by synthetic KUnit tests that seed the sequence values
directly.

Patch 1 rejects an incoming duplicate ID before list insertion or userspace
notification, preserving the existing pending packet. The incoming packet
follows the existing enqueue-failure policy: drop by default, or accept
with FAIL_OPEN.

Patch 2 uses an exact queued boundary to select the FIFO prefix. For a
boundary no longer queued, it uses a 64-bit queue sequence and a per-entry
32-bit epoch to recover issuance order. Ambiguous missing boundaries
return -ERANGE without changing the queue. The wire format is unchanged,
but the rejection behavior is userspace-visible. This does not distinguish
stale verdicts after an ID has been released and reused.

Patch 3 adds 45 KUnit cases covering ordering, wraparound, missing
boundaries, collisions and the actual enqueue path. Each case uses a
private network namespace.

I would appreciate feedback on:

  - Whether -ERANGE with the queue unchanged is the appropriate response
    for an ambiguous missing batch boundary.
  - Whether the per-entry epoch and widened queue counter are appropriate
    for handling boundaries that have already been removed.
  - Whether the existing drop/FAIL_OPEN policy is the preferred way to
    handle an incoming packet whose ID is still pending.

Validation:

  - Focused UML KUnit run: 45 cases passed with GCC 13.3 and W=1.
  - Kconfig dependency checks with NFQUEUE built in: tests enabled with
    KUNIT=y and NET_NS=y, and disabled with KUNIT=m or NET_NS=n.
  - Full x86-64 allmodconfig with GCC 13.3 and allyesconfig with Clang
    18.1.3: both passed with W=1 and CONFIG_WERROR=n.
  - Separate GCC builds of NFQUEUE and all eight other direct users of
    nf_queue.h passed in both configurations with W=1 and
    CONFIG_WERROR=y, without compiler diagnostics.

The full builds disabled WERROR after unrelated failures were reproduced
on the unpatched base. GCC allyesconfig also encountered an unrelated
MCTP KUnit static assertion failure on that base; the full allyesconfig
build therefore used Clang. Runtime coverage is the focused KUnit suite;
no throughput or latency measurements are included.

Codex assisted with developing and reviewing this series, fixing the
KUnit dependencies and namespace isolation, running validation, and
preparing the submission text.

---
Alireza Asgari (3):
      netfilter: nfnetlink_queue: reject duplicate pending packet IDs
      netfilter: nfnetlink_queue: fix batch verdict ordering across large ID gaps
      netfilter: nfnetlink_queue: test packet ID ordering and collisions

 include/net/netfilter/nf_queue.h         |   1 +
 net/netfilter/Kconfig                    |  12 +
 net/netfilter/nfnetlink_queue.c          |  78 ++-
 net/netfilter/nfnetlink_queue_gap_test.c | 906 +++++++++++++++++++++++++++++++
 4 files changed, 988 insertions(+), 9 deletions(-)
---
base-commit: 734bef548a96e8774d6eef5dfa2026c6edc4e80b
change-id: 20261106-nfqueue-review-1840e52eafdb

Best regards,
--  
Alireza Asgari <alireza@asgari.net>

