From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 08 May 2026 18:39:04 +0200
Subject: [PATCH 01/10] test: register pytest run as a meson test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-new-mount-fixes-and-tests-v1-1-c67a0893ddbc@bsbernd.com>
References: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
In-Reply-To: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3189; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=Ip+BNFKW42d7N2EI7LkMBi/+hAajKEWWU4YejbhBw/8=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGDL/Ca6WOCaQF1Uq3CcU/LI618Vrru7NXLOP+pYnzRpC5
 pdFu3/rKGVhEONgkBVTZOmS2GM75R+frNrX9ddh5rAygQxh4OIUgIksmcrI0OT83CLo1CE+gUAN
 n1cdVT17P27f31woaMvxNvLMvp+F0xkZDl9+f/zC7gb/ewqrf0bOsFXZsCTLReFd7YyE/W8sG1K
 W8QAA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wire the pytest suite into meson as a single test() so it can be run
via 'meson test -C build' (or 'meson test -C build pytest -v') instead
of having to invoke pytest directly. The same definition works for
both unprivileged and root runs -- invoke 'meson test' as your user,
or 'sudo -E meson test' to exercise the tests that need root (these
detect the uid at runtime via os.geteuid()).

Assisted by Claude/Opus 4.7
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 test/ci-build.sh |  9 ++++++---
 test/meson.build | 23 +++++++++++++++++++----
 2 files changed, 25 insertions(+), 7 deletions(-)

diff --git a/test/ci-build.sh b/test/ci-build.sh
index 799f13b2..727cc8c9 100755
--- a/test/ci-build.sh
+++ b/test/ci-build.sh
@@ -2,7 +2,7 @@
 
 set -e
 
-TEST_CMD="pytest -vv --tb=short --maxfail=1 --log-level=INFO --log-cli-level=INFO test/"
+TEST_CMD="meson test -C . --print-errorlogs"
 SAN="-Db_sanitize=address,undefined"
 
 # not default
@@ -122,8 +122,11 @@ sanitized_build()
     sudo chown root:root util/fusermount3
     sudo chmod 4755 util/fusermount3
 
-    # Test as root and regular user
-    sudo env PATH=$PATH ${TEST_CMD}
+    # Test as root and regular user. Give the root run a distinct
+    # meson log basename so its meson-logs/testlog.* files don't end
+    # up owned by root and block the subsequent user run from writing
+    # them.
+    sudo env PATH=$PATH ${TEST_CMD} --logbase=testlog-root
     # Cleanup temporary files (since they are now owned by root)
     sudo rm -rf test/.pytest_cache/ test/__pycache__
 
diff --git a/test/meson.build b/test/meson.build
index 84333f96..87668d61 100644
--- a/test/meson.build
+++ b/test/meson.build
@@ -41,13 +41,28 @@ td += custom_target('test_scripts', input: test_scripts,
                       command: ['cp', '-fPp',
                                 '@INPUT@', meson.current_build_dir() ])
 
-# Provide something helpful when running 'ninja test'
-
 if meson.is_subproject()
 	test('libfuse is a subproject, skipping tests', executable('wrong_command',
                       'wrong_command.c', install: false,
                        c_args: [ '-DMESON_IS_SUBPROJECT' ]))
 else
-	test('wrong_command', executable('wrong_command', 'wrong_command.c',
-                      install: false))
+	# Run the pytest suite via 'meson test'. The same definition works
+	# both as a regular user and under sudo: invoke 'meson test -C build'
+	# for the unprivileged subset, or 'sudo -E meson test -C build' to
+	# also exercise the tests that require root (they pick the uid up at
+	# runtime via os.geteuid()).
+	pytest = find_program('pytest', required: false)
+	if pytest.found()
+		test('pytest', pytest,
+		     args: ['-vv', '--tb=short', '--maxfail=1',
+		            '--log-level=INFO', '--log-cli-level=INFO',
+		            meson.current_build_dir()],
+		     depends: td,
+		     workdir: meson.project_build_root(),
+		     timeout: 600,
+		     is_parallel: false)
+	else
+		test('pytest not found', executable('wrong_command',
+                              'wrong_command.c', install: false))
+	endif
 endif

-- 
2.53.0

