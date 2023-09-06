From: Joel Granados <j.granados@samsung.com>
Date: Wed, 06 Sep 2023 12:03:22 +0200
Subject: [PATCH 1/8] S390: Remove sentinel elem from ctl_table arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230906-jag-sysctl_remove_empty_elem_arch-v1-1-3935d4854248@samsung.com>
References: <20230906-jag-sysctl_remove_empty_elem_arch-v1-0-3935d4854248@samsung.com>
In-Reply-To: <20230906-jag-sysctl_remove_empty_elem_arch-v1-0-3935d4854248@samsung.com>
To: Luis Chamberlain <mcgrof@kernel.org>, willy@infradead.org, 
 josh@joshtriplett.org, Kees Cook <keescook@chromium.org>, 
 Iurii Zaikin <yzaikin@google.com>, Heiko Carstens <hca@linux.ibm.com>, 
 Vasily Gorbik <gor@linux.ibm.com>, 
 Alexander Gordeev <agordeev@linux.ibm.com>, 
 Christian Borntraeger <borntraeger@linux.ibm.com>, 
 Sven Schnelle <svens@linux.ibm.com>, 
 Gerald Schaefer <gerald.schaefer@linux.ibm.com>, 
 Russell King <linux@armlinux.org.uk>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Mark Rutland <mark.rutland@arm.com>, Thomas Gleixner <tglx@linutronix.de>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Andy Lutomirski <luto@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, Guo Ren <guoren@kernel.org>
Cc: linux-fsdevel@vger.kernel.org, linux-s390@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-riscv@lists.infradead.org, linuxppc-dev@lists.ozlabs.org, 
 linux-ia64@vger.kernel.org, linux-csky@vger.kernel.org, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13-dev-86aa5
X-Developer-Signature: v=1; a=openpgp-sha256; l=3312;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=2H2WzHl1n5TkpobrfRC4Stm2MJ3A7MviIWn7mV1kLj0=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBk+E6UZcDRrcDgi6XDgHoPgVGiMLF7dg0Lwe1D8
 WrUlTZwO2uJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZPhOlAAKCRC6l81St5ZB
 T7eFDACYd/thv7eog9R+8K3MNNvNcrogNfqCUi3KZYYpEM6mbOExHxEHer5opFU0aar2lKX3P2a
 kuLYmZScpymlZ9mWz/4dlmRQLKFo+UjTlqzIc4W+knLH9s5GNh3SO2Cu+r+8t5ThHTd2mg2wqQK
 BYbEjGISQ7yu+qgZvbUVM6lhaF88gOAQkyZAlwZZVNBxuxrx0PARpCrsOi8JBXgs2/BptD1ynJh
 nKP+HQZam1M11IH4uQHT3BG+coO1Y8VIfX5PBSLl5Dkz6PWyHpli05ZN5h5hnV7dqdxqA2siPha
 Ko8a6YP9YqBZGKiuEhTNWybGdn962FqHpz8s+teStd5gQFGrT8+t83ybZanx2KKzws0zIjyYr01
 ZBrRo32fxR9zwgTehsh0iA0Jb4DUyudUiO5yAk2LiHRJYku03jQmsTcfXgz49cg/ez0vmu1pC0y
 3uChH1l23/cE7jsdYOzUQY39WzC8ImccPHMEX8ya5YrWiGdqsAAPUd8mfAW3g9XNyNJos=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove the sentinel element from appldata_table, s390dbf_table,
topology_ctl_table, cmm_table and page_table_sysctl. Reduced the
memory allocation in appldata_register_ops by 1 effectively removing the
sentinel from ops->ctl_table.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 arch/s390/appldata/appldata_base.c | 6 ++----
 arch/s390/kernel/debug.c           | 3 +--
 arch/s390/kernel/topology.c        | 3 +--
 arch/s390/mm/cmm.c                 | 3 +--
 arch/s390/mm/pgalloc.c             | 3 +--
 5 files changed, 6 insertions(+), 12 deletions(-)

diff --git a/arch/s390/appldata/appldata_base.c b/arch/s390/appldata/appldata_base.c
index 3b0994625652..872a644b1fd1 100644
--- a/arch/s390/appldata/appldata_base.c
+++ b/arch/s390/appldata/appldata_base.c
@@ -62,8 +62,7 @@ static struct ctl_table appldata_table[] = {
 		.procname	= "interval",
 		.mode		= S_IRUGO | S_IWUSR,
 		.proc_handler	= appldata_interval_handler,
-	},
-	{ },
+	}
 };
 
 /*
@@ -351,8 +350,7 @@ int appldata_register_ops(struct appldata_ops *ops)
 	if (ops->size > APPLDATA_MAX_REC_SIZE)
 		return -EINVAL;
 
-	/* The last entry must be an empty one */
-	ops->ctl_table = kcalloc(2, sizeof(struct ctl_table), GFP_KERNEL);
+	ops->ctl_table = kcalloc(1, sizeof(struct ctl_table), GFP_KERNEL);
 	if (!ops->ctl_table)
 		return -ENOMEM;
 
diff --git a/arch/s390/kernel/debug.c b/arch/s390/kernel/debug.c
index a85e0c3e7027..150e2bfff0b3 100644
--- a/arch/s390/kernel/debug.c
+++ b/arch/s390/kernel/debug.c
@@ -977,8 +977,7 @@ static struct ctl_table s390dbf_table[] = {
 		.maxlen		= sizeof(int),
 		.mode		= S_IRUGO | S_IWUSR,
 		.proc_handler	= s390dbf_procactive,
-	},
-	{ }
+	}
 };
 
 static struct ctl_table_header *s390dbf_sysctl_header;
diff --git a/arch/s390/kernel/topology.c b/arch/s390/kernel/topology.c
index 68adf1de8888..9dcfac416669 100644
--- a/arch/s390/kernel/topology.c
+++ b/arch/s390/kernel/topology.c
@@ -635,8 +635,7 @@ static struct ctl_table topology_ctl_table[] = {
 		.procname	= "topology",
 		.mode		= 0644,
 		.proc_handler	= topology_ctl_handler,
-	},
-	{ },
+	}
 };
 
 static int __init topology_init(void)
diff --git a/arch/s390/mm/cmm.c b/arch/s390/mm/cmm.c
index f47515313226..8937aa7090b3 100644
--- a/arch/s390/mm/cmm.c
+++ b/arch/s390/mm/cmm.c
@@ -331,8 +331,7 @@ static struct ctl_table cmm_table[] = {
 		.procname	= "cmm_timeout",
 		.mode		= 0644,
 		.proc_handler	= cmm_timeout_handler,
-	},
-	{ }
+	}
 };
 
 #ifdef CONFIG_CMM_IUCV
diff --git a/arch/s390/mm/pgalloc.c b/arch/s390/mm/pgalloc.c
index 07fc660a24aa..e8cecd31715f 100644
--- a/arch/s390/mm/pgalloc.c
+++ b/arch/s390/mm/pgalloc.c
@@ -29,8 +29,7 @@ static struct ctl_table page_table_sysctl[] = {
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
-	},
-	{ }
+	}
 };
 
 static int __init page_table_register_sysctl(void)

-- 
2.30.2

