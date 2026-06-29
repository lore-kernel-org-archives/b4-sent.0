From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 29 Jun 2026 14:22:37 +0200
Subject: [PATCH RFC] net: enforce net sysctl registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-jag-net_const_qualify-v1-1-ee98b8fc400c@kernel.org>
X-B4-Tracking: v=1; b=H4sIAIxjQmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMyNL3azEdN281JL45Py84pL4wtLEnMy0St00k1QDS3NTy5TEZHMloN6
 CotS0zAqwudFKQW7OSrG1tQB8gdeybAAAAA==
X-Change-ID: 20260629-jag-net_const_qualify-f4e09759dac7
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5809;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=NRsIqaSK8RGdLBJ8Ckf0Kn2nMXzwb4lcPbZPtnn3QzY=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGpCY5Xd/ZIBb4vTp6l/2LgZY8FutPxzZnJPA
 6paIKtitGoPGIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqQmOVAAoJELqXzVK3
 lkFPq78L/RDjA79itce9JApL7QDETxLSdsyuB9Wr0pqBofIf3LRBEKsHGo1IVK1FJrAVsabDFrS
 OfTKZ4PQLJ7MFs1EzIzCEBYDo80+B0czmPLEdh86Ch0Bs1RaMxcpsxL1qoqDybomzqEM/ps/L4R
 xyJ/t0nPKiuzZ9S5SrvW3NEnosJCC2KiMKtB6ANP9m/jYU1w9QcIkUwJXeQct4w/nXByRKNbRlZ
 nV04/p/K4H6zv0dFLVkZla3jiJPifSGIKoiumKgygwbTmeREam/h80jYMizFRtktZEvR/nbmJeb
 eO3N6KiXpSvCVwWCPvvn7pmG64eTEEjBOYOply5q3g484HOvj1sKTvJKQO0JGJZRroptdNkwWHg
 ccOKFAaM5UNcsYkBN1L0ZJcgFnu/6+zrrJ3KcIiRcMcoOazBiRKsBwLA0qmMWMVxJ0HTXlc7uLb
 jkXb+iRYEUQ8eq6/QMKChKCgMEX3dh+FtCkqdPx4b59V3XG+EV0fchk9/P6FGX16+NMhXQqeQP6
 PU=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the warning and file permission change with an error when an
"unsafe" net sysctl registration is detected.

One of the barriers preventing the const qualification of the ctl_tables
in the net directory is the permission (->mode) change in
ensure_safe_net_sysctl. This prep commit removes that barrier allowing
the const qualification of net ctl_tables.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
What?
=====
Replace warning and file permission change with an error (reject
registration) when an "unsafe" net sysctl registration is detected.

Why?
====
The main motivation for this is to continue with the const qualification
of the ctl_table arrays [1]. The permission change inside
ensure_safe_net_sysctl disallows cons qualifiaction as it basically
modifies the entries before running the sysctl registration.

      ent->mode &= ~0222;

Analysis
========
* I believe that there is currently now way that the permission change
  gets executed [2]
* I found one case where the warning message was posted to lore
  (vsock_sysctl_register) [3], but it made its to mainline as part of
  the second case in [2].
* We should error anyway because writing to the global sysctl value
  through a child netns is indicative of a bug [4].

RFC
===
I'm sending it out as an RFC as I would like to discuss the change to
ensure_safe_net_sysctl in isolation, but my idea is to send out a series
that actually const qualifies the clt_tables in the net directory. I
would be very thankful if you point me to anything that I have missed in
my analysis that shows that this cannot/shouldn't be done.

Best

[1]
  https://git.kernel.org/pub/scm/linux/kernel/git/sysctl/sysctl.git/commit/?h=constfy-sysctl-6.14-rc1&id=1751f872cc97f992ed5c4c72c55588db1f0021e1

[2]
  I have identified 4 contexts relevant to the ensure_safe_net_sysctl call
  inside the network sysctl registration.

  1. When the (struct net) == &init_net (like in iw_cm_init): In this case
     ensure_safe_net_sysctl is not executed and permission modification
     never happens.

  2. When the ctl_table data (->data) gets "manually" assigned to
     something other init_net (like in vsock_sysctl_register): In this
     case ensure_safe_net_sysctl *is* executed but the data that is passed
     is neither a module address (!is_module_address) nor a kernel core
     address (!is_kernel_core_data); so the permission modification never
     happens.

  3. When the permissions are explicitly changed on a kmemdup'ed ctl_table
     array (like in sysctl_core_net_init): in this case
     ensure_safe_net_sysctl *is* executed but the permission modification
     never happens as the mode is not writable.

  4. When ctl have custom proc_handlers (like in nf_lwtunnel_net_init): In
     this case ->data is NULL so it is not a module address
     (!is_module_address) nor a kernel core address
     (!is_kernel_core_data), so permission modification never happens.

  It seems like there is no way of executing the permission change in
  ensure_safe_net_sysctl. Please correct me if this is inacurate and help
  me find the case that I missed.

[3]
  https://lore.kernel.org/all/20260302194926.90378-1-graf@amazon.com/

[4]
  The ensure_safe_net_sysctl function was introduced in Commit:
  31c4d2f160eb7b17cbead24dc6efed06505a3fee ("net: Ensure net namespace
  isolation of sysctls") which states that it is trying to prevent a
  leak (indicative of a bug).
---
 net/sysctl_net.c | 22 +++++++++++-----------
 1 file changed, 11 insertions(+), 11 deletions(-)

diff --git a/net/sysctl_net.c b/net/sysctl_net.c
index 19e8048241bacb18de853d3b904d0f97fd2fe78a..c1630a266f8436d8962ceb87dc629964b2d71260 100644
--- a/net/sysctl_net.c
+++ b/net/sysctl_net.c
@@ -114,16 +114,16 @@ __init int net_sysctl_init(void)
 	goto out;
 }
 
-/* Verify that sysctls for non-init netns are safe by either:
+/* Return error when sysctls for non-init netns are unsafe by verifying:
  * 1) being read-only, or
  * 2) having a data pointer which points outside of the global kernel/module
  *    data segment, and rather into the heap where a per-net object was
  *    allocated.
  */
-static void ensure_safe_net_sysctl(struct net *net, const char *path,
-				   struct ctl_table *table, size_t table_size)
+static int ensure_safe_net_sysctl(struct net *net, const char *path,
+				  const struct ctl_table *table, size_t table_size)
 {
-	struct ctl_table *ent;
+	const struct ctl_table *ent;
 
 	pr_debug("Registering net sysctl (net %p): %s\n", net, path);
 	ent = table;
@@ -149,15 +149,14 @@ static void ensure_safe_net_sysctl(struct net *net, const char *path,
 		else
 			continue;
 
-		/* If it is writable and points to kernel/module global
-		 * data, then it's probably a netns leak.
-		 */
+		/* Warn on netns leak. */
 		WARN(1, "sysctl %s/%s: data points to %s global data: %ps\n",
-		     path, ent->procname, where, ent->data);
+			path, ent->procname, where, ent->data);
 
-		/* Make it "safe" by dropping writable perms */
-		ent->mode &= ~0222;
+		return -EACCES;
 	}
+
+	return 0;
 }
 
 struct ctl_table_header *register_net_sysctl_sz(struct net *net,
@@ -166,7 +165,8 @@ struct ctl_table_header *register_net_sysctl_sz(struct net *net,
 						size_t table_size)
 {
 	if (!net_eq(net, &init_net))
-		ensure_safe_net_sysctl(net, path, table, table_size);
+		if (ensure_safe_net_sysctl(net, path, table, table_size))
+			return NULL;
 
 	return __register_sysctl_table(&net->sysctls, path, table, table_size);
 }

---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260629-jag-net_const_qualify-f4e09759dac7

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

