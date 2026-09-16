From: Jim Cromie <jim.cromie@gmail.com>
Date: Wed, 16 Sep 2026 09:33:05 -0600
Subject: [PATCH v10 13/38] dyndbg: reduce verbose/debug clutter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260916-dd-cmap-part2-clean-v10-13-af4cf4767707@gmail.com>
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
 Jim Cromie <jim.cromie@gmail.com>, 
 Louis Chauvet <louis.chauvet@bootlin.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789572777; l=12932;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=cn289Vv5vBG6H4LI9zm5c2S/wvfFrR5HNFwuhQU/epI=;
 b=s1T2H/B5da2j5TLClhnqlJJmqjhNolRdhYs638k/bWG8BQhJiXU0UcXV/Lvj0sa78ANmwduz1
 XJmg+EashMDDURxgV3rzyicX2Y6aOgQ94sAnL6acSlEItOjDV64b7+U
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
 lib/dynamic_debug.c                                |  24 ++---
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 120 ++++++++++-----------
 2 files changed, 70 insertions(+), 74 deletions(-)

diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index 83983b261bf8..ca8e3cea504c 100644
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
@@ -284,9 +284,6 @@ static int ddebug_change(const struct ddebug_query *query,
 	}
 	mutex_unlock(&ddebug_lock);
 
-	if (!nfound && verbose)
-		pr_info("no matches for query\n");
-
 	return nfound;
 }
 
@@ -495,7 +492,6 @@ static int ddebug_parse_query(char *words[], int nwords,
 		 */
 		query->module = modname;
 
-	vpr_info_dq(query, "parsed");
 	return 0;
 }
 
@@ -519,7 +515,6 @@ static int ddebug_parse_flags(const char *str, struct flag_settings *modifiers)
 		pr_err("bad flag-op %c, at start of %s\n", *str, str);
 		return -EINVAL;
 	}
-	v3pr_info("op='%c'\n", op);
 
 	for (; *str ; ++str) {
 		for (i = ARRAY_SIZE(opt_array) - 1; i >= 0; i--) {
@@ -533,7 +528,6 @@ static int ddebug_parse_flags(const char *str, struct flag_settings *modifiers)
 			return -EINVAL;
 		}
 	}
-	v3pr_info("flags=0x%x\n", modifiers->flags);
 
 	/* calculate final flags, mask based upon op */
 	switch (op) {
@@ -549,7 +543,7 @@ static int ddebug_parse_flags(const char *str, struct flag_settings *modifiers)
 		modifiers->flags = 0;
 		break;
 	}
-	v3pr_info("*flagsp=0x%x *maskp=0x%x\n", modifiers->flags, modifiers->mask);
+	v3pr_info("op='%c' flags=0x%x maskp=0x%x\n", op, modifiers->flags, modifiers->mask);
 
 	return 0;
 }
@@ -578,7 +572,7 @@ static int ddebug_exec_query(char *query_string, const char *modname)
 	}
 	/* actually go and implement the change */
 	nfound = ddebug_change(&query, &modifiers);
-	vpr_info_dq(&query, nfound ? "applied" : "no-match");
+	v3pr_info_dq(&query, nfound ? "applied" : "no-match");
 
 	return nfound;
 }
@@ -601,7 +595,10 @@ static int ddebug_exec_queries(char *query, const char *modname)
 		if (!query || !*query || *query == '#')
 			continue;
 
-		vpr_info("query %d: \"%s\" mod:%s\n", i, query, modname ?: "*");
+		if (modname)
+			v2pr_info("query %d: module %s \"%s\"\n", i, modname, query);
+		else
+			v2pr_info("query %d: \"%s\"\n", i, query);
 
 		rc = ddebug_exec_query(query, modname);
 		if (rc < 0) {
@@ -1168,11 +1165,10 @@ static int ddebug_add_module(struct _ddebug_info *di, const char *modname)
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
index 04c1d9254ca9..972f12c70a8e 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -322,66 +322,66 @@ modular_tests=(
 # ==============================================================================
 function GOLDEN_RECORDS {
     cat << 'EOF' | {
-#K= b938440930e5f1297d524e6c0c1ec85c FT_grammar_errs.1
-#K= b9a397e807148d13ba07da7db7e69817 FT_grammar_errs.2
-#K= 5abefa504937a329f974504f1896e368 FT_grammar_errs.3
-#K= 1d94d0f239bf40bf51280caeab499de0 FT_grammar_errs.4
-#K= 9a5e1c1856f1ebbe57a4afdfc4c9703a FT_grammar_errs.5
-#K= b3809a6f9f643f049f1ef30827d4b001 FT_grammar_errs.6
-#K= 5d400aad1a7d71f548b6b81274d00a55 FT_grammar_errs.7
-#K= 61cd359b10f9051862d3745eda07a295 FT_grammar_errs.8
-#K= 567379f4f4d099f00f37d1469d9370bd FT_grammar_errs.9
-#K= 31a026d10f85e8f4c9f8cf3e1cef3c61 FT_grammar_errs.10
-#K= ba62952b671a553d4b14e344a61926f7 FT_grammar_errs.11
-#K= 49aec6c2e99cc70a1e4137f86e94f6f4 FT_grammar_errs.12
-#K= cc02cccf15988a98dfd5b1df1e492e31 FT_grammar_errs.13
-#K= 2bbf3fac2b77b88b6cebe459ff9631d3 FT_grammar_errs.14
-#K= 93b67411c254875a6bae5c01c0239729 FT_grammar_errs.15
-#K= b22f2efe54a1637156b9521b2794806e FT_grammar_errs.16
-#K= de410dba40d8b097524f91da8ae2b1c5 FT_grammar_errs.17
-#K= 6c922048c21f6198720dfd68ae16fdad FT_grammar_errs.18
-#K= 4ddd57e9cbc3da2613ac59eb285ad8c1 FT_grammar_errs.19
-#K= ba65062f6be00a1d04907dd176d26c19 FT_grammar_errs.20
-#K= 94cdf3b32afa4f12a00a704208aa2e53 FT_grammar_errs.21
-#K= 1f6fedfe222af475211b3bfc6d08bc63 FT_grammar_errs.22
-#K= c67dfeca97697b707acdd70672816dff FT_grammar_errs.23
-#K= 9574dbfdac063409b41a44e6251fbcd9 FT_grammar_errs.24
-#K= 3c694a0ee2cf3a1d39f2ca8a9f3b9094 FT_grammar_errs.25
-#K= c23be05426c8727be833ff055944aa96 FT_grammar_errs.26
-#K= cdddf4ffd7fde3c12eb0c73770b872bf FT_grammar_errs.27
-#K= cdf7a2e2740ec007efbd29feda478420 FT_grammar_errs.28
-#K= f6650d69963cef433c50e1f2acb899fc FT_grammar_errs.29
-#K= e150a96693eb561a20eebebfd637e667 FT_grammar_errs.30
-#K= b63514cf73a93962311d098284d7b491 FT_grammar_errs.31
-#K= b253cde723889c42d2c944c1b14f5a45 FT_grammar_errs.32
-#K= 7ad3dfb73e82f4d75b0770179e6dc264 FT_grammar_errs.33
-#K= f4d905e4f72dbd535bb80d7fe9df84b0 FT_grammar_errs.34
-#K= 5bf50b198d8e5fe300541adfce92e073 FT_grammar_errs.35
-#K= 7c4d73d42cff377cd84a7683b0c3e0b9 FT_grammar_errs.36
-#K= 19f1aa8d33d71888be74b19a3143938f FT_grammar_errs.37
-#K= 84309c1322631ae74ecf2c729b6aa210 FT_grammar_errs.38
-#K= 8cfe48871f91a90e6eaaef9123892394 FT_grammar_errs.39
-#K= 8aaa5fdd50ead5cd429fbba4123b215c FT_grammar_errs.40
-#K= 94cdf3b32afa4f12a00a704208aa2e53 FT_grammar_errs.41
-#K= 1a402ada248d0d50cec13a1af150ea33 FT_grammar_errs.42
-#K= 5b46a8eb0d74009462f74cf7553e3228 FT_grammar_errs.43
-#K= 546e440044828d86135dd63f1eb9ed17 FT_grammar_errs.44
-#K= 3c694a0ee2cf3a1d39f2ca8a9f3b9094 FT_grammar_errs.45
-#K= 37b7ab754e579683a28ce086c470cdc9 FT_grammar_errs.46
-#K= 3e3acfb800cfb1bcb0cc07f33b75830a FT_grammar_errs.47
-#K= 42dc6cb4fe938bb82b64c82924ef28d8 FT_grammar_errs.48
-#K= cf9320d2188f5b48d508d610d95298b2 FT_grammar_errs.49
-#K= 1f33fb1fd2365e77c3cfbd61d1ae2a7c FT_grammar_errs.50
-#K= 67588c71f92f319c6224d5917456ecd2 FT_grammar_errs.51
-#K= 22e7795f7dbeb6dc2fce5e113312781c FT_grammar_errs.52
-#K= 66d253407728c1f8a850519eadd66880 FT_grammar_errs.53
-#K= 27e8345aaeed85c1de5516871e0bbd0c FT_grammar_errs.54
-#K= 43cc8a154f28f1a668ab409a1af4e77a FT_grammar_errs.55
-#K= eda21551fcdd76ef2f192e1d9950a05f FT_grammar_errs.56
-#K= 0a8a986b5610630cb75c0568deff8315 FT_grammar_errs.57
-#K= 29bfae73351c3157a5fe409febcef276 FT_grammar_errs.58
-#K= 73a9e53428d1fb1a9813e3eab7d0ea18 FT_grammar_errs.59
-#K= 800951095b297532e25785ab101a2ba9 FT_grammar_errs.60
+#K= 26fd1565f209b383d9f2fbf0b54cd5fc FT_grammar_errs.1
+#K= 200c01632c52a63f6d186da1c6460740 FT_grammar_errs.2
+#K= 7d7141900ce6e32f15c99202309c63a4 FT_grammar_errs.3
+#K= 1bb798a5831d0119789d424ef6cb55c4 FT_grammar_errs.4
+#K= 5edd66e308b2792d5694df86c07a3eaf FT_grammar_errs.5
+#K= 6f87d92ffe0812550f43287127c6f2b9 FT_grammar_errs.6
+#K= c0eb05b58a008c722e091e1ae74440ec FT_grammar_errs.7
+#K= 911929ec0e2ffc1f13822b479dec6805 FT_grammar_errs.8
+#K= 1ac52ce8ba553ec23eb70faa3ffa1197 FT_grammar_errs.9
+#K= c1407512376369d2e591a4b25a4b607a FT_grammar_errs.10
+#K= ea94add1d76d17dbb69c1b86f3aa42b2 FT_grammar_errs.11
+#K= 2046abda72725ea06fe339d5f364f1c9 FT_grammar_errs.12
+#K= b72f7fccf76f8a5bee47a05d7bb545fb FT_grammar_errs.13
+#K= 98e2bd3e4f3da58536496a38ec3e6238 FT_grammar_errs.14
+#K= b371c6ba52503d037dbc43da788af8be FT_grammar_errs.15
+#K= cb8288d607b0c5282125852f3ab05107 FT_grammar_errs.16
+#K= c2a8d0401e4cf85ccebedf61c5d0ff4b FT_grammar_errs.17
+#K= cb8288d607b0c5282125852f3ab05107 FT_grammar_errs.18
+#K= b371c6ba52503d037dbc43da788af8be FT_grammar_errs.19
+#K= 98e2bd3e4f3da58536496a38ec3e6238 FT_grammar_errs.20
+#K= 02b210b2646aceb68f3d6d2876a3d57a FT_grammar_errs.21
+#K= 51030cd01ed601a68dd48356902954b1 FT_grammar_errs.22
+#K= af8818de076407d4e7f4e384ba110ac5 FT_grammar_errs.23
+#K= 023ba04ffced833b4776fb4fcaae7755 FT_grammar_errs.24
+#K= 0a082bb9d50f9a6257c3be5938758150 FT_grammar_errs.25
+#K= 3b956344b2338de9dd0625391b41ed35 FT_grammar_errs.26
+#K= 97779a5b22bb43912268caca0dc391d8 FT_grammar_errs.27
+#K= c02a669a8b76e15f0dcced9c4aacc5da FT_grammar_errs.28
+#K= 89822eac51e11b55c50c4e72a1203452 FT_grammar_errs.29
+#K= 56a65b28955c743f18001d1b423356fb FT_grammar_errs.30
+#K= ff1186fdf1ffe20c89fe38db596e75c2 FT_grammar_errs.31
+#K= 10945c0e8920342903ffeeb0d601babd FT_grammar_errs.32
+#K= 6a333eb2cfbb2c347b8fdfb06a979aa9 FT_grammar_errs.33
+#K= 55dba10e65775dfd1e229ddf0eb2608e FT_grammar_errs.34
+#K= dfa3b6908ea9f4b23005925d95dedd8e FT_grammar_errs.35
+#K= 3cfcc96931e76ce6396da3e27c61a6ef FT_grammar_errs.36
+#K= 04e37fe069eed91515c6a24301378548 FT_grammar_errs.37
+#K= 130bf64b92a5e34d1c4cce98899084e1 FT_grammar_errs.38
+#K= 9681a05658f1a50e3434aa991b5ce992 FT_grammar_errs.39
+#K= 38506317363a188fbb7a417ff50457a9 FT_grammar_errs.40
+#K= 02b210b2646aceb68f3d6d2876a3d57a FT_grammar_errs.41
+#K= 8c08a8b5cacbf885d022360ed856e7a1 FT_grammar_errs.42
+#K= f0f4d894a49bd2c1856cf4f013f83e54 FT_grammar_errs.43
+#K= 25b92d52cb299fa8d84c5584e490bd97 FT_grammar_errs.44
+#K= 0a082bb9d50f9a6257c3be5938758150 FT_grammar_errs.45
+#K= 2a41940f70efa80e39cb3356931e49af FT_grammar_errs.46
+#K= a3cbfcf5e452fb11994fdf41254c6775 FT_grammar_errs.47
+#K= d47387d5885927ac4d33f0675a721963 FT_grammar_errs.48
+#K= 37d2984315284521b084e62feb889527 FT_grammar_errs.49
+#K= 99b7d60f3afb7ab9fb8e14340c30df02 FT_grammar_errs.50
+#K= a16f404c515c40418f43ea1d4d8e6a7b FT_grammar_errs.51
+#K= 424841345d03bcfad704e9cdfce29794 FT_grammar_errs.52
+#K= de2bf9687e8374f566db45d45274c313 FT_grammar_errs.53
+#K= 6d923562c9fc7aaf1ac1c393aa7b55f9 FT_grammar_errs.54
+#K= 704bfc82d4cf8fee52552d33bacfc7df FT_grammar_errs.55
+#K= 426bf966b975ade7ec8c6ccf40463583 FT_grammar_errs.56
+#K= 59a11ff06013a43e7bb6a21f8f55e7b7 FT_grammar_errs.57
+#K= d6fde9bf3500a509fbd9cbf69fedb04f FT_grammar_errs.58
+#K= c6a1064235d93bc17a623216b3817cb8 FT_grammar_errs.59
+#K= 4042bdb2ea75ed254c429324b20c82b8 FT_grammar_errs.60
 #K= 6e8599556a312200fb6d484565b6c52f FT_basic_queries.1
 #K= db17180b59444e5e34a8fc20c40e4530 FT_basic_queries.2
 #K= f7bd56bd407ff255ef2e3b5fb093ae6a FT_basic_queries.3

-- 
2.55.0

