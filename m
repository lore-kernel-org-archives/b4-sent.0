From: Jim Cromie <jim.cromie@gmail.com>
Date: Sat, 05 Sep 2026 12:13:57 -0600
Subject: [PATCH v8 43/43] selftests/dynamic_debug: Prime params module with
 +p in FT_comma_terminators
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260905-dd-cmap-part2-clean-v8-43-a4cc0674f6fd@gmail.com>
References: <20260905-dd-cmap-part2-clean-v8-0-a4cc0674f6fd@gmail.com>
In-Reply-To: <20260905-dd-cmap-part2-clean-v8-0-a4cc0674f6fd@gmail.com>
To: Jason Baron <jbaron@akamai.com>, Shuah Khan <shuah@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Arnd Bergmann <arnd@arndb.de>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Aaron Tomlin <atomlin@atomlin.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788632017; l=1753;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=0bPKrMOveW2DXDWbNxuLf+xV+IKUyruuyqM/WCqrbOA=;
 b=E07+vsTmo4Qxkl+wWUBCjQViaHe//qAwFizWF/bRP2M6r3UuVXxEDV45xLfCTCpHJrGh/Y7dM
 wvTr/9OKqgVAzttaPB63yn6gA2rh50JakNdxoZcGOuiN6kVLexwoXhH
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In FT_comma_terminators, ddcmd "module params =_" was executed immediately
before ddcmd "module,params,=_" 'kernel/params.c'. Because flags were
already cleared (=_), the second command produced a zero-length diff,
causing verify_after_change() to fail due to expected fingerprint drift.

Prime params call-sites with +p prior to testing comma delimiters,
ensuring a valid +p -> =_ state transition diff.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index eeb5018d6f82..d581b4e1cc80 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -479,7 +479,7 @@ function FT_comma_terminators {
 	echo "SKIP - test requires params, which is a builtin module"
 	return
     fi
-    ddcmd "module params =_"
+    ddcmd "module params +p"
 
     ddcmd "module,params,=_" 'kernel/params.c'
     ddcmd "module,params,+mf" 'kernel/params.c'
@@ -675,7 +675,7 @@ function GOLDEN_RECORDS {
 #K= bede904b02278e5648bb7a8243be8d98 FT_path_module_queries.2
 #K= 4b902c159d7f08f91377bf0a353e0051 FT_path_module_queries.3
 #K= bede904b02278e5648bb7a8243be8d98 FT_path_module_queries.4
-#K= 68b329da9893e34099c7d8ad5cb9c940 FT_comma_terminators.1
+#K= 3dbf634bbf0364431b3c99f6a294eb14 FT_comma_terminators.1
 #K= 99985cce918eb5108ecb3658249f6bc7 FT_comma_terminators.2
 #K= 68b329da9893e34099c7d8ad5cb9c940 FT_comma_terminators.3
 #K= 85f93d30f4006c99a806639970b92f20 FT_comma_terminators.4

-- 
2.55.0

