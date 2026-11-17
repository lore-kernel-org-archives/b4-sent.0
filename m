From: Mattathias Pinchover <mattathias.pinchover@uber.com>
Date: Tue, 17 Nov 2026 23:22:16 +0000
Subject: [PATCH v2 2/6] mm/damon/sysfs-schemes: add
 sz_ops_filter_passed_last file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-damon-sz-ops-b4-v2-2-439888fa04ac@uber.com>
References: <20261117-damon-sz-ops-b4-v2-0-439888fa04ac@uber.com>
In-Reply-To: <20261117-damon-sz-ops-b4-v2-0-439888fa04ac@uber.com>
To: SJ Park <sj@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: damon@lists.linux.dev, linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Mattathias Pinchover <mattathias.pinchover@uber.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794957787; l=2833;
 i=mattathias.pinchover@uber.com; s=20261113; h=from:subject:message-id;
 bh=u1DV0UDoFEvDL3o7weOFk6krr3N8RcXJkWhDsTcSkS8=;
 b=ub0fqxaKw5XbPxgkwtlZcCSSAhhCeMDHpt+Ei20JZ5Gyd00+YxJp1oD+Btjq9e5umYV/NAQ6p
 kcAFeK4nKn4DVQOxzviNFD7DIYF18kXYmSqXQEBZipJIznYH4z62KJQ
X-Developer-Key: i=mattathias.pinchover@uber.com; a=ed25519;
 pk=6Bh6OEwWiU6dpON0CVcoipq8fXtEgvhsM1Tmm9CTmtY=
X-Endpoint-Received: by B4 Relay for mattathias.pinchover@uber.com/20261113 with auth_id=1515
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a new DAMON sysfs interface file for exposing the newly added
DAMOS stat, sz_ops_filter_passed_last.  The file has the same
name as the stat and is placed under the DAMOS stats directory.  Like
other stats files, it is updated when the stats are refreshed via
refresh_ms or the update_schemes_stats command.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Mattathias Pinchover <mattathias.pinchover@uber.com>
---
 mm/damon/sysfs-schemes.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/mm/damon/sysfs-schemes.c b/mm/damon/sysfs-schemes.c
index 230987efac3a..750f70f0c31b 100644
--- a/mm/damon/sysfs-schemes.c
+++ b/mm/damon/sysfs-schemes.c
@@ -370,6 +370,7 @@ struct damon_sysfs_stats {
 	unsigned long nr_applied;
 	unsigned long sz_applied;
 	unsigned long sz_ops_filter_passed;
+	unsigned long sz_ops_filter_passed_last;
 	unsigned long qt_exceeds;
 	unsigned long nr_snapshots;
 	unsigned long max_nr_snapshots;
@@ -425,6 +426,15 @@ static ssize_t sz_ops_filter_passed_show(struct kobject *kobj,
 	return sysfs_emit(buf, "%lu\n", stats->sz_ops_filter_passed);
 }
 
+static ssize_t sz_ops_filter_passed_last_show(struct kobject *kobj,
+		struct kobj_attribute *attr, char *buf)
+{
+	struct damon_sysfs_stats *stats = container_of(kobj,
+			struct damon_sysfs_stats, kobj);
+
+	return sysfs_emit(buf, "%lu\n", stats->sz_ops_filter_passed_last);
+}
+
 static ssize_t qt_exceeds_show(struct kobject *kobj,
 		struct kobj_attribute *attr, char *buf)
 {
@@ -485,6 +495,9 @@ static struct kobj_attribute damon_sysfs_stats_sz_applied_attr =
 static struct kobj_attribute damon_sysfs_stats_sz_ops_filter_passed_attr =
 		__ATTR_RO_MODE(sz_ops_filter_passed, 0400);
 
+static struct kobj_attribute damon_sysfs_stats_sz_ops_filter_passed_last_attr =
+		__ATTR_RO_MODE(sz_ops_filter_passed_last, 0400);
+
 static struct kobj_attribute damon_sysfs_stats_qt_exceeds_attr =
 		__ATTR_RO_MODE(qt_exceeds, 0400);
 
@@ -500,6 +513,7 @@ static struct attribute *damon_sysfs_stats_attrs[] = {
 	&damon_sysfs_stats_nr_applied_attr.attr,
 	&damon_sysfs_stats_sz_applied_attr.attr,
 	&damon_sysfs_stats_sz_ops_filter_passed_attr.attr,
+	&damon_sysfs_stats_sz_ops_filter_passed_last_attr.attr,
 	&damon_sysfs_stats_qt_exceeds_attr.attr,
 	&damon_sysfs_stats_nr_snapshots_attr.attr,
 	&damon_sysfs_stats_max_nr_snapshots_attr.attr,
@@ -3130,6 +3144,8 @@ void damon_sysfs_schemes_update_stats(
 		sysfs_stats->sz_applied = scheme->stat.sz_applied;
 		sysfs_stats->sz_ops_filter_passed =
 			scheme->stat.sz_ops_filter_passed;
+		sysfs_stats->sz_ops_filter_passed_last =
+			scheme->stat.sz_ops_filter_passed_last;
 		sysfs_stats->qt_exceeds = scheme->stat.qt_exceeds;
 		sysfs_stats->nr_snapshots = scheme->stat.nr_snapshots;
 	}

-- 
2.54.0-uber3

