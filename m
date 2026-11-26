From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 26 Nov 2026 12:47:49 +0100
Subject: [PATCH RFC 9/9] ucount: Register user_table as a template
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-lklm-sysctl-ctx-flatarray-v1-9-d7fc9cc9b03e@kernel.org>
References: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
In-Reply-To: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexey Gladkov <legion@kernel.org>, 
 David Laight <david.laight.linux@gmail.com>, Wen Yang <wen.yang@linux.dev>
Cc: Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Linus Torvalds <torvalds@linux-foundation.org>, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 netdev@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1852;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=xxV6z++7ScCL89/Zbrnu7BW+bL94aG5P2MD4Ph2vuSk=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGsIHGb4MoAhfzZ1I0S/+EBq8ElFI7wbN0PZ+
 Imexis5rB3Dv4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJrCBxmAAoJELqXzVK3
 lkFPHbcMAIU+j6RI+3mitsigy7GoDEHm1dD/3TlR1oUbw7PCY3S8JrChRnPm4SNvA9aXEsHeP2y
 zwimrDfTY2CJiq29aw3N5lxRVm/nTT66Di5jUpBol57ZSsMKXsGv5cTRGzqeuSLzNAVtgfwJsX0
 I044x1WNml5Pc5C+aaC3Wzcqrd49uw1ub50fPyC0Oq2DhnO56ncCGd2+Bh5hrFfQHBatgX2LwwG
 e0lDhNjYH/1Ey7Cz1inFdzeGW5uXR6qGmXg+nTpGnq5DscCxinI2yATfwG3vU4EL3Nd8zaynH4L
 Dfms9KJtEWkR3uu6BVGOJmGF4/U+Uho8+gyy/YeZogtV/CypF6nMdJqG4UeG6EnG4wVArESfoJa
 +nkXL+PbLC5NKQTQ+ueg/gVDtu32DLcv8F3whKBJTz7AqaPee9PxC4dfVwwSBlCqW3KGos9p5mX
 ENmW1MVCZmCwFH0GYSFhOYf4JqcPAOX1kvR1SwciZ9elw65+Vbjgm7j9rYIIlmDi69ZKeJ54467
 AY=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SYSCTL_OVERLAY_DATA to UCOUNT_ENTRY() so every entry of user_table
carries it, and register the table through
__register_sysctl_table_tmpl(), passing the copy that
setup_userns_sysctls() already fills by position as the overlay. Free
the copy once the call returns and stop freeing ctl_table_arg in
retire_userns_sysctls().

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/ucount.c | 14 ++++++--------
 1 file changed, 6 insertions(+), 8 deletions(-)

diff --git a/kernel/ucount.c b/kernel/ucount.c
index 94b70502dc9ded4de4a946b73141119efc3a26fe..bf021247f5ee5999f3c298e318c25dc2164a8c9b 100644
--- a/kernel/ucount.c
+++ b/kernel/ucount.c
@@ -69,6 +69,7 @@ static long ue_int_max = INT_MAX;
 		.procname	= name,				\
 		.maxlen		= sizeof(long),			\
 		.mode		= 0644,				\
+		.flags		= SYSCTL_OVERLAY_DATA,		\
 		.proc_handler	= proc_doulongvec_minmax,	\
 		.extra1		= &ue_zero,			\
 		.extra2		= &ue_int_max,			\
@@ -109,11 +110,12 @@ bool setup_userns_sysctls(struct user_namespace *ns)
 		for (i = 0; i < UCOUNT_COUNTS; i++) {
 			tbl[i].data = &ns->ucount_max[i];
 		}
-		ns->sysctls = __register_sysctl_table(&ns->set, "user", tbl,
-						      ARRAY_SIZE(user_table));
-	}
-	if (!ns->sysctls) {
+		ns->sysctls = __register_sysctl_table_tmpl(&ns->set, "user",
+							   CTL_TABLE_TMPL(user_table),
+							   tbl, ARRAY_SIZE(user_table));
 		kfree(tbl);
+	}
+	if (!ns->sysctls) {
 		retire_sysctl_set(&ns->set);
 		return false;
 	}
@@ -124,12 +126,8 @@ bool setup_userns_sysctls(struct user_namespace *ns)
 void retire_userns_sysctls(struct user_namespace *ns)
 {
 #ifdef CONFIG_SYSCTL
-	const struct ctl_table *tbl;
-
-	tbl = ns->sysctls->ctl_table_arg;
 	unregister_sysctl_table(ns->sysctls);
 	retire_sysctl_set(&ns->set);
-	kfree(tbl);
 #endif
 }
 

-- 
2.50.1

