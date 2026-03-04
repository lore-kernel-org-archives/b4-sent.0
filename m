From: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
Date: Wed, 04 Mar 2026 08:27:38 +0100
Subject: [PATCH] mm/vmstat: reject zero vm.stat_interval to prevent
 busy-loop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260304-mm-vmstat-reject-zero-vm-stat_interval-to-prevent-busy-loop-v1-1-c03c9555ff15@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2N0QrCMAxFf2Xk2cCs3QR/RUSyGTWytqONRR37d
 6OP53C5Z4HCWbjAoVkgc5UiKRpsNw2Md4o3RrkYg2td3+5ajyFgDUVJMfODR8UP52QKf+4sUTl
 XmlATzvbHUXF4ljdOKc04UOd9T53bE4EVbHGV179+PK3rF2FrJJaNAAAA
X-Change-ID: 20260304-mm-vmstat-reject-zero-vm-stat_interval-to-prevent-busy-loop-ba5446a527aa
To: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Terry M <terrym3201@bugzilla.kernel.org>, 
 Maximilian Pezzullo <maximilianpezzullo@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772609289; l=1836;
 i=maximilianpezzullo@gmail.com; s=20260303; h=from:subject:message-id;
 bh=qPVkk+RjNot6d1aWiuzGeSKqQMeQqa4dNJWr0ISRIT8=;
 b=8fIpGxrHPIjYGDUNowEueBvSdu3/qSDNnV63gL4/GDUISpQasaYU5bPCTo9KPkXdNirrDWSy9
 6SqTQxrYgilAzGICa/sFavlePMaT9YGB/y/IPJL6frSt1jLWjtDo1ar
X-Developer-Key: i=maximilianpezzullo@gmail.com; a=ed25519;
 pk=TRTR4c2Vb1IfluQvv5OUDPg7EE+pIzdPBND85UU559w=
X-Endpoint-Received: by B4 Relay for maximilianpezzullo@gmail.com/20260303 with auth_id=658
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Setting vm.stat_interval to 0 causes excessive kworker CPU usage
because vmstat_shepherd() and vmstat_update() reschedule themselves
with round_jiffies_relative(0), which resolves to an immediate
reschedule and creates a busy-loop.

Add a custom sysctl handler that rejects 0 and restores the previous
value, similar to how dirtytime_interval_handler() handles
vm.dirtytime_expire_seconds.

Reported-by: Terry M <terrym3201@bugzilla.kernel.org>
Closes: https://bugzilla.kernel.org/show_bug.cgi?id=220226
Signed-off-by: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
---
 mm/vmstat.c | 14 +++++++++++++-
 1 file changed, 13 insertions(+), 1 deletion(-)

diff --git a/mm/vmstat.c b/mm/vmstat.c
index 86b14b0f77b5..6eeb4341b215 100644
--- a/mm/vmstat.c
+++ b/mm/vmstat.c
@@ -2114,6 +2114,18 @@ void vmstat_flush_workqueue(void)
 	flush_workqueue(mm_percpu_wq);
 }
 
+static int vmstat_interval_handler(const struct ctl_table *table, int write,
+				    void *buffer, size_t *lenp, loff_t *ppos)
+{
+	int ret = proc_dointvec_jiffies(table, write, buffer, lenp, ppos);
+
+	if (ret == 0 && write && sysctl_stat_interval == 0) {
+		sysctl_stat_interval = HZ;
+		return -EINVAL;
+	}
+	return ret;
+}
+
 static void vmstat_shepherd(struct work_struct *w)
 {
 	int cpu;
@@ -2236,7 +2248,7 @@ static const struct ctl_table vmstat_table[] = {
 		.data		= &sysctl_stat_interval,
 		.maxlen		= sizeof(sysctl_stat_interval),
 		.mode		= 0644,
-		.proc_handler	= proc_dointvec_jiffies,
+		.proc_handler	= vmstat_interval_handler,
 	},
 	{
 		.procname	= "stat_refresh",

---
base-commit: af4e9ef3d78420feb8fe58cd9a1ab80c501b3c08
change-id: 20260304-mm-vmstat-reject-zero-vm-stat_interval-to-prevent-busy-loop-ba5446a527aa

Best regards,
-- 
Maximilian Pezzullo <maximilianpezzullo@gmail.com>

