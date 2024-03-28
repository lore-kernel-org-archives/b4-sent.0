From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Mar 2024 16:57:48 +0100
Subject: [PATCH 1/7] memory: Remove the now superfluous sentinel element
 from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-jag-sysctl_remset_misc-v1-1-47c1463b3af2@samsung.com>
References: <20240328-jag-sysctl_remset_misc-v1-0-47c1463b3af2@samsung.com>
In-Reply-To: <20240328-jag-sysctl_remset_misc-v1-0-47c1463b3af2@samsung.com>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Muchun Song <muchun.song@linux.dev>, Miaohe Lin <linmiaohe@huawei.com>, 
 Naoya Horiguchi <naoya.horiguchi@nec.com>, 
 John Johansen <john.johansen@canonical.com>, 
 Paul Moore <paul@paul-moore.com>, James Morris <jmorris@namei.org>, 
 "Serge E. Hallyn" <serge@hallyn.com>, David Howells <dhowells@redhat.com>, 
 Jarkko Sakkinen <jarkko@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Jens Axboe <axboe@kernel.dk>, 
 Pavel Begunkov <asml.silence@gmail.com>, 
 Atish Patra <atishp@atishpatra.org>, Anup Patel <anup@brainfault.org>, 
 Will Deacon <will@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>
Cc: Luis Chamberlain <mcgrof@kernel.org>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 apparmor@lists.ubuntu.com, linux-security-module@vger.kernel.org, 
 keyrings@vger.kernel.org, linux-crypto@vger.kernel.org, 
 io-uring@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13-dev-2d940
X-Developer-Signature: v=1; a=openpgp-sha256; l=2947;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=G0BkbiS24qk3nYu5g34TDOv3csGuh2kZPaxeW+vD810=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGYFk8Nm85JUJMtVWCP7cQK3ztzb05qjvvmwk
 T3kPJF8vCCcyIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmBZPDAAoJELqXzVK3
 lkFPIpAL/1y2jHL0ldqx4fqCXGpuZzDqhJXCnpqihvZ32zsopWjrhi+p1ISWuGKdyIdGynRC+IV
 Je1APUKFuRDQVYxqM1OOjB5c5leSJAk/qPnLrVpVFMjq8BMGhuRvS3XCyTX6SzTiUUgoo0506Vz
 NdxhHpuidbjm1IXWicjzuhMbT+HeIsrG+Z/QyfDJBkzjhL5RfFK25EwE2GpcGp+W2NVEfWlgyfW
 Yhe6qx9yVJxD7gCRqTl4VBDmd8HgbLq2WAJmj/DanH2NusT804q+smteFEkRg3A8W6U1pdDlN6O
 f9WMoD8mGt09rh6Mn3JluYzMrRNYJYBueiePbq3oSBcYIQB8DEDuMNfJfUbRD3hBPJAI8OTijXf
 VC2kNdiWFsnrM7+rG3oIYSGgqNY5X5fbdcKv1xIifBGJmPD1hXxWTiGxTUgsESjz6+xH0At+0cJ
 6Sxi6LMR4IMPjL9/EqLkXXjve+OYcbYo8A5uawCVRLr05E3l9IGfbpljEMx9fFQ7ew36yoKuYo7
 AQ=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which will
reduce the overall build time size of the kernel and run time memory
bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from all files under mm/ that register a sysctl table.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 mm/compaction.c      | 1 -
 mm/hugetlb.c         | 1 -
 mm/hugetlb_vmemmap.c | 1 -
 mm/memory-failure.c  | 1 -
 mm/oom_kill.c        | 1 -
 mm/page-writeback.c  | 1 -
 mm/page_alloc.c      | 1 -
 7 files changed, 7 deletions(-)

diff --git a/mm/compaction.c b/mm/compaction.c
index 807b58e6eb68..e8a047afca22 100644
--- a/mm/compaction.c
+++ b/mm/compaction.c
@@ -3345,7 +3345,6 @@ static struct ctl_table vm_compaction[] = {
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
 	},
-	{ }
 };
 
 static int __init kcompactd_init(void)
diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 23ef240ba48a..7ac5240a197d 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -5045,7 +5045,6 @@ static struct ctl_table hugetlb_table[] = {
 		.mode		= 0644,
 		.proc_handler	= hugetlb_overcommit_handler,
 	},
-	{ }
 };
 
 static void hugetlb_sysctl_init(void)
diff --git a/mm/hugetlb_vmemmap.c b/mm/hugetlb_vmemmap.c
index da177e49d956..b9a55322e52c 100644
--- a/mm/hugetlb_vmemmap.c
+++ b/mm/hugetlb_vmemmap.c
@@ -679,7 +679,6 @@ static struct ctl_table hugetlb_vmemmap_sysctls[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_dobool,
 	},
-	{ }
 };
 
 static int __init hugetlb_vmemmap_init(void)
diff --git a/mm/memory-failure.c b/mm/memory-failure.c
index 9349948f1abf..6a112f9ecf91 100644
--- a/mm/memory-failure.c
+++ b/mm/memory-failure.c
@@ -141,7 +141,6 @@ static struct ctl_table memory_failure_table[] = {
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
 	},
-	{ }
 };
 
 /*
diff --git a/mm/oom_kill.c b/mm/oom_kill.c
index 8d6a207c3c59..4d7a0004df2c 100644
--- a/mm/oom_kill.c
+++ b/mm/oom_kill.c
@@ -724,7 +724,6 @@ static struct ctl_table vm_oom_kill_table[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_dointvec,
 	},
-	{}
 };
 #endif
 
diff --git a/mm/page-writeback.c b/mm/page-writeback.c
index 3e19b87049db..fba324e1a010 100644
--- a/mm/page-writeback.c
+++ b/mm/page-writeback.c
@@ -2291,7 +2291,6 @@ static struct ctl_table vm_page_writeback_sysctls[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_dointvec_jiffies,
 	},
-	{}
 };
 #endif
 
diff --git a/mm/page_alloc.c b/mm/page_alloc.c
index 14d39f34d336..8b9820620fe3 100644
--- a/mm/page_alloc.c
+++ b/mm/page_alloc.c
@@ -6211,7 +6211,6 @@ static struct ctl_table page_alloc_sysctl_table[] = {
 		.extra2		= SYSCTL_ONE_HUNDRED,
 	},
 #endif
-	{}
 };
 
 void __init page_alloc_sysctl_init(void)

-- 
2.43.0

