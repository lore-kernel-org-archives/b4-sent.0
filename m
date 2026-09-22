From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:08:41 -0400
Subject: [PATCH] soc: tegra: cbb: walk cbb_list under cbb_lock in the
 debugfs path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-tegra-cbb-v1-1-67aa3712aa4b@vt.edu>
X-B4-Tracking: v=1; b=H4sIABjVsWoC/yXMwQ6CQAwE0F8hPVsDqyL6K8bDtlugJq6mi8SE8
 O/u4vFNZmaBJKaS4FotYDJr0lfMaHYV8OjjIKghG1zt2vriGnwSTjKYRybCEFwI0p247XrIk7d
 Jr9/t7nb/O33oITyVj9IgnwTJfOSxRBvn8/6AxkdY1x8JSV+kkAAAAA==
X-Change-ID: 20260921-mb-tegra-cbb-dd2dde85c68f
To: Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790039326; l=2069;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=TnU7XDcPbIvevl70JeyBncqSk6nfZZH/4bzxa+jtmw8=;
 b=KGpSDD2inrUNpQy+0tK3z/l30omzvntoM99pEYBBuUqRufWbG1G/py3UW7VHWN/exKYdXk+IB
 ti30HhShB7+DbiD1ZqN47b+igdSHBtmq9dzlZm23uXBuUC4PLviIrwj
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra194_cbb_probe() and tegra194_cbb_remove() add and remove cbb_list
entries under cbb_lock, and the error interrupt handler walks the list
under the same lock. tegra194_cbb_debugfs_show() walks it holding only
cbb_err_mutex, which the writers never take.

A debugfs read of one CBB instance can therefore run while another
instance is probed or removed. list_add() publishes the node with a
plain store, so the walker can see a node before its links and private
data are visible, or step onto a node that remove is freeing.

Take cbb_lock around the walk. cbb_err_mutex keeps its existing job of
serialising the error log output.

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/soc/tegra/cbb/tegra194-cbb.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/soc/tegra/cbb/tegra194-cbb.c b/drivers/soc/tegra/cbb/tegra194-cbb.c
index 69ef929e0..d1a80b0b5 100644
--- a/drivers/soc/tegra/cbb/tegra194-cbb.c
+++ b/drivers/soc/tegra/cbb/tegra194-cbb.c
@@ -1990,9 +1990,16 @@ static DEFINE_MUTEX(cbb_err_mutex);
 static int tegra194_cbb_debugfs_show(struct tegra_cbb *cbb, struct seq_file *file, void *data)
 {
 	struct tegra_cbb *noc;
+	unsigned long flags;
 
 	mutex_lock(&cbb_err_mutex);
 
+	/*
+	 * cbb_list is modified under cbb_lock by the probe and remove paths of
+	 * the other CBB instances; cbb_err_mutex alone does not exclude them.
+	 */
+	spin_lock_irqsave(&cbb_lock, flags);
+
 	list_for_each_entry(noc, &cbb_list, node) {
 		struct tegra194_cbb *priv = to_tegra194_cbb(noc);
 		u32 status;
@@ -2002,6 +2009,8 @@ static int tegra194_cbb_debugfs_show(struct tegra_cbb *cbb, struct seq_file *fil
 			print_errlog(file, priv, status);
 	}
 
+	spin_unlock_irqrestore(&cbb_lock, flags);
+
 	mutex_unlock(&cbb_err_mutex);
 
 	return 0;

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-tegra-cbb-dd2dde85c68f

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

