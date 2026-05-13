From: Chen Linxuan <me@black-desk.cn>
Date: Wed, 13 May 2026 16:08:17 +0800
Subject: [PATCH v4 1/2] config: refactor include_by_gitdir() into
 include_by_path()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260513-includeif-worktree-v4-1-f8e6212d1fba@black-desk.cn>
References: <20260513-includeif-worktree-v4-0-f8e6212d1fba@black-desk.cn>
In-Reply-To: <20260513-includeif-worktree-v4-0-f8e6212d1fba@black-desk.cn>
To: git@vger.kernel.org
Cc: Kristoffer Haugsbakk <kristofferhaugsbakk@fastmail.com>, 
 Junio C Hamano <gitster@pobox.com>, Patrick Steinhardt <ps@pks.im>, 
 Chen Linxuan <me@black-desk.cn>, Phillip Wood <phillip.wood@dunelm.org.uk>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2786; i=me@black-desk.cn;
 h=from:subject:message-id; bh=yvkS6GGoBsk+BJdWDXSoiHZd4Dvb067JLuW86tJ84MQ=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqBDGUd+G+8WmcWIym39HPan8wTdvfz8ACQe9Ij
 lgFYdCcFtWJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCagQxlAAKCRB2HuYUOZmu
 i8wTD/0ajh99XUjBkp/+UQGhnGNn3lPWktAaKLxfAvuX8OPeYjusD696BNl08erQBJuMNNplVXf
 t1ai4PAL8idj/CR2Iku2B3bmV3nYDeCJblFfrhdchtlH19N+cOkMsM1NCPe5We9aGfgs/imsC9m
 U2u8vy6RoOhTTFfXOMuAQPxvNKcd7xdl476yxDPJgEsLAWeLcTSYd0YocIqu0Pc8b0D18ZwiKUR
 S4lSt1MWMyfKt6CNsFviAVfSwW4Y5r7wSTsdWLAL/iDXvyWY1MvSDAv1lRsseuaCOHRNUe5iRT8
 ejCewtpKEBzNahIp8DTdgUttvDvjmmb44WDJ4nO2Vot+fVx8VZiFoKnAI2S4rNcJDpvMns9flR2
 PV8NiQTHwnB8tQBiEkjOmA8vPTOErWMs+RhDHqe0urqbS+OgGhgtN++NWb8UqvUD37FCtusSYzQ
 vCkHlR787BI/VutNEz4FdBZ9y951zwOZvnWYMiAasxlHUxHAB9oJaHvuUwOMIDNSelHEsfJGuZY
 2OHfrzkN0jMWDiyYIbzqio5lgyNI66IkJYFsidLskhbxs3h19A5AEAQBy492bJaubtZd5YSCMIw
 rgFA/1Fc4/oBQmv1IdUiMxBMcYTupWAiFNl1vhFVRy6IbEYStZ6npljNA8S+4hjofblSk9Qq9VC
 S1cwTLU1mCwgARQ==
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

