From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:51:35 +0000
Subject: [PATCH v2 10/16] check_whence: error if symlinks are in-tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-10-6061ab1a0483@gmail.com>
References: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
To: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696718; l=2491;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=TDRX1rTSLi9ZIfkbg2hlz0zLxWY1jhNr+LbgA2nv804=;
 b=X4vOqVB+ddwnBgtSiFnJ1qw6nNFkji1F6rl8zz8o3fij8L2prnhYE+LEexS6sT8URdkRq3IMr
 93l4QzNSV6UC8+K+/rzhpe4Li9M47XvJv5h9EOQKPsDoIuXIisaU/kb
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently we have no symlinks in-tree. Add a simple check, ensuring they
don't get added in the future.

This allows us to remove the clunky symlink checking code in
copy-firmware.sh

v2:
 - tweak helper to produce link and target (based off Adam's patch)

Cc: Adam Sampson <ats@offog.org>
Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
Adam, you should be able to use this helper with your fixes.

Note that symlinks should not point to another symlink, so you might
want to tweak your patch to check and error out in such cases.

HTH o/
---
 check_whence.py | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/check_whence.py b/check_whence.py
index 92b104e..f94037d 100755
--- a/check_whence.py
+++ b/check_whence.py
@@ -32,6 +32,23 @@ def list_whence_files():
                 yield match.group(1).replace("\ ", " ")
                 continue
 
+def list_links_list():
+    with open('WHENCE', encoding='utf-8') as whence:
+        for line in whence:
+            match = re.match(r'Link:\s*(.*)', line)
+            if match:
+                linkname, target = match.group(1).split("->")
+
+                linkname = linkname.strip().replace("\ ", " ")
+                target = target.strip().replace("\ ", " ")
+
+                # Link target is relative to the link
+                target = os.path.join(os.path.dirname(linkname), target)
+                target = os.path.normpath(target)
+
+                yield (linkname, target)
+                continue
+
 def list_git():
     with os.popen('git ls-files') as git_files:
         for line in git_files:
@@ -41,6 +58,7 @@ def main():
     ret = 0
     whence_list = list(list_whence())
     whence_files = list(list_whence_files())
+    links_list = list(list_links_list())
     known_files = set(name for name in whence_list if not name.endswith('/')) | \
                   set(['check_whence.py', 'configure', 'Makefile',
                        'README', 'copy-firmware.sh', 'WHENCE'])
@@ -61,6 +79,10 @@ def main():
                          name)
         ret = 1
 
+    for name in set(link[0] for link in links_list if os.path.islink(link[0])):
+        sys.stderr.write('E: %s listed in WHENCE as Link, is in tree\n' % name)
+        ret = 1
+
     for name in sorted(list(known_files - git_files)):
         sys.stderr.write('E: %s listed in WHENCE does not exist\n' % name)
         ret = 1

-- 
2.39.2

