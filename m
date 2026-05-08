From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 08 May 2026 18:39:06 +0200
Subject: [PATCH 03/10] test: assert ro/rw, nosuid/suid, nodev/dev
 round-trip via fsmount
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-new-mount-fixes-and-tests-v1-3-c67a0893ddbc@bsbernd.com>
References: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
In-Reply-To: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4045; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=eYayxcooayUQkqjXTb586tNpfXL9uNgcP9rvIcKKd8A=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGDL/Ca65EXUt2r8jf4lP87ebG322b1He77FNsq4v+Jf+F
 mZ1b/M1HaUsDGIcDLJiiixdEntsp/zjk1X7uv46zBxWJpAhDFycAjCRpF5Ghk8PYpPnN0Zluitt
 Ygs6sbmv4GRpaZEUu0SKW9scLs1eNkaG2/JrYw6/ELx92uTJhjkR745+zkx7J87xLd8+2ZvlTaI
 5MwA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Assisted by ClaudeOpus 4.7
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 test/test_mount_state.py | 70 ++++++++++++++++++++++++++++++++++++++++++------
 1 file changed, 62 insertions(+), 8 deletions(-)

diff --git a/test/test_mount_state.py b/test/test_mount_state.py
index eacb7326..a7949ec3 100644
--- a/test/test_mount_state.py
+++ b/test/test_mount_state.py
@@ -105,12 +105,66 @@ def test_mountinfo_subtype_fsname(tmpdir, output_checker, name):
         'unexpected source: %r' % info['source']
 
 
-@pytest.mark.parametrize('name', ('hello', 'hello_ll'))
-def test_mountinfo_unprivileged_attrs(tmpdir, output_checker, name):
-    if os.getuid() == 0:
-        pytest.skip('only meaningful for unprivileged mounts via fusermount3')
-    with hello_mount(tmpdir, output_checker, name) as mnt:
-        info = parse_mountinfo(mnt)
+# (label, options, must-be-in mount_options, must-NOT-be-in mount_options)
+#
+# Library defaults are MS_NOSUID|MS_NODEV (lib/mount.c:771,
+# util/fusermount.c:988), so a no-options mount is expected to land
+# with both attrs set. The negation forms (suid/dev) clear the default
+# flags via lib/mount.c:set_mount_flag(), which on the new mount API
+# path means MOUNT_ATTR_NOSUID/MOUNT_ATTR_NODEV are not set in the
+# fsmount() call. Asserting their absence catches a routing bug where
+# the negation wasn't honored.
+ATTR_CASES = [
+    ('default',  (),          ('rw', 'nosuid', 'nodev'), ('ro',)),
+    ('ro',       ('ro',),     ('ro',),                   ('rw',)),
+    ('nosuid',   ('nosuid',), ('nosuid',),               ()),
+    ('nodev',    ('nodev',),  ('nodev',),                ()),
+]
+
+# suid/dev are root-only: the kernel rejects MS_NOSUID/MS_NODEV being
+# cleared for unprivileged mounts, and fusermount3 hard-codes them on
+# anyway (util/fusermount.c:988).
+ATTR_CASES_ROOT = [
+    ('suid',     ('suid',),   (),                        ('nosuid',)),
+    ('dev',      ('dev',),    (),                        ('nodev',)),
+]
+
+
+def _check_attrs(info, must_have, must_not_have):
     assert info is not None
-    assert 'nosuid' in info['mount_options']
-    assert 'nodev'  in info['mount_options']
+    for opt in must_have:
+        assert opt in info['mount_options'], \
+            '%r missing from mount_options=%r' % (opt, info['mount_options'])
+    for opt in must_not_have:
+        assert opt not in info['mount_options'], \
+            'unexpected %r in mount_options=%r' % (opt, info['mount_options'])
+
+
+@pytest.mark.parametrize('name', ('hello', 'hello_ll'))
+@pytest.mark.parametrize('label,opts,must_have,must_not_have', ATTR_CASES,
+                         ids=[c[0] for c in ATTR_CASES])
+def test_mountinfo_attrs(tmpdir, output_checker, name,
+                         label, opts, must_have, must_not_have):
+    with hello_mount(tmpdir, output_checker, name, opts) as mnt:
+        info = parse_mountinfo(mnt)
+    _check_attrs(info, must_have, must_not_have)
+    # ro/rw also surface in super_options; if we asked for ro the
+    # superblock must agree. Catches a path that sets MOUNT_ATTR_RDONLY
+    # but forgets the FSCONFIG-side MS_RDONLY (or vice versa).
+    if 'ro' in must_have:
+        assert 'ro' in info['super_options'], \
+            'ro on mount but rw on superblock: super_options=%r' % \
+                info['super_options']
+
+
+@pytest.mark.parametrize('name', ('hello', 'hello_ll'))
+@pytest.mark.parametrize('label,opts,must_have,must_not_have',
+                         ATTR_CASES_ROOT,
+                         ids=[c[0] for c in ATTR_CASES_ROOT])
+def test_mountinfo_attrs_root(tmpdir, output_checker, name,
+                              label, opts, must_have, must_not_have):
+    if os.getuid() != 0:
+        pytest.skip('clearing nosuid/nodev requires root')
+    with hello_mount(tmpdir, output_checker, name, opts) as mnt:
+        info = parse_mountinfo(mnt)
+    _check_attrs(info, must_have, must_not_have)

-- 
2.53.0

