From: Paul Barker <paul@pbarker.dev>
Date: Fri, 27 Nov 2026 09:35:17 +0000
Subject: [PATCH] Revert "oeqa: selftest: signing: Fix use of gnupg-native
 sysroot"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-revert-v1-1-27e7fff6c17a@pbarker.dev>
X-B4-Tracking: v=1; b=H4sIANROCWsC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyNzXaCi1KISXQsDA0MzQ6NkE4u0RCWg4oKi1LTMCrBB0bEQfnFpUlZ
 qcglIt1JtLQAtfv2+agAAAA==
X-Change-ID: 20261127-revert-8001612c48fa
To: openembedded-core@lists.openembedded.org
Cc: Paul Barker <paul@pbarker.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795772129; l=2588;
 i=paul@pbarker.dev; s=20261127; h=from:subject:message-id;
 bh=21sPu30c4Lw69OmhHcZFv7CMjRjiCodWQi/tO/5H/WA=;
 b=EKKjVqCAaW2cI/BvSEfA//yJuCqiUzBTbLhoV3od5nslk5pQlZ2hvoYdKZe/s5Y3+L/nwOqNY
 x5qA+r/2fPNC086rkaL16t2LDURQMo+zUnHWEyQ2nxAxnY9AKvJ4nUK
X-Developer-Key: i=paul@pbarker.dev; a=ed25519;
 pk=WqW1DI8ojKsslrA2FOhJuBZUdddRnjQP2xjPNaop5PU=
X-Endpoint-Received: by B4 Relay for paul@pbarker.dev/20261127 with auth_id=1665
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This reverts commit 89daeb7edf0bbc76bdde40ba0381ad75d242945f.

We can't use the native_sysroot argument of runCmd() to run gpg here
because we are within a self.create_new_builddir() context block. i.e.
we are in a different build environment to the one where gnupg-native
was built and so its sysroot doesn't exist in this build environment.

Modification of os.environ in a test case should actually be safe, there
are several other test cases which do this.

This should fix [YOCTO #16483].

Signed-off-by: Paul Barker <paul@pbarker.dev>
---
 meta/lib/oeqa/selftest/cases/signing.py | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/meta/lib/oeqa/selftest/cases/signing.py b/meta/lib/oeqa/selftest/cases/signing.py
index 6269536d1d61..e36a5cd0f671 100644
--- a/meta/lib/oeqa/selftest/cases/signing.py
+++ b/meta/lib/oeqa/selftest/cases/signing.py
@@ -37,7 +37,7 @@ class Signing(OESelftestTestCase):
             f.write("auto-expand-secmem\n")
 
         runCmd('gpg --batch --homedir %s --import %s %s' % (self.gpg_dir, self.pub_key_path, self.secret_key_path), native_sysroot=nsysroot)
-        return nsysroot
+        return nsysroot + get_bb_var("bindir_native")
 
 
     @contextmanager
@@ -158,6 +158,7 @@ class Signing(OESelftestTestCase):
 
         with self.create_new_builddir(os.environ['BUILDDIR'], builddir):
 
+            os.environ["PATH"] = nsysroot + ":" + os.environ["PATH"]
             self.add_command_to_tearDown('bitbake -c clean %s' % test_recipe)
             self.add_command_to_tearDown('rm -rf %s' % sstatedir)
             self.add_command_to_tearDown('rm -rf %s' % builddir)
@@ -171,7 +172,7 @@ class Signing(OESelftestTestCase):
             self.assertEqual(len(recipe_sig), 1, 'Failed to find .sig file.')
             self.assertEqual(len(recipe_archive), 1, 'Failed to find .tar.zst file.')
 
-            ret = runCmd('gpg --homedir %s --verify %s %s' % (self.gpg_dir, recipe_sig[0], recipe_archive[0]), native_sysroot=nsysroot)
+            ret = runCmd('gpg --homedir %s --verify %s %s' % (self.gpg_dir, recipe_sig[0], recipe_archive[0]))
             # gpg: Signature made Thu 22 Oct 2015 01:45:09 PM EEST using RSA key ID 61EEFB30
             # gpg: Good signature from "testuser (nocomment) <testuser@email.com>"
             self.assertIn('gpg: Good signature from', ret.output, 'Package signed incorrectly.')

---
base-commit: 39019629a4ad25557f120ec98305a4a2ad6a8558
change-id: 20261127-revert-8001612c48fa

Best regards,
--  
Paul Barker <paul@pbarker.dev>

