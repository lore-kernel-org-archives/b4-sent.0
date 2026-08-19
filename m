From: Jonas Juffinger <jonas.juffinger@liebherr.com>
Date: Wed, 19 Aug 2026 10:26:05 +0200
Subject: [PATCH] kernel-fit-image: Skip sign key check for PKCS #11 URI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260819-bugfix-run_mkimage_sign_pkcs11_support-v1-1-363fbbf2ff66@liebherr.com>
X-B4-Tracking: v=1; b=H4sIAJxohWoC/x2NywqDMBAAf0X2bCCxUB+/IhI0buIixrDblIL47
 w0e5zAzFwgyocBQXcD4JaEzFjB1BW6bY0BFa2FodPPWnenVkoOnn+Ic7bHTMQe0QiHatDsxxkp
 O6eSPevl28eh69J2GEkuMRXtG43Tff+HfXfh4AAAA
To: openembedded-core@lists.openembedded.org
Cc: Jonas Juffinger <jonas.juffinger@liebherr.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787127967; l=2079;
 i=jonas.juffinger@liebherr.com; s=20260615; h=from:subject:message-id;
 bh=64TTPyeT/WKSI9SQsD72c8pXRB7TuV60zpFV/nppFYg=;
 b=ZrD4GUCxg+aPulWcKgEG19Jg+iKRYHuWPQQsGmE13O28678bBVGuXCQ7hCVhZ80rGVX7Ts6YN
 s15w6dX5InFBvwTEXBuxe1G7dHWRM8PN2u4STC78xkGTDQKhPtQgHvJ
X-Developer-Key: i=jonas.juffinger@liebherr.com; a=ed25519;
 pk=57Vzs2aKTP3E7TDrBuZMQibGR+Koattc4oIhiMOs3FI=
X-Endpoint-Received: by B4 Relay for jonas.juffinger@liebherr.com/20260615 with auth_id=821
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The run_mkimage_sign function checks if the required keys exist
in the keydir because mkimage does not return with an error if
the keys do not exist. This check fails if the keydir is a PKCS
 #11 URI.

This patch skips the check if the keydir is a PKCS #11 URI by
checking if it starts with "pkcs11:".

Signed-off-by: Jonas Juffinger <jonas.juffinger@liebherr.com>
---
 meta/lib/oe/fitimage.py | 14 ++++++++------
 1 file changed, 8 insertions(+), 6 deletions(-)

diff --git a/meta/lib/oe/fitimage.py b/meta/lib/oe/fitimage.py
index d4dacdd508..195edbb8e3 100644
--- a/meta/lib/oe/fitimage.py
+++ b/meta/lib/oe/fitimage.py
@@ -601,12 +601,14 @@ class ItsNodeRootKernel(ItsNode):
             bb.debug(1, "FIT image signing is disabled. Skipping signing.")
             return
 
-        # Some sanity checks because mkimage exits with 0 also without needed keys
-        sign_key_path = os.path.join(self._sign_keydir, self._sign_keyname_conf)
-        self._check_sign_key_files(sign_key_path, self._sign_algo)
-        if self._sign_individual:
-            sign_key_img_path = os.path.join(self._sign_keydir, self._sign_keyname_img)
-            self._check_sign_key_files(sign_key_img_path, self._sign_algo)
+        # Some sanity checks because mkimage exits with 0 also without needed keys.
+        # If the keydir is a PKCS#11 URI, skip this check.
+        if not self._sign_keydir.startswith('pkcs11:'):
+            sign_key_path = os.path.join(self._sign_keydir, self._sign_keyname_conf)
+            self._check_sign_key_files(sign_key_path, self._sign_algo)
+            if self._sign_individual:
+                sign_key_img_path = os.path.join(self._sign_keydir, self._sign_keyname_img)
+                self._check_sign_key_files(sign_key_img_path, self._sign_algo)
 
         cmd = [
             self._mkimage_sign,

---
base-commit: 6f7a806ece411ab32e4b1c08a0299400bdf3b588
change-id: 20260819-bugfix-run_mkimage_sign_pkcs11_support-3f7bfec9ef80

Best regards,
-- 
Jonas Juffinger <jonas.juffinger@liebherr.com>

