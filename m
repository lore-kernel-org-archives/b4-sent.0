From: Mani Tofigh <mt4022@columbia.edu>
Subject: [PATCH bpf v2 0/4] bpf: Don't spin on rhtab bucket locks with IRQs
 disabled
Date: Sun, 22 Nov 2026 19:25:11 -0500
Message-Id: <20261122-bpf-rhtab-irqs-disabled-v2-0-207aedcc2215@columbia.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNTQ6CMBCFr0Jm7Zi2kgquvIdh0Z9BxiBgC0RDu
 LsFD+DyvXzvewtECkwRLtkCgWaO3HcpqEMGrjHdnZB9yqCE0lKKE9qhxtCMxiKHV0TP0diWPLp
 c59qVJGpSkNZDoJrfu/kGaQTVr4yTfZAbN+eGNRzHPnz2/1nu8N+rWaLEsjjnvtRGFIW7ur6dn
 pbNkfwE1bquX8j9x9XYAAAA
X-Change-ID: 20261103-bpf-rhtab-irqs-disabled-c4646c9e0fe2
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Mykyta Yatsenko <yatsenko@meta.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 Andrew Morton <akpm@linux-foundation.org>, Shuah Khan <shuah@kernel.org>
Cc: Thomas Graf <tgraf@suug.ch>, Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, bpf@vger.kernel.org, 
 linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795393512; l=1885;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=Cdk7sFLE8Ms1z4MWODP6tHICAcN6MvIKq/Q+cx9TxjA=;
 b=QyYqJhTCgCxEks59roKvMT4SIBstHsjhnIxEryfr9INyqeC5lbUDBSQ6oPuQ4tjfrpB4lRR+z
 oVc1iV/TsnpBD7LzTsVaP0lWipwJWgMeQj752iWKnKn9mJvarl6D5mf
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A BPF program with IRQs disabled can run inside a bucket lock's critical
section on its own CPU, e.g., a kprobe on the hash function the resize
worker calls with the lock held.  An insert or delete of that bucket
then spins forever, and a lookup can retry forever.

v2 follows Alexei's trylock design (patch 1) and Mykyta's lookup change
(patch 2), turns it on for rhtab (patch 3) and adds a selftest (patch
4).  The kvmalloc(GFP_ATOMIC) in rhashtable_insert_rehash() is left for
a follow-up.

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/rhashlock.c

---
Changes in v2:
- Trylock the bucket lock with IRQs disabled instead of failing every
  insert and delete (Alexei)
- Drop bpf_disable_instrumentation() from rhtab (Alexei)
- Don't retry lookups with IRQs disabled (Mykyta)
- Add a selftest
- Link to v1: https://patch.msgid.link/20261103-bpf-rhtab-irqs-disabled-v1-1-9874d96a088c@columbia.edu

---
Mani Tofigh (4):
      rhashtable: Add trylock_irqsoff for callers that can't spin
      rhashtable: Don't retry trylock_irqsoff lookups with IRQs disabled
      bpf: Don't spin on rhtab bucket locks with IRQs disabled
      selftests/bpf: Test rhtab deletes from inside a resize

 include/linux/rhashtable-types.h                 |  3 ++
 include/linux/rhashtable.h                       | 45 ++++++++++++++++++++++--
 kernel/bpf/hashtab.c                             | 17 ++-------
 lib/rhashtable.c                                 |  9 +++--
 tools/testing/selftests/bpf/prog_tests/rhash.c   | 34 ++++++++++++++++++
 tools/testing/selftests/bpf/progs/rhash_resize.c | 34 ++++++++++++++++++
 6 files changed, 122 insertions(+), 20 deletions(-)
---
base-commit: 84afebd853437e44cb71f718be11d90e4c1a59dd
change-id: 20261103-bpf-rhtab-irqs-disabled-c4646c9e0fe2

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

