From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 23 Sep 2024 14:09:29 +0100
Subject: [PATCH v2 01/16] check_whence.py: use consistent naming
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-misc-fixes-v2-1-397f23443628@gmail.com>
References: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
In-Reply-To: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727096979; l=1740;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=+wYedyIHQdeXvxtfLekWNvAK9v0wDJG46Op9Xb0SWes=;
 b=dCgce6RpbtBHAHJ/deRxJ2XbaOjm3im0BBLiWezYc1OQE/zbnugNah9vm/EHM+qzthK+UThdV
 4H5cRHCgKegCZQtcyM3HI+ugprxY+MCUXBcKb/3hyOEPv6480xhFJtV
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Namely: file(name) and sym(link) ... which were swapped in a few places.
One of which by yours truly :facepalm:

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 check_whence.py | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/check_whence.py b/check_whence.py
index fd74a56a5c5a1fbbc989588626ba1d9bc072d602..c270ee6020083044645353235a94eee0b2497960 100755
--- a/check_whence.py
+++ b/check_whence.py
@@ -99,7 +99,7 @@ def main():
         sys.stderr.write("E: %s listed in WHENCE as File, but is directory\n" % name)
         ret = 1
 
-    for name in set(fw for fw in whence_files if whence_files.count(fw) > 1):
+    for name in set(name for name in whence_files if whence_files.count(name) > 1):
         sys.stderr.write("E: %s listed in WHENCE twice\n" % name)
         ret = 1
 
@@ -107,7 +107,7 @@ def main():
         sys.stderr.write("E: %s listed in WHENCE twice\n" % name)
         ret = 1
 
-    for name in set(link for link in whence_files if os.path.islink(link)):
+    for name in set(file for file in whence_files if os.path.islink(file)):
         sys.stderr.write("E: %s listed in WHENCE as File, but is a symlink\n" % name)
         ret = 1
 
@@ -131,10 +131,10 @@ def main():
                 break
             valid_targets.add(dirname)
 
-    for name, target in sorted(links_list):
+    for link, target in sorted(links_list):
         if target not in valid_targets:
             sys.stderr.write(
-                "E: target %s of link %s in WHENCE" " does not exist\n" % (target, name)
+                "E: target %s of link %s in WHENCE" " does not exist\n" % (target, link)
             )
             ret = 1
 

-- 
2.46.1

