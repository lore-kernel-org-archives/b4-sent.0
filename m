From: Jim Cromie <jim.cromie@gmail.com>
Date: Wed, 16 Sep 2026 09:33:04 -0600
Subject: [PATCH v10 12/38] dyndbg: bump num-tokens in a query-cmd from 9 to
 15
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260916-dd-cmap-part2-clean-v10-12-af4cf4767707@gmail.com>
References: <20260916-dd-cmap-part2-clean-v10-0-af4cf4767707@gmail.com>
In-Reply-To: <20260916-dd-cmap-part2-clean-v10-0-af4cf4767707@gmail.com>
To: Jason Baron <jbaron@akamai.com>, Shuah Khan <shuah@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Arnd Bergmann <arnd@arndb.de>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Aaron Tomlin <atomlin@atomlin.com>, 
 Jonathan Corbet <corbet@net.net>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Len Brown <lenb@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, linux-pm@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789572777; l=3086;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=ZGemRpU3viZV1yyWNrUvp83bn0nizPoTEiNG6+9byRk=;
 b=U11SX80pKnjEiP9L+ni/xIVpnJ0qf6b63AUzYMQGC8xqR+eZWUXymkZ+KVoSZ7Fm7lGn3baEP
 emhNvZv5MzFAtb/0qv/NrLW/ayPRmHZ303QZx0oHngbc9shpedhCENb
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Current MAXWORDS in ddebug_exec_query() is too small to accept a legal
query-command using all 6 keywords.  We *need* 13, but this adds a few
extra to allow certain errors to fail on subsequent, more meaningful
grammar checks.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 lib/dynamic_debug.c                                      |  2 +-
 tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh | 12 ++++++------
 2 files changed, 7 insertions(+), 7 deletions(-)

diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index b4617c57dcec..83983b261bf8 100644
--- a/lib/dynamic_debug.c
+++ b/lib/dynamic_debug.c
@@ -558,7 +558,7 @@ static int ddebug_exec_query(char *query_string, const char *modname)
 {
 	struct flag_settings modifiers = {};
 	struct ddebug_query query = {};
-#define MAXWORDS 9
+#define MAXWORDS 15
 	int nwords, nfound;
 	char *words[MAXWORDS];
 
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index 73c2a4b07bd3..04c1d9254ca9 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -326,8 +326,8 @@ function GOLDEN_RECORDS {
 #K= b9a397e807148d13ba07da7db7e69817 FT_grammar_errs.2
 #K= 5abefa504937a329f974504f1896e368 FT_grammar_errs.3
 #K= 1d94d0f239bf40bf51280caeab499de0 FT_grammar_errs.4
-#K= 135035c8a17ae100cc4ec954c4d75b2f FT_grammar_errs.5
-#K= a9cc14244f91a12d3174ad1314144a8e FT_grammar_errs.6
+#K= 9a5e1c1856f1ebbe57a4afdfc4c9703a FT_grammar_errs.5
+#K= b3809a6f9f643f049f1ef30827d4b001 FT_grammar_errs.6
 #K= 5d400aad1a7d71f548b6b81274d00a55 FT_grammar_errs.7
 #K= 61cd359b10f9051862d3745eda07a295 FT_grammar_errs.8
 #K= 567379f4f4d099f00f37d1469d9370bd FT_grammar_errs.9
@@ -346,8 +346,8 @@ function GOLDEN_RECORDS {
 #K= 1f6fedfe222af475211b3bfc6d08bc63 FT_grammar_errs.22
 #K= c67dfeca97697b707acdd70672816dff FT_grammar_errs.23
 #K= 9574dbfdac063409b41a44e6251fbcd9 FT_grammar_errs.24
-#K= 644b81753949ac1285e38ac995eeba46 FT_grammar_errs.25
-#K= 1bf2a93a39961f40e0c2dd4c5e2edc6d FT_grammar_errs.26
+#K= 3c694a0ee2cf3a1d39f2ca8a9f3b9094 FT_grammar_errs.25
+#K= c23be05426c8727be833ff055944aa96 FT_grammar_errs.26
 #K= cdddf4ffd7fde3c12eb0c73770b872bf FT_grammar_errs.27
 #K= cdf7a2e2740ec007efbd29feda478420 FT_grammar_errs.28
 #K= f6650d69963cef433c50e1f2acb899fc FT_grammar_errs.29
@@ -366,8 +366,8 @@ function GOLDEN_RECORDS {
 #K= 1a402ada248d0d50cec13a1af150ea33 FT_grammar_errs.42
 #K= 5b46a8eb0d74009462f74cf7553e3228 FT_grammar_errs.43
 #K= 546e440044828d86135dd63f1eb9ed17 FT_grammar_errs.44
-#K= 644b81753949ac1285e38ac995eeba46 FT_grammar_errs.45
-#K= 1bf2a93a39961f40e0c2dd4c5e2edc6d FT_grammar_errs.46
+#K= 3c694a0ee2cf3a1d39f2ca8a9f3b9094 FT_grammar_errs.45
+#K= 37b7ab754e579683a28ce086c470cdc9 FT_grammar_errs.46
 #K= 3e3acfb800cfb1bcb0cc07f33b75830a FT_grammar_errs.47
 #K= 42dc6cb4fe938bb82b64c82924ef28d8 FT_grammar_errs.48
 #K= cf9320d2188f5b48d508d610d95298b2 FT_grammar_errs.49

-- 
2.55.0

