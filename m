From: Jonas Juffinger <jonas.juffinger@liebherr.com>
Date: Tue, 08 Sep 2026 16:31:35 +0200
Subject: [PATCH RESEND v2] kernel-fit-image: Don't add hash node when
 signing is enabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-bugfix-dont-add-hash-node-to-signed-fit-images-v2-1-c993a8fcf378@liebherr.com>
To: openembedded-core@lists.openembedded.org
Cc: mathieu.dubois-briand@bootlin.com, 
 Jonas Juffinger <jonas.juffinger@liebherr.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788877902; l=4095;
 i=jonas.juffinger@liebherr.com; s=20260615; h=from:subject:message-id;
 bh=d8k2iVWYy11A4qUEi1AtPL1bOa7UzBC826kPvrcFklM=;
 b=1HRbEB+dUyDsgEyYBE7iL3u/z66l9pUXbzyI0I2UDTW7fxlQn1xEjVA+auIuTByCGa2k90lvl
 zxkwBOoVYDbABZi4YEDkOgZwIPl/kXNYlllYrH3L6ya2v6qEQzXhcv9
X-Developer-Key: i=jonas.juffinger@liebherr.com; a=ed25519;
 pk=57Vzs2aKTP3E7TDrBuZMQibGR+Koattc4oIhiMOs3FI=
X-Endpoint-Received: by B4 Relay for jonas.juffinger@liebherr.com/20260615 with auth_id=821
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When fit image signing is enabled, mkimage does not fill
the configuration hash node even if it is present. This causes
the verification to fail in U-Boot with a "Bad Data Hash" error
because the hash node exists but is empty.

This patch adds a check to only add the configuration hash node
if signing is not enabled and fixes the respective test cases.

The example FIT from the official documentation also shows
the configuration field with only the signature, without the
hash field:
https://docs.u-boot.org/en/latest/usage/fit/signature.html#signed-configurations

To further ensure that this change is valid, I also checked
the U-Boot source for the hash and signature generation code:
https://github.com/u-boot/u-boot/blob/main/tools/image-host.c#L1593
The function fit_config_add_verification_data only adds the
signature and no hash. Compare with fit_image_add_verification_data
which adds both.

Signed-off-by: Jonas Juffinger <jonas.juffinger@liebherr.com>
---
Changes in v2:
- Adjusted test cases
- Link to v1: https://lore.kernel.org/r/20260819-bugfix-dont-add-hash-node-to-signed-fit-images-v1-1-c0ffc1a0fc17@liebherr.com
---
 meta/lib/oe/fitimage.py                  | 2 +-
 meta/lib/oeqa/selftest/cases/fitimage.py | 8 +++++---
 2 files changed, 6 insertions(+), 4 deletions(-)

diff --git a/meta/lib/oe/fitimage.py b/meta/lib/oe/fitimage.py
index d4dacdd508..142a5d60f7 100644
--- a/meta/lib/oe/fitimage.py
+++ b/meta/lib/oe/fitimage.py
@@ -485,7 +485,7 @@ class ItsNodeRootKernel(ItsNode):
             f"{default_flag} {', '.join(conf_desc)}",
             opt_props=opt_props
         )
-        if self._hash_algo:
+        if self._hash_algo and not self._sign_enable:
             ItsNodeHash(
                 "hash-1",
                 conf_node,
diff --git a/meta/lib/oeqa/selftest/cases/fitimage.py b/meta/lib/oeqa/selftest/cases/fitimage.py
index 3d8bdc4a74..6f9e6f30e5 100644
--- a/meta/lib/oeqa/selftest/cases/fitimage.py
+++ b/meta/lib/oeqa/selftest/cases/fitimage.py
@@ -893,9 +893,10 @@ class KernelFitImageBase(FitImageTestCase):
             if uboot_sign_enable == "1" and fit_sign_individual == "1":
                 req_its_paths.append(['/', 'images', image, 'signature-1'])
         for configuration in configurations:
-            req_its_paths.append(['/', 'configurations', configuration, 'hash-1'])
             if uboot_sign_enable == "1":
                 req_its_paths.append(['/', 'configurations', configuration, 'signature-1'])
+            else:
+                req_its_paths.append(['/', 'configurations', configuration, 'hash-1'])
 
         not_req_its_paths = []
         for image in not_images:
@@ -1066,14 +1067,15 @@ class KernelFitImageBase(FitImageTestCase):
         # Add signing related properties if needed
         if uboot_sign_enable == "1":
             for section in req_sections:
-                req_sections[section]['Hash algo'] = fit_hash_alg
                 if section.startswith(bb_vars['FIT_CONF_PREFIX']):
-                    req_sections[section]['Hash value'] = "unavailable"
                     req_sections[section]['Sign algo'] = "%s,%s:%s" % (fit_hash_alg, fit_sign_alg, uboot_sign_keyname)
                     num_signatures += 1
                 elif fit_sign_individual == "1":
+                    req_sections[section]['Hash algo'] = fit_hash_alg
                     req_sections[section]['Sign algo'] = "%s,%s:%s" % (fit_hash_alg, fit_sign_alg, uboot_sign_img_keyname)
                     num_signatures += 1
+                else:
+                    req_sections[section]['Hash algo'] = fit_hash_alg
         return (req_sections, num_signatures)
 
     def _check_signing(self, bb_vars, sections, num_signatures, uboot_tools_bindir, fitimage_path):

---
base-commit: 6f7a806ece411ab32e4b1c08a0299400bdf3b588
change-id: 20260819-bugfix-dont-add-hash-node-to-signed-fit-images-12ab0c9271ce

Best regards,
--
Jonas Juffinger <jonas.juffinger@liebherr.com>
-- 
Jonas Juffinger <jonas.juffinger@liebherr.com>

