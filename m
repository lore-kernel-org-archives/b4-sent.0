From: Joel Granados <j.granados@samsung.com>
Date: Tue, 04 Jun 2024 08:29:19 +0200
Subject: [PATCH 1/8] locking: Remove superfluous sentinel element from
 kern_lockdep_table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240604-jag-sysctl_remset-v1-1-2df7ecdba0bd@samsung.com>
References: <20240604-jag-sysctl_remset-v1-0-2df7ecdba0bd@samsung.com>
In-Reply-To: <20240604-jag-sysctl_remset-v1-0-2df7ecdba0bd@samsung.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Will Deacon <will@kernel.org>, Waiman Long <longman@redhat.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Suren Baghdasaryan <surenb@google.com>, 
 Kent Overstreet <kent.overstreet@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Luis Chamberlain <mcgrof@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Joel Granados <j.granados@samsung.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 linux-fsdevel@vger.kernel.org, netdev@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=860; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=14739GNIvIP1jcOFEalMBBReb5ieHSFF2clMwb/AQoM=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZetGJabxTBGOF4nHQDP1wm5ErY55X5yT1ko
 moGhHsQTVtxBIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmXrRiAAoJELqXzVK3
 lkFPreYMAIXr/sxZeeYa1hpzMSQR+LDo1okDOTVaAB6RI94p35Ph0NodstJFVE8/a/F7z8yznfT
 zRGB5mwTfERvnAHoLRa4cRPV7deYGX2Lfl4gRBxx38VVMXVNXGHuX412vQ/HGw8IG9A/McpDk0u
 Z2K9H7mdffgtNOrik+M5doL2wo8aIl3n/ntCbrFS6KMi5BjMA6JTGcCKPQc09MMFN8iWCyUlpHv
 PO0MOmlqI+ydfIGKM3grwe0ygIghPE7rXbC+RmQ/CFoPVTtuysPBixbT389HdPi2kwZfc3yMdiG
 JqIDpGDgEfx6eBoHqPi9f6UjsZsRZ8uQjA3cPhNf2r57I/Ous7iFkFzWnm9lsT7juRvP2yBLdve
 Fsb5u3LI21rJQdi9hKHm+Qy0a7lF7daS5ISDeA9YiPhRmI4qFElN50yOxuLkzeWdOmUek/m7eVe
 mIrjNatEmaWnNaLmtaw3exq+Eoi54Rdh5QCBMA0GRO+dVR2JtZ85j6nhTdGkijeKFOoJQ/Vz+O5
 Xc=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit is part of a greater effort to remove all
empty elements at the end of the ctl_table arrays (sentinels) which will
reduce the overall build time size of the kernel and run time memory
bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 kernel/locking/lockdep.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/kernel/locking/lockdep.c b/kernel/locking/lockdep.c
index 151bd3de5936..726b22ce7d0b 100644
--- a/kernel/locking/lockdep.c
+++ b/kernel/locking/lockdep.c
@@ -97,7 +97,6 @@ static struct ctl_table kern_lockdep_table[] = {
 		.proc_handler   = proc_dointvec,
 	},
 #endif /* CONFIG_LOCK_STAT */
-	{ }
 };
 
 static __init int kernel_lockdep_sysctls_init(void)

-- 
2.43.0

