From: Chen Linxuan <me@black-desk.cn>
Date: Fri, 03 Apr 2026 15:02:28 +0800
Subject: [PATCH v3 1/2] config: refactor include_by_gitdir() into
 include_by_path()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-includeif-worktree-v3-1-109ce5782b03@black-desk.cn>
References: <20260403-includeif-worktree-v3-0-109ce5782b03@black-desk.cn>
In-Reply-To: <20260403-includeif-worktree-v3-0-109ce5782b03@black-desk.cn>
To: git@vger.kernel.org
Cc: Kristoffer Haugsbakk <kristofferhaugsbakk@fastmail.com>, 
 Junio C Hamano <gitster@pobox.com>, Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2786; i=me@black-desk.cn;
 h=from:subject:message-id; bh=yvkS6GGoBsk+BJdWDXSoiHZd4Dvb067JLuW86tJ84MQ=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBpz2YgmLK2XJDMD5MTvQzr/oXFGybt6xOnaUOKd
 R3jabpUd8qJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCac9mIAAKCRB2HuYUOZmu
 i8MREAC1nFwnlVype3a9DVNVfmkYLn5DB7AIxN6zy6N2tE2+QdgCp2DUc+EXvgEhZgI/ck8c7wJ
 HOn7R3LuYsdy1S7sbARXkaiLxEoJfFrwpbk1dCLdOUUsyCAn4nh1As1SUdO9IE/L3cLlsi4zKlh
 /t9AY1y+MIn77cVvp13AqYRSubI0w8RovRL+ZFEL7oVAh/q4QshyDAu2Nxh/e6fkUvYRX1ddPXt
 WO5VNZdd7DTPdzIutVgQaS7W/2CnTSGkkip/0blFwtxmNRqCQdDVuPJVODTvHJKFeM/nqEHPJng
 7gf1+Fqi8RUBXhHZ5Y+4rfyE9cWo9DT91Fs6b0w5CNQYbJ7zI10B4iqK/+cG79J/2EGM+fhDmoA
 jClTEJO/eGDDdbbDGZM5YIUtuqYT0/zaJxAtocbXNshya+W0P/xic4N4bmh/mQ+Ba8RdXreDiH9
 2/g9bafLxHVSVTzzJobWP5TJBOX+oos13A/zbwsZs6QGgeARMlSG3Au1Oa4etCSB5MtoQF2tQ8I
 DDV7PRpAxvhfmEIeIR/1Yf8dkc1a/RXSAklHpqDGiqe+pG6LlH4V6LjulAsIlVNXHU/GFRuj491
 BbaP+yQe+9FYqG32zuCyCL66gapems59r6x2pwHIaPEXgUVgqCG0fj5wquaxlBHJv7SxOLgGxuv
 wlLBSq1/Kczw0eg==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/default with auth_id=573
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The include_by_gitdir() function matches the realpath of a given
path against a glob pattern, but its interface is tightly coupled to
the gitdir condition: it takes a struct config_options *opts and
extracts opts->git_dir internally.

Refactor it into a more generic include_by_path() helper that takes
a const char *path parameter directly, and update the gitdir and
gitdir/i callers to pass opts->git_dir explicitly.  No behavior
change, just preparing for the addition of a new worktree condition
that will reuse the same path-matching logic with a different path.

Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 config.c | 19 ++++++++-----------
 1 file changed, 8 insertions(+), 11 deletions(-)

diff --git a/config.c b/config.c
index 156f2a24fa00..7d5dae0e8450 100644
--- a/config.c
+++ b/config.c
@@ -235,23 +235,20 @@ static int prepare_include_condition_pattern(const struct key_value_info *kvi,
 	return 0;
 }
 
-static int include_by_gitdir(const struct key_value_info *kvi,
-			     const struct config_options *opts,
-			     const char *cond, size_t cond_len, int icase)
+static int include_by_path(const struct key_value_info *kvi,
+			   const char *path,
+			   const char *cond, size_t cond_len, int icase)
 {
 	struct strbuf text = STRBUF_INIT;
 	struct strbuf pattern = STRBUF_INIT;
 	size_t prefix;
 	int ret = 0;
-	const char *git_dir;
 	int already_tried_absolute = 0;
 
-	if (opts->git_dir)
-		git_dir = opts->git_dir;
-	else
+	if (!path)
 		goto done;
 
-	strbuf_realpath(&text, git_dir, 1);
+	strbuf_realpath(&text, path, 1);
 	strbuf_add(&pattern, cond, cond_len);
 	ret = prepare_include_condition_pattern(kvi, &pattern, &prefix);
 	if (ret < 0)
@@ -284,7 +281,7 @@ static int include_by_gitdir(const struct key_value_info *kvi,
 		 * which'll do the right thing
 		 */
 		strbuf_reset(&text);
-		strbuf_add_absolute_path(&text, git_dir);
+		strbuf_add_absolute_path(&text, path);
 		already_tried_absolute = 1;
 		goto again;
 	}
@@ -400,9 +397,9 @@ static int include_condition_is_true(const struct key_value_info *kvi,
 	const struct config_options *opts = inc->opts;
 
 	if (skip_prefix_mem(cond, cond_len, "gitdir:", &cond, &cond_len))
-		return include_by_gitdir(kvi, opts, cond, cond_len, 0);
+		return include_by_path(kvi, opts->git_dir, cond, cond_len, 0);
 	else if (skip_prefix_mem(cond, cond_len, "gitdir/i:", &cond, &cond_len))
-		return include_by_gitdir(kvi, opts, cond, cond_len, 1);
+		return include_by_path(kvi, opts->git_dir, cond, cond_len, 1);
 	else if (skip_prefix_mem(cond, cond_len, "onbranch:", &cond, &cond_len))
 		return include_by_branch(inc, cond, cond_len);
 	else if (skip_prefix_mem(cond, cond_len, "hasconfig:remote.*.url:", &cond,

-- 
2.53.0

