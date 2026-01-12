From: Louis Rannou <louis.rannou@non.se.com>
Date: Mon, 12 Jan 2026 09:29:56 +0100
Subject: [PATCH v2 2/2] wic: extra-partition: introduce variable matching
 sourceparams
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260112-extrafiles-v2-2-67f0f6c37c4e@non.se.com>
References: <20260112-extrafiles-v2-0-67f0f6c37c4e@non.se.com>
In-Reply-To: <20260112-extrafiles-v2-0-67f0f6c37c4e@non.se.com>
To: openembedded-core@lists.openembedded.org
Cc: Louis Rannou <louis.rannou@non.se.com>, pierre-loup.gosse@smile.fr
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768206597; l=6450;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=SQjm33RgN6E2NmCdxnO305mzyXqbJx5D67PfcmCTlDg=;
 b=Ji17YSuNUq+UhqWoJh6h9GT8lwkchPEbYsR0MrS66K4kBWfERdfyxBvPjt2KP8ZZ3saWDzT5D
 SWxGZUikx7bCJbVbTrXOgDXg4NnQffvnYXuOdGCSdO5czKkmVywyIxq
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The current extra_partition plugin uses predictable variable names (the
configuration must predict the image partition label or uuid). This has two
inconveniences:

- an extra partition that has a specific label (or uuid) is doomed with the
  associated variable. The partition cannot be configured unless the label
  (or uuid) is changed.
- two partitions with same label from distincts .wks cannot have different
  content.

This allows the new suffix _name_%s to be appended to
IMAGE_EXTRA_PARTITION_FILES. This variable will be preferred whenever the
.wks specifies a name in the --sourceparams option.

For example:
  an image may define:
    IMAGE_EXTRA_PARTITION_FILES_name_foo = "bar.conf"
  and the .wks line have line:
    part --source extra_partition --sourceparams "name=foo"

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
 meta/lib/oeqa/selftest/cases/wic.py               | 16 ++++++++++-----
 scripts/lib/wic/plugins/source/extra_partition.py | 24 +++++++++++++++++------
 2 files changed, 29 insertions(+), 11 deletions(-)

diff --git a/meta/lib/oeqa/selftest/cases/wic.py b/meta/lib/oeqa/selftest/cases/wic.py
index 55fb8dfd1b..409437a5c0 100644
--- a/meta/lib/oeqa/selftest/cases/wic.py
+++ b/meta/lib/oeqa/selftest/cases/wic.py
@@ -1657,6 +1657,7 @@ INITRAMFS_IMAGE = "core-image-initramfs-boot"
     def test_extra_partition_plugin(self):
         """Test extra partition plugin"""
         config = dedent("""\
+        IMAGE_EXTRA_PARTITION_FILES_name-foo = "bar.conf"
         IMAGE_EXTRA_PARTITION_FILES_label-foo = "bar.conf;foo.conf"
         IMAGE_EXTRA_PARTITION_FILES_uuid-e7d0824e-cda3-4bed-9f54-9ef5312d105d = "bar.conf;foobar.conf bar2.conf;foobar2.conf bar3.conf bar4.conf"
         IMAGE_EXTRA_PARTITION_FILES = "foo/*"
@@ -1688,9 +1689,13 @@ INITRAMFS_IMAGE = "core-image-initramfs-boot"
 
         try:
             with NamedTemporaryFile("w", suffix=".wks") as wks:
-                wks.writelines(['part / --source extra_partition --ondisk sda --label foo --align 4 --size 5M\n',
-                                'part / --source extra_partition --ondisk sda --fstype=vfat --uuid e7d0824e-cda3-4bed-9f54-9ef5312d105d --align 4 --size 5M\n',
-                                'part / --source extra_partition --ondisk sda --fstype=ext4 --label bar --align 4 --size 5M\n'])
+                wks.writelines([
+                    'part / --source extra_partition --ondisk sda --sourceparams "name=foo" --align 4 --size 5M\n',
+                    'part / --source extra_partition --ondisk sda --label foo --align 4 --size 5M\n',
+                    'part / --source extra_partition --ondisk sda --fstype=vfat --uuid e7d0824e-cda3-4bed-9f54-9ef5312d105d --align 4 --size 5M\n',
+                    'part / --source extra_partition --ondisk sda --fstype=ext4 --label bar --align 4 --size 5M\n',
+                    'bootloader --ptable gpt\n',
+                ])
                 wks.flush()
                 _, wicimg = self._get_wic(wks.name)
 
@@ -1698,14 +1703,15 @@ INITRAMFS_IMAGE = "core-image-initramfs-boot"
             partls = result.output.split('\n')[1:]
 
             # Assert the number of partitions is correct
-            self.assertEqual(3, len(partls), msg="Expect 3 partitions, not %s" % result.output)
+            self.assertEqual(4, len(partls), msg="Expect 4 partitions, not %s" % result.output)
 
             # Fstype column from 'wic ls' should be fstype as given in the part command
-            for part_id, part_fs in enumerate(["fat16", "fat16", "ext4"]):
+            for part_id, part_fs in enumerate(["fat16", "fat16", "fat16", "ext4"]):
                 self.assertIn(part_fs, partls[part_id])
 
             # For each partition, assert expected files exist
             for part, part_glob in enumerate([
+                ["bar.conf"],
                 ["foo.conf"],
                 ["foobar.conf", "foobar2.conf", "bar3.conf", "bar4.conf"],
                 ["bar.conf", "bar2.conf"],
diff --git a/scripts/lib/wic/plugins/source/extra_partition.py b/scripts/lib/wic/plugins/source/extra_partition.py
index d370b0107e..0d49e2bc7c 100644
--- a/scripts/lib/wic/plugins/source/extra_partition.py
+++ b/scripts/lib/wic/plugins/source/extra_partition.py
@@ -18,15 +18,17 @@ class ExtraPartitionPlugin(SourcePlugin):
     The plugin supports:
     - Glob pattern matching for file selection.
     - File renaming.
-    - Suffixes to specify the target partition (by label, UUID, or partname),
-      enabling multiple extra partitions to coexist.
+    - Suffixes to specify the target partition (by params-name, label, UUID,
+      or partname), enabling multiple extra partitions to coexist.
 
     For example:
 
+        IMAGE_EXTRA_PARTITION_FILES_name-randomname = "bar.conf;foo.conf"
         IMAGE_EXTRA_PARTITION_FILES_label-foo = "bar.conf;foo.conf"
         IMAGE_EXTRA_PARTITION_FILES_uuid-e7d0824e-cda3-4bed-9f54-9ef5312d105d = "bar.conf;foobar.conf"
         IMAGE_EXTRA_PARTITION_FILES = "foo/*"
         WICVARS:append = "\
+            IMAGE_EXTRA_PARTITION_FILES_name-randomname \
             IMAGE_EXTRA_PARTITION_FILES_label-foo \
             IMAGE_EXTRA_PARTITION_FILES_uuid-e7d0824e-cda3-4bed-9f54-9ef5312d105d \
         "
@@ -53,11 +55,21 @@ class ExtraPartitionPlugin(SourcePlugin):
                 raise WicError("Couldn't find DEPLOY_DIR_IMAGE, exiting")
 
         extra_files = None
-        for (fmt, id) in (("_uuid-%s", part.uuid), ("_label-%s", part.label), ("_part-name-%s", part.part_name), (None, None)):
-            if fmt:
-                var = fmt % id
-            else:
+        for (fmt, part_id) in (
+                ("_name-%s", source_params.get("name")),
+                ("_uuid-%s", part.uuid),
+                ("_label-%s", part.label),
+                ("_part-name-%s", part.part_name),
+                (None, None)
+        ):
+            if fmt is None:
                 var = ""
+            elif part_id is not None:
+                var = fmt % part_id
+            else:
+                continue
+
+            logger.debug("Looking for extra files in %s" % cls.image_extra_partition_files_var_name + var)
             extra_files = get_bitbake_var(cls.image_extra_partition_files_var_name + var)
             if extra_files is not None:
                 break

-- 
2.43.0

