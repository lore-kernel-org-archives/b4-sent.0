From: Joel Granados <j.granados@samsung.com>
Date: Mon, 13 May 2024 11:25:18 +0200
Subject: [PATCH] sysctl: constify ctl_table arguments of utility function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240513-jag-constfy_sysctl_proc_args-v1-1-bba870a480d5@samsung.com>
X-B4-Tracking: v=1; b=H4sIAH3cQWYC/x3MUQqDMAwA0KtIvi20VhnsKkNKqLHLGK0kIop4d
 4uf7+edoCRMCu/mBKGNlUuucG0D8Ys5keGpGjrb9XZw3vwwmViyrvMR9NC4/sMiJQaUpKZ3ZBH
 98PLWQy0WoZn3p/+M13UDZW5V/24AAAA=
To: =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <linux@weissschuh.net>, 
 Luis Chamberlain <mcgrof@kernel.org>, Kees Cook <keescook@chromium.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=6218;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=UbuzwFV9yt+MFeVXaXbM4GSooBlNbbHVhu3sJmvZDXg=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZB3J0JCUzdt5tMMeU5ki7dQFrJZcBDoJwFZ
 XLiT1xsxaTN5IkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmQdydAAoJELqXzVK3
 lkFPnvML/2pZoajPo85FfZuk0XHnvPstK3chOwygf6eXdRKuHcwHTZmsFs5LLphCFbNU8wq2lO0
 I3kem+B59qHprrMTz8WIfOCjCsSMTvX/gjemPUs+NAaNeIhudIHqXTLCK8kd2Yt5a7ecH8QMxlf
 bvVYG2ynOTsDSD62WjFXbviWI2LGO/VSutpkViTm8dyGKsBmp9Ym3DsZdPmhbWhxixpwQIh5U5u
 hvIpG5pcjMjx3fs/pN5TPZDhdH1pMTwDJx3zmq8Ho3Zucs/lAcq1PA6DfOtUJwqouWqzte8uWAL
 MtGmHfNUlOK0gh+PmBQIh0tpzmq2LChvX2KhzCpCm/zNoeA6szdo8x++yStyGLGwow+OMvNjHMU
 XVKj6A2E6AN03SDzzqQB//h70GqsCo7ZHL32lLh7rxuHiG8/AYbtHbRxcdfYZsm7FSFuNhMnd/q
 91dAI4Cu0h9HOVASgwntIY37C3Sf2mH5MogX1jadsbp6QkdERI5V4lPP1/dZRgnHUG7/NVZRfH6
 xY=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Thomas Weißschuh <linux@weissschuh.net>

In a future commit the proc_handlers themselves will change to
"const struct ctl_table". As a preparation for that adapt the internal
helper.

Signed-off-by: Thomas Weißschuh <linux@weissschuh.net>
---
What:
Modify the arguments of utility functions within the sysctl subsystem in
preparation for the system wide commit (should look like this [5]). This
patch is picked out from Thomas's series in [6]. Note that this commit
does *not* constify any ctl_table structures.

Why:
This is part of a greater constification effort that involves several
patchsets and subsystems ([3,4,5,6]). This patchset is in preparation
to:
1. Increase safety by putting ctl_table struct objects in .rodata and
   making the pointers to the proc_handler functions read only.
2. Clarify and transmit intent to API users so that it is obvious that
   ctl_table object are not meant to change.

[1] [PATCH v2 00/14] ASoC: Constify local snd_sof_dsp_ops
    https://lore.kernel.org/all/20240426-n-const-ops-var-v2-0-e553fe67ae82@kernel.org
[2] [PATCH v2 00/19] backlight: Constify lcd_ops
    https://lore.kernel.org/all/20240424-video-backlight-lcd-ops-v2-0-1aaa82b07bc6@kernel.org
[3] [PATCH 1/4] iommu: constify pointer to bus_type
    https://lore.kernel.org/all/20240216144027.185959-1-krzysztof.kozlowski@linaro.org
[4] [PATCH 00/29] const xattr tables
    https://lore.kernel.org/all/20230930050033.41174-1-wedsonaf@gmail.com
[5] https://lore.kernel.org/linux-mm/20240423-sysctl-const-handler-v3-11-e0beccb836e2@weissschuh.net/
[6] https://lore.kernel.org/all/20240423-sysctl-const-handler-v3-0-e0beccb836e2@weissschuh.net

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 include/linux/sysctl.h |  2 +-
 kernel/sysctl.c        | 21 +++++++++++----------
 2 files changed, 12 insertions(+), 11 deletions(-)

diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index ee7d33b89e9e..99ea26b16c0d 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -238,7 +238,7 @@ extern struct ctl_table_header *register_sysctl_mount_point(const char *path);
 
 void do_sysctl_args(void);
 bool sysctl_is_alias(char *param);
-int do_proc_douintvec(struct ctl_table *table, int write,
+int do_proc_douintvec(const struct ctl_table *table, int write,
 		      void *buffer, size_t *lenp, loff_t *ppos,
 		      int (*conv)(unsigned long *lvalp,
 				  unsigned int *valp,
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 81cc974913bb..233380f967f8 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -205,7 +205,7 @@ static int _proc_do_string(char *data, int maxlen, int write,
 	return 0;
 }
 
-static void warn_sysctl_write(struct ctl_table *table)
+static void warn_sysctl_write(const struct ctl_table *table)
 {
 	pr_warn_once("%s wrote to %s when file position was not 0!\n"
 		"This will not be supported in the future. To silence this\n"
@@ -223,7 +223,7 @@ static void warn_sysctl_write(struct ctl_table *table)
  * handlers can ignore the return value.
  */
 static bool proc_first_pos_non_zero_ignore(loff_t *ppos,
-					   struct ctl_table *table)
+					   const struct ctl_table *table)
 {
 	if (!*ppos)
 		return false;
@@ -468,7 +468,7 @@ static int do_proc_douintvec_conv(unsigned long *lvalp,
 
 static const char proc_wspace_sep[] = { ' ', '\t', '\n' };
 
-static int __do_proc_dointvec(void *tbl_data, struct ctl_table *table,
+static int __do_proc_dointvec(void *tbl_data, const struct ctl_table *table,
 		  int write, void *buffer,
 		  size_t *lenp, loff_t *ppos,
 		  int (*conv)(bool *negp, unsigned long *lvalp, int *valp,
@@ -541,7 +541,7 @@ static int __do_proc_dointvec(void *tbl_data, struct ctl_table *table,
 	return err;
 }
 
-static int do_proc_dointvec(struct ctl_table *table, int write,
+static int do_proc_dointvec(const struct ctl_table *table, int write,
 		  void *buffer, size_t *lenp, loff_t *ppos,
 		  int (*conv)(bool *negp, unsigned long *lvalp, int *valp,
 			      int write, void *data),
@@ -552,7 +552,7 @@ static int do_proc_dointvec(struct ctl_table *table, int write,
 }
 
 static int do_proc_douintvec_w(unsigned int *tbl_data,
-			       struct ctl_table *table,
+			       const struct ctl_table *table,
 			       void *buffer,
 			       size_t *lenp, loff_t *ppos,
 			       int (*conv)(unsigned long *lvalp,
@@ -639,7 +639,7 @@ static int do_proc_douintvec_r(unsigned int *tbl_data, void *buffer,
 	return err;
 }
 
-static int __do_proc_douintvec(void *tbl_data, struct ctl_table *table,
+static int __do_proc_douintvec(void *tbl_data, const struct ctl_table *table,
 			       int write, void *buffer,
 			       size_t *lenp, loff_t *ppos,
 			       int (*conv)(unsigned long *lvalp,
@@ -675,7 +675,7 @@ static int __do_proc_douintvec(void *tbl_data, struct ctl_table *table,
 	return do_proc_douintvec_r(i, buffer, lenp, ppos, conv, data);
 }
 
-int do_proc_douintvec(struct ctl_table *table, int write,
+int do_proc_douintvec(const struct ctl_table *table, int write,
 		      void *buffer, size_t *lenp, loff_t *ppos,
 		      int (*conv)(unsigned long *lvalp,
 				  unsigned int *valp,
@@ -1023,8 +1023,9 @@ static int sysrq_sysctl_handler(struct ctl_table *table, int write,
 }
 #endif
 
-static int __do_proc_doulongvec_minmax(void *data, struct ctl_table *table,
-		int write, void *buffer, size_t *lenp, loff_t *ppos,
+static int __do_proc_doulongvec_minmax(void *data,
+		const struct ctl_table *table, int write,
+		void *buffer, size_t *lenp, loff_t *ppos,
 		unsigned long convmul, unsigned long convdiv)
 {
 	unsigned long *i, *min, *max;
@@ -1096,7 +1097,7 @@ static int __do_proc_doulongvec_minmax(void *data, struct ctl_table *table,
 	return err;
 }
 
-static int do_proc_doulongvec_minmax(struct ctl_table *table, int write,
+static int do_proc_doulongvec_minmax(const struct ctl_table *table, int write,
 		void *buffer, size_t *lenp, loff_t *ppos, unsigned long convmul,
 		unsigned long convdiv)
 {

---
base-commit: a38297e3fb012ddfa7ce0321a7e5a8daeb1872b6
change-id: 20240513-jag-constfy_sysctl_proc_args-41e0aa357303

Best regards,
-- 
Joel Granados <j.granados@samsung.com>

