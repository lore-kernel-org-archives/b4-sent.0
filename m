From: Jim Cromie <jim.cromie@gmail.com>
Date: Tue, 08 Sep 2026 18:55:09 -0600
Subject: [PATCH v9 13/39] dyndbg: reduce verbose/debug clutter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-dd-cmap-part2-clean-v9-13-3a3f621f4a10@gmail.com>
References: <20260908-dd-cmap-part2-clean-v9-0-3a3f621f4a10@gmail.com>
In-Reply-To: <20260908-dd-cmap-part2-clean-v9-0-3a3f621f4a10@gmail.com>
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
 Jim Cromie <jim.cromie@gmail.com>, 
 Louis Chauvet <louis.chauvet@bootlin.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788915300; l=10845;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=RZ5qUROukv5OkG1GzGxtaTWZxcv/1Cz2lbhZsH57qKg=;
 b=HPV4CflXVV8q1TO3cHfaSj9UCUeWKAmpO3nv/FBYqSJKrhH6xvq0I9yEjKpUMhZjHxVvLk5em
 fsvfHIKXEa1AFKxL9ktr122nG9nvUVAt70gooey+LTPARAjrIR6LgEG
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

currently, for verbose=3, these are logged (blank lines for clarity):

 dyndbg: query 0: "class DRM_UT_CORE +p" mod:*
 dyndbg: split into words: "class" "DRM_UT_CORE" "+p"

 dyndbg: op='+'
 dyndbg: flags=0x1
 dyndbg: *flagsp=0x1 *maskp=0xffffffff

 dyndbg: parsed: func="" file="" module="" format="" lineno=0-0 class=...
 dyndbg: no matches for query
 dyndbg: no-match: func="" file="" module="" format="" lineno=0-0 class=...
 dyndbg: processed 1 queries, with 0 matches, 0 errs

That is excessive, so this patch:
 - shrinks 3 lines of 2nd stanza to single line
 - drops 1st 2 lines of 3rd stanza
   3rd line is like 1st, with result, not procedure.
   2nd line is just status, retold in 4th, with more info.

New output:

 dyndbg: query 0: "class DRM_UT_CORE +p"
 dyndbg: split into words: "class" "DRM_UT_CORE" "+p"
 dyndbg: op='+' flags=0x1 maskp=0xffffffff
 dyndbg: processed 1 queries, with 0 matches, 0 errs

Also drop several verbose=3 messages in ddebug_add_module.  When
modprobing a module, dyndbg currently logs/says "add-module", and then
"skipping" if the module has no prdbgs.  Instead just check 1st and
return quietly.

Unmatched query diagnostics are intentionally restricted to verbose
level 3 (v3pr_info_dq) to reduce dmesg output clutter on standard
verbose levels (verbose=1 and verbose=2), aligning with the overall
de-cluttering of dynamic debug logging.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
Reviewed-by: Louis Chauvet <louis.chauvet@bootlin.com>
---
v7: update fingerprints of grammar-errs changed here
v4: rename vpr_dq_info to v3pr_dq_info to tell its active logging level
    adjust some vX levels per doc'd intentions
v2: RvB after SoB

trivial change to verbose-debug output line to output the actual
"module" keyword rather than "mod:", and do so only when the module is
constrained by the callchain (ie as part of a modprobe).

 was:   query X: "(keyword value)* [+-=]flags" mod:*
 now:   query X: "(keyword value)* [+-=]flags"
   or   query X: module FOO "keyword value)* [+-=]flags"

IOW, adjust output to reflect the input grammar more closely.
---
 lib/dynamic_debug.c                                | 24 +++----
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 84 +++++++++++-----------
 2 files changed, 52 insertions(+), 56 deletions(-)

diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index 43850ff5ccc3..2a69f86f973e 100644
--- a/lib/dynamic_debug.c
+++ b/lib/dynamic_debug.c
@@ -128,7 +128,7 @@ do {								\
 #define v3pr_info(fmt, ...)	vnpr_info(3, fmt, ##__VA_ARGS__)
 #define v4pr_info(fmt, ...)	vnpr_info(4, fmt, ##__VA_ARGS__)
 
-static void vpr_info_dq(const struct ddebug_query *query, const char *msg)
+static void v3pr_info_dq(const struct ddebug_query *query, const char *msg)
 {
 	/* trim any trailing newlines */
 	int fmtlen = 0;
@@ -283,9 +283,6 @@ static int ddebug_change(const struct ddebug_query *query,
 	}
 	mutex_unlock(&ddebug_lock);
 
-	if (!nfound && verbose)
-		pr_info("no matches for query\n");
-
 	return nfound;
 }
 
@@ -494,7 +491,6 @@ static int ddebug_parse_query(char *words[], int nwords,
 		 */
 		query->module = modname;
 
-	vpr_info_dq(query, "parsed");
 	return 0;
 }
 
@@ -518,7 +514,6 @@ static int ddebug_parse_flags(const char *str, struct flag_settings *modifiers)
 		pr_err("bad flag-op %c, at start of %s\n", *str, str);
 		return -EINVAL;
 	}
-	v3pr_info("op='%c'\n", op);
 
 	for (; *str ; ++str) {
 		for (i = ARRAY_SIZE(opt_array) - 1; i >= 0; i--) {
@@ -532,7 +527,6 @@ static int ddebug_parse_flags(const char *str, struct flag_settings *modifiers)
 			return -EINVAL;
 		}
 	}
-	v3pr_info("flags=0x%x\n", modifiers->flags);
 
 	/* calculate final flags, mask based upon op */
 	switch (op) {
@@ -548,7 +542,7 @@ static int ddebug_parse_flags(const char *str, struct flag_settings *modifiers)
 		modifiers->flags = 0;
 		break;
 	}
-	v3pr_info("*flagsp=0x%x *maskp=0x%x\n", modifiers->flags, modifiers->mask);
+	v3pr_info("op='%c' flags=0x%x maskp=0x%x\n", op, modifiers->flags, modifiers->mask);
 
 	return 0;
 }
@@ -577,7 +571,7 @@ static int ddebug_exec_query(char *query_string, const char *modname)
 	}
 	/* actually go and implement the change */
 	nfound = ddebug_change(&query, &modifiers);
-	vpr_info_dq(&query, nfound ? "applied" : "no-match");
+	v3pr_info_dq(&query, nfound ? "applied" : "no-match");
 
 	return nfound;
 }
@@ -600,7 +594,10 @@ static int ddebug_exec_queries(char *query, const char *modname)
 		if (!query || !*query || *query == '#')
 			continue;
 
-		vpr_info("query %d: \"%s\" mod:%s\n", i, query, modname ?: "*");
+		if (modname)
+			v2pr_info("query %d: module %s \"%s\"\n", i, modname, query);
+		else
+			v2pr_info("query %d: \"%s\"\n", i, query);
 
 		rc = ddebug_exec_query(query, modname);
 		if (rc < 0) {
@@ -1167,11 +1164,10 @@ static int ddebug_add_module(struct _ddebug_info *di, const char *modname)
 {
 	struct ddebug_table *dt;
 
-	v3pr_info("add-module: %s.%d sites\n", modname, di->num_descs);
-	if (!di->num_descs) {
-		v3pr_info(" skip %s\n", modname);
+	if (!di->num_descs)
 		return 0;
-	}
+
+	v3pr_info("add-module: %s %d sites\n", modname, di->num_descs);
 
 	dt = kzalloc_obj(*dt);
 	if (dt == NULL) {
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index bf02c505f1b5..e9f9db35fb7f 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -615,48 +615,48 @@ modular_tests=(
 # ==============================================================================
 function GOLDEN_RECORDS {
     cat << 'EOF' | {
-#K= bb85d28739876b0fdf1eb426baae8ef7 FT_grammar_errs.1
-#K= 9c405e06fcea50284df82d1ae9692403 FT_grammar_errs.2
-#K= 0b0d9b0e6f4c45c7d75d699fd3b6aa93 FT_grammar_errs.3
-#K= e008644e159c2a9d99a8d0806c06e71e FT_grammar_errs.4
-#K= 5750ed178633f9a68623f928c093d16e FT_grammar_errs.5
-#K= 2cd51e5e3c3e2501544524bed0fab620 FT_grammar_errs.6
-#K= 3e1eba65bd936e1276c7e1d76b399595 FT_grammar_errs.7
-#K= e3ac86676e309d4e72ff3da287736c29 FT_grammar_errs.8
-#K= 466d325c23519119f754fa7860bae7c6 FT_grammar_errs.9
-#K= 51c489366cd86c16280858b95adf34ac FT_grammar_errs.10
-#K= dfc632c6c0cd6206b6141dbc5fb989db FT_grammar_errs.11
-#K= 69650fc26e97a78082bd851eb4a5c83b FT_grammar_errs.12
-#K= 5cfe5665962a482f416836793067f2a2 FT_grammar_errs.13
-#K= 661cc9a2d8d3c381bfeae41392432575 FT_grammar_errs.14
-#K= 5dd0accf9be37ce2f4bf697e9bdebe30 FT_grammar_errs.15
-#K= bd8d9cf661c9aca54dac93c74cfc1501 FT_grammar_errs.16
-#K= e991391048f2fdffaaed99ba36b787ed FT_grammar_errs.17
-#K= 82d99278f471ebfbf47eeb19898525cf FT_grammar_errs.18
-#K= f3f088fa7d276981bf2898c048087f76 FT_grammar_errs.19
-#K= 984ecc198e0fa9fc91bc31caf7da2a5d FT_grammar_errs.20
-#K= 76c8a33c585d414fcc3f1c8b5ea5b4b3 FT_grammar_errs.21
-#K= 90cfc66e9d61f5c448353b97baa99145 FT_grammar_errs.22
-#K= 37a51dfd6e84cb64b69d3a0e23e68ceb FT_grammar_errs.23
-#K= 3aefa325b63742710b45e4531152c9d8 FT_grammar_errs.24
-#K= bc8d2c23282cd6834879bc1f1b303d05 FT_grammar_errs.25
-#K= 092ec5530d875be1dc96ad4202fc7dc3 FT_grammar_errs.26
-#K= 98caa2677e9070953a852b27ab57861e FT_grammar_errs.27
-#K= 8d755baa707c7b3b67491bf84708ef08 FT_grammar_errs.28
-#K= 5dd0accf9be37ce2f4bf697e9bdebe30 FT_grammar_errs.29
-#K= 2e37642dc8aee3d04b8a54a76b3b891c FT_grammar_errs.30
-#K= 593c8b4c41932e3bde564a0008627ced FT_grammar_errs.31
-#K= 85a2a0bee8d0cd10f883aa5477d62efb FT_grammar_errs.32
-#K= f3f088fa7d276981bf2898c048087f76 FT_grammar_errs.33
-#K= 629f6a7e379e02f38c543cdb48e3b84f FT_grammar_errs.34
-#K= d9f0cffb0898c54690735a71b0d4f3bf FT_grammar_errs.35
-#K= 4cf728b6a32043ea5336a14d0c435312 FT_grammar_errs.36
-#K= a11ae3f86f4e5f539fd6168d318f74b4 FT_grammar_errs.37
-#K= c7d3830b0391f6a773205066b64e15f9 FT_grammar_errs.38
-#K= 5c506ea2bfd050439b580b91543e9be7 FT_grammar_errs.39
-#K= a257660007408f7bb0cb43c99b1c7bb8 FT_grammar_errs.40
-#K= 0082939f100300a7b327b143cf40cb43 FT_grammar_errs.41
-#K= 657ac4360f978687ad25a705b2bb89f1 FT_grammar_errs.42
+#K= f3dbd5afb9aa1750f93275b634499e22 FT_grammar_errs.1
+#K= 200c01632c52a63f6d186da1c6460740 FT_grammar_errs.2
+#K= 7d7141900ce6e32f15c99202309c63a4 FT_grammar_errs.3
+#K= 1bb798a5831d0119789d424ef6cb55c4 FT_grammar_errs.4
+#K= 5edd66e308b2792d5694df86c07a3eaf FT_grammar_errs.5
+#K= 6f87d92ffe0812550f43287127c6f2b9 FT_grammar_errs.6
+#K= c0eb05b58a008c722e091e1ae74440ec FT_grammar_errs.7
+#K= 911929ec0e2ffc1f13822b479dec6805 FT_grammar_errs.8
+#K= c1407512376369d2e591a4b25a4b607a FT_grammar_errs.9
+#K= 2046abda72725ea06fe339d5f364f1c9 FT_grammar_errs.10
+#K= b72f7fccf76f8a5bee47a05d7bb545fb FT_grammar_errs.11
+#K= 98e2bd3e4f3da58536496a38ec3e6238 FT_grammar_errs.12
+#K= b371c6ba52503d037dbc43da788af8be FT_grammar_errs.13
+#K= cb8288d607b0c5282125852f3ab05107 FT_grammar_errs.14
+#K= 9346a310c4ad57cc3746afbace702c3e FT_grammar_errs.15
+#K= 533d27af85eed3c0fd2eaec961982a36 FT_grammar_errs.16
+#K= 114e0632585e205a3347c82bac7d79f2 FT_grammar_errs.17
+#K= 73f5c173bafdfb9674b5ecce77db3354 FT_grammar_errs.18
+#K= 0fc110d078f60eacdd389e5975ba18d9 FT_grammar_errs.19
+#K= 815a1c52f365510c644450bb80c07e72 FT_grammar_errs.20
+#K= 621e3cd81b553973cb40a935bb9298f1 FT_grammar_errs.21
+#K= 581222901232344ade18bbda58302c48 FT_grammar_errs.22
+#K= ea0aae3e01b3bb22eb8ad7acd327b371 FT_grammar_errs.23
+#K= 8f28189bff62a3d5ed16f537d41a725a FT_grammar_errs.24
+#K= 19c425e5d3a645b5dc5e23758ba0f4a1 FT_grammar_errs.25
+#K= 75415542333f2250f0e060a54dae50f8 FT_grammar_errs.26
+#K= 0955815c0e595ab2206e25aa31fe1ef2 FT_grammar_errs.27
+#K= 3ff4c0b60db33e44c3cd6f0e14f81e3e FT_grammar_errs.28
+#K= 9346a310c4ad57cc3746afbace702c3e FT_grammar_errs.29
+#K= 7aaf0a16c287e66b62e11298ee160b34 FT_grammar_errs.30
+#K= 06350c62105b537cdd0c67736b29727d FT_grammar_errs.31
+#K= 6ef0ec01805c8719d828553098f95377 FT_grammar_errs.32
+#K= 0fc110d078f60eacdd389e5975ba18d9 FT_grammar_errs.33
+#K= 72203b2d88d0617cd5c659d3b80e26f9 FT_grammar_errs.34
+#K= 6ecb03736d5cddb7ab2aaff49d561be9 FT_grammar_errs.35
+#K= eaa989336cb7c96c13ef4a3964fc6898 FT_grammar_errs.36
+#K= 5b624d9c133d7bb4f5370c3ce06929ed FT_grammar_errs.37
+#K= 127275739b1fe04c84eedad28ec154f6 FT_grammar_errs.38
+#K= 3e2fd15a7e8c0583bc5066524bc50508 FT_grammar_errs.39
+#K= 781995971d28f732a792522f3c56cdd3 FT_grammar_errs.40
+#K= 6614a677d9f9ac09d9825b4e989d2c42 FT_grammar_errs.41
+#K= 70de9afed457a6be9f9c3c81cbd6d4d5 FT_grammar_errs.42
 #K= 6e8599556a312200fb6d484565b6c52f FT_basic_queries.1
 #K= db17180b59444e5e34a8fc20c40e4530 FT_basic_queries.2
 #K= f7bd56bd407ff255ef2e3b5fb093ae6a FT_basic_queries.3

-- 
2.55.0

