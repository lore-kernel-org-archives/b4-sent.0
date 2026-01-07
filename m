From: Louis Rannou <louis.rannou@non.se.com>
Date: Wed, 07 Jan 2026 11:40:50 +0100
Subject: [PATCH 1/2] oeqa/selftest: wic: improve extra-partition plugin
 tests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260107-extrafiles-v1-1-a4ddd07df231@non.se.com>
References: <20260107-extrafiles-v1-0-a4ddd07df231@non.se.com>
In-Reply-To: <20260107-extrafiles-v1-0-a4ddd07df231@non.se.com>
To: openembedded-core@lists.openembedded.org
Cc: Louis Rannou <louis.rannou@non.se.com>, pierre-loup.gosse@smile.fr
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767782471; l=5257;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=TXFcnKkeJtla53OEj3/yR9MX04AZNof2m0CxbS1o3Q0=;
 b=CRpFu7C29cye0qzvKJqSqv+xeFdvypl9FUBpEPrrnsPUf2uqONLACuM7mLqVnExt8a2m8yy+F
 1EotONqtJKMCQHlWlYCLbCEiJnP5xthWlHy6gbQsn+mZaV7mA7fyZC4
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Increase the number of inputs to check several files can be copied. Change
the partition type to GPT in order to avoid logical partitions.

Test various file systems and check the wic image partitions match.

Simplify 'wic ls' commands (remove pipes) and use '-n' to specify wic-tools
sysroot and avoid host contamination.

Also dedent the code just after the wic image is built to close the .wks
temporary file when its goal is achieved.

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
 meta/lib/oeqa/selftest/cases/wic.py | 47 +++++++++++++++++++++++++------------
 1 file changed, 32 insertions(+), 15 deletions(-)

diff --git a/meta/lib/oeqa/selftest/cases/wic.py b/meta/lib/oeqa/selftest/cases/wic.py
index d7a9b14658..55fb8dfd1b 100644
--- a/meta/lib/oeqa/selftest/cases/wic.py
+++ b/meta/lib/oeqa/selftest/cases/wic.py
@@ -1658,7 +1658,7 @@ INITRAMFS_IMAGE = "core-image-initramfs-boot"
         """Test extra partition plugin"""
         config = dedent("""\
         IMAGE_EXTRA_PARTITION_FILES_label-foo = "bar.conf;foo.conf"
-        IMAGE_EXTRA_PARTITION_FILES_uuid-e7d0824e-cda3-4bed-9f54-9ef5312d105d = "bar.conf;foobar.conf"
+        IMAGE_EXTRA_PARTITION_FILES_uuid-e7d0824e-cda3-4bed-9f54-9ef5312d105d = "bar.conf;foobar.conf bar2.conf;foobar2.conf bar3.conf bar4.conf"
         IMAGE_EXTRA_PARTITION_FILES = "foo/*"
         WICVARS:append = "\
             IMAGE_EXTRA_PARTITION_FILES_label-foo \
@@ -1668,36 +1668,53 @@ INITRAMFS_IMAGE = "core-image-initramfs-boot"
         self.append_config(config)
 
         deploy_dir = get_bb_var('DEPLOY_DIR_IMAGE')
+        sysroot = get_bb_var('RECIPE_SYSROOT_NATIVE', 'wic-tools')
 
-        testfile = open(os.path.join(deploy_dir, "bar.conf"), "w")
-        testfile.write("test")
-        testfile.close()
+        # Write test files
+        for testfilename in ["bar.conf", "bar2.conf", "bar3.conf", "bar4.conf"]:
+            testfile = open(os.path.join(deploy_dir, testfilename), "w")
+            testfile.write("test %s" % testfilename)
+            testfile.close()
 
+        # Create directory foo/ and testfiles within
         os.mkdir(os.path.join(deploy_dir, "foo"))
-        testfile = open(os.path.join(deploy_dir, "foo", "bar.conf"), "w")
-        testfile.write("test")
-        testfile.close()
+        for testfilename in ["bar.conf", "bar2.conf"]:
+            testfile = open(os.path.join(deploy_dir, "foo", testfilename), "w")
+            testfile.write("test %s" % testfilename)
+            testfile.close()
 
         oldpath = os.environ['PATH']
         os.environ['PATH'] = get_bb_var("PATH", "wic-tools")
 
         try:
             with NamedTemporaryFile("w", suffix=".wks") as wks:
-                wks.writelines(['part / --source extra_partition --ondisk sda --fstype=ext4 --label foo --align 4 --size 5M\n',
-                                'part / --source extra_partition --ondisk sda --fstype=ext4 --uuid e7d0824e-cda3-4bed-9f54-9ef5312d105d --align 4 --size 5M\n',
+                wks.writelines(['part / --source extra_partition --ondisk sda --label foo --align 4 --size 5M\n',
+                                'part / --source extra_partition --ondisk sda --fstype=vfat --uuid e7d0824e-cda3-4bed-9f54-9ef5312d105d --align 4 --size 5M\n',
                                 'part / --source extra_partition --ondisk sda --fstype=ext4 --label bar --align 4 --size 5M\n'])
                 wks.flush()
                 _, wicimg = self._get_wic(wks.name)
 
-                result = runCmd("wic ls %s | wc -l" % wicimg)
-                self.assertEqual('4', result.output, msg="Expect 3 partitions, not %s" % result.output)
+            result = runCmd("wic ls %s -n %s" % (wicimg, sysroot))
+            partls = result.output.split('\n')[1:]
 
-                for part, file in enumerate(["foo.conf", "foobar.conf", "bar.conf"]):
-                    result = runCmd("wic ls %s:%d | grep -q \"%s\"" % (wicimg, part + 1, file))
-                    self.assertEqual(0, result.status, msg="File '%s' not found in the partition #%d" % (file, part))
+            # Assert the number of partitions is correct
+            self.assertEqual(3, len(partls), msg="Expect 3 partitions, not %s" % result.output)
 
-            self.remove_config(config)
+            # Fstype column from 'wic ls' should be fstype as given in the part command
+            for part_id, part_fs in enumerate(["fat16", "fat16", "ext4"]):
+                self.assertIn(part_fs, partls[part_id])
 
+            # For each partition, assert expected files exist
+            for part, part_glob in enumerate([
+                ["foo.conf"],
+                ["foobar.conf", "foobar2.conf", "bar3.conf", "bar4.conf"],
+                ["bar.conf", "bar2.conf"],
+            ]):
+                for part_file in part_glob:
+                    result = runCmd("wic ls %s:%d/%s -n %s" % (wicimg, part + 1, part_file, sysroot))
+                    self.assertEqual(0, result.status, msg="File '%s' not found in the partition #%d" % (part_file, part))
+
+            self.remove_config(config)
         finally:
             os.environ['PATH'] = oldpath
 

-- 
2.43.0

