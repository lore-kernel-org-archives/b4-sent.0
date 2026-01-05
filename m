From: Louis Rannou <louis.rannou@non.se.com>
Date: Mon, 05 Jan 2026 11:49:27 +0100
Subject: [PATCH 2/4] oeqa/selftests: fitimage: prepare for split
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-fitimage-v1-2-e319258c4c4f@non.se.com>
References: <20260105-fitimage-v1-0-e319258c4c4f@non.se.com>
In-Reply-To: <20260105-fitimage-v1-0-e319258c4c4f@non.se.com>
To: openembedded-core@lists.openembedded.org
Cc: Louis Rannou <louis.rannou@non.se.com>, adrian.freihofer@siemens.com, 
 pascal.eberhard@se.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767610172; l=26816;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=o6lGOXHG5lkrkLhSrZat0NJn19RgBgEztckY4ph8dWQ=;
 b=h0BSMUTqaVeWZP46iVytPWoe35yxbSDOEkwuIx8SfsEhGWfDc450zqFl2HvYVFO84LzUzTmt7
 +YL95SSmz4zBnxSrQyfNVy3cZ/5q1+LYlmlhs4lPd1vTr2I0dZ0pmBB
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change subfunctions to become generic and not depends on the unittest
library. Thos functions will be moved in a dedicated library.

- split _bitbake_fit_image into the bitbake call and a generic
  _get_fit_image function
- remove asserts from generic functions
- move descriptions to better describe generic functions

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
 meta/lib/oeqa/selftest/cases/fitimage.py | 260 +++++++++++++++++++++++--------
 1 file changed, 198 insertions(+), 62 deletions(-)

diff --git a/meta/lib/oeqa/selftest/cases/fitimage.py b/meta/lib/oeqa/selftest/cases/fitimage.py
index 008687f9d1..214ed4d512 100644
--- a/meta/lib/oeqa/selftest/cases/fitimage.py
+++ b/meta/lib/oeqa/selftest/cases/fitimage.py
@@ -44,19 +44,10 @@ class FitImageTestCase(OESelftestTestCase):
         self._bitbake_fit_image()
 
         # Check if the its file contains the expected paths and attributes.
-        # The _get_req_* functions are implemented by more specific chield classes.
-        self._check_its_file()
-            req_its_paths, not_req_its_paths = self._get_req_its_paths()
-            req_sigvalues_config = self._get_req_sigvalues_config()
-            req_sigvalues_image = self._get_req_sigvalues_image()
-            # Compare the its file against req_its_paths, not_req_its_paths,
-            #                              req_sigvalues_config, req_sigvalues_image
+        assert True: self._check_its_file()
 
         # Call the dumpimage utiliy and check that it prints all the expected paths and attributes
-        # The _get_req_* functions are implemented by more specific chield classes.
-        self._check_fitimage()
-            self._get_req_sections()
-            # Compare the output of the dumpimage utility against
+        assert True: self._check_fitimage()
     """
 
     MKIMAGE_HASH_LENGTHS = { 'sha256': 64, 'sha384': 96, 'sha512': 128 }
@@ -133,7 +124,11 @@ class FitImageTestCase(OESelftestTestCase):
             cmd += ' -c %s' % conf_name
         result = runCmd(cmd)
         self.logger.debug("%s\nreturned: %s\n%s", cmd, str(result.status), result.output)
-        self.assertIn("Signature check OK", result.output)
+        if "Signature check OK" not in result.output:
+            self.logger.error("'Signature verification failed (%s)' % result.output")
+            return False
+
+        return True
 
     def _verify_dtb_property(self, dtc_bindir, dtb_path, node_path, property_name, req_property, absent=False):
         """Verify device tree properties
@@ -145,11 +140,17 @@ class FitImageTestCase(OESelftestTestCase):
         if absent:
             result = runCmd(cmd, ignore_status=True)
             self.logger.debug("%s\nreturned: %s\n%s", cmd, str(result.status), result.output)
-            self.assertIn("FDT_ERR_NOTFOUND", result.output)
+            if "FDT_ERR_NOTFOUND" not in result.output:
+                self.logger.error('FDT_ERR_NOTFOUND is missing in device tree %s', dtb_path)
+                return False
         else:
             result = runCmd(cmd)
             self.logger.debug("%s\nreturned: %s\n%s", cmd, str(result.status), result.output)
-            self.assertEqual(req_property, result.output.strip())
+            if req_property != result.output.strip():
+                self.logger.error('Property is not as expected: %s (%s != %s)' % (property_name, req_property, result.output.strip()))
+                return False
+
+        return True
 
     @staticmethod
     def _find_string_in_bin_file(file_path, search_string):
@@ -214,20 +215,49 @@ class FitImageTestCase(OESelftestTestCase):
             req_dict (dict): The dictionary containing the required key-value pairs.
         """
         for key, value in req_dict.items():
-            self.assertIn(key, found_dict)
+            if key not in found_dict:
+                self.logger.error('Key not in expected dictionary: %s' % key)
+                return False
             if isinstance(value, dict):
-                self._is_req_dict_in_dict(found_dict[key], value)
+                if not self._is_req_dict_in_dict(found_dict[key], value):
+                    return False
             elif isinstance(value, str):
-                self.assertIn(value, found_dict[key])
+                if not (value in found_dict[key]):
+                    self.logger.error(
+                        'Value is not in expected dictionary[%s]: %s' % (key, value)
+                    )
+                    return False
             elif isinstance(value, list):
-                self.assertLessEqual(set(value), set(found_dict[key]))
+                if not (set(value) <= set(found_dict[key])):
+                    self.logger.error(
+                        'List is not part of expected dictionary[%s]: %s' % (key, str(value))
+                    )
+                    return False
             elif isinstance(value, set):
-                self.assertLessEqual(value, found_dict[key])
+                if not (value <= found_dict[key]):
+                    self.logger.error(
+                        'Set is not part of expected dictionary[%s]: %s' % (key, str(value))
+                    )
+                    return False
             else:
-                self.assertEqual(value, found_dict[key])
+                if (value != found_dict[key]):
+                    self.logger.error(
+                        'Value is not equal in expected dictionary[%s]: %s := %s' % (key, str(value), str(found_dict[key]))
+                    )
+                    return False
+
+        return True
 
     def _check_its_file(self, bb_vars, its_file_path):
-        """Check if the its file contains the expected sections and fields"""
+        """Check if the its file contains the expected sections and fields
+
+        # The _get_req_* functions are implemented by more specific child classes.
+            req_its_paths, not_req_its_paths = self._get_req_its_paths()
+            req_sigvalues_config = self._get_req_sigvalues_config()
+            req_sigvalues_image = self._get_req_sigvalues_image()
+            # Compare the its file against req_its_paths, not_req_its_paths,
+            #                              req_sigvalues_config, req_sigvalues_image
+        """
         # print the its file for debugging
         if logging.DEBUG >= self.logger.level:
             with open(its_file_path) as its_file:
@@ -266,7 +296,10 @@ class FitImageTestCase(OESelftestTestCase):
                     if not itsdotpath in sigs:
                         sigs[itsdotpath] = {}
                     if not '=' in line or not line.endswith(';'):
-                        self.fail('Unexpected formatting in %s sigs section line %d:%s' % (its_file_path, linect, line))
+                        self.logger.error(
+                            'Unexpected formatting in %s sigs section line %d:%s' % (its_file_path, linect, line)
+                        )
+                        return False
                     key, value = line.split('=', 1)
                     sigs[itsdotpath][key.rstrip()] = value.lstrip().rstrip(';')
 
@@ -274,12 +307,18 @@ class FitImageTestCase(OESelftestTestCase):
         self.logger.debug("itspaths:\n%s\n" % pprint.pformat(its_paths, indent=4))
         for req_path in req_its_paths:
             if not req_path in its_paths:
-                self.fail('Missing path in its file: %s (%s)' % (req_path, its_file_path))
+                self.logger.error(
+                    'Missing path in its file: %s (%s)' % (req_path, its_file_path)
+                )
+                return False
 
         # check if all not expected paths are absent in the its file
         for not_req_path in not_req_its_paths:
             if not_req_path in its_paths:
-                self.fail('Unexpected path found in its file: %s (%s)' % (not_req_path, its_file_path))
+                self.logger.error(
+                    'Unexpected path found in its file: %s (%s)' % (not_req_path, its_file_path)
+                )
+                return False
 
         # Check if all the expected singnature nodes (images and configurations) are found
         self.logger.debug("sigs:\n%s\n" % pprint.pformat(sigs, indent=4))
@@ -292,8 +331,11 @@ class FitImageTestCase(OESelftestTestCase):
                 for reqkey, reqvalue in reqsigvalues.items():
                     value = values.get(reqkey, None)
                     if value is None:
-                        self.fail('Missing key "%s" in its file signature section %s (%s)' % (reqkey, its_path, its_file_path))
-                    self.assertEqual(value, reqvalue)
+                        self.logger.error('Missing key "%s" in its file signature section %s (%s)' % (reqkey, its_path, its_file_path))
+                        return False
+                    if value != reqvalue:
+                        self.logger.error('Wrong value  for key "%s" in its file signature section %s (%s) (%s != %s)' % (reqkey, its_path, its_file_path, value, reqvalue))
+                        return False
 
         # Generate a list of expected fields in the its file
         req_its_fields = self._get_req_its_fields(bb_vars)
@@ -312,12 +354,22 @@ class FitImageTestCase(OESelftestTestCase):
                         else:
                             found_all = True
                             break
-            self.assertTrue(found_all,
-                "Fields in Image Tree Source File %s did not match, error in finding %s"
-                % (its_file_path, req_its_fields[field_index]))
+            if not found_all:
+                self.logger.error(
+                    "Fields in Image Tree Source File %s did not match, error in finding %s"
+                    % (its_file_path, req_its_fields[field_index])
+                )
+                return False
+
+        return True
 
     def _check_fitimage(self, bb_vars, fitimage_path, uboot_tools_bindir):
-        """Run dumpimage on the final FIT image and parse the output into a dict"""
+        """Run dumpimage on the final FIT image and parse the output into a dict
+
+        # The _get_req_* functions are implemented by more specific chield classes.
+            self._get_req_sections()
+            # Compare the output of the dumpimage utility against
+        """
         dumpimage_path = os.path.join(uboot_tools_bindir, 'dumpimage')
         cmd = '%s -l %s' % (dumpimage_path, fitimage_path)
         self.logger.debug("Analyzing output from dumpimage: %s" % cmd)
@@ -352,10 +404,14 @@ class FitImageTestCase(OESelftestTestCase):
         req_sections, num_signatures = self._get_req_sections(bb_vars)
         self.logger.debug("req_sections: \n%s\n" % pprint.pformat(req_sections, indent=4))
         self.logger.debug("dumpimage sections: \n%s\n" % pprint.pformat(sections, indent=4))
-        self._is_req_dict_in_dict(sections, req_sections)
+        if not self._is_req_dict_in_dict(sections, req_sections):
+            self.logger.error(
+                "The requested dictionary is not a subset of the parsed dictionary"
+            )
+            return False
 
         # Call the signing related checks if the function is provided by a inherited class
-        self._check_signing(bb_vars, sections, num_signatures, uboot_tools_bindir, fitimage_path)
+        return self._check_signing(bb_vars, sections, num_signatures, uboot_tools_bindir, fitimage_path)
 
     def _get_req_its_paths(self, bb_vars):
         self.logger.error("This function needs to be implemented")
@@ -379,11 +435,18 @@ class FitImageTestCase(OESelftestTestCase):
 
     def _check_signing(self, bb_vars, sections, num_signatures, uboot_tools_bindir, fitimage_path):
         """Verify the signatures in the FIT image."""
-        self.fail("Function needs to be implemented by inheriting classes")
+        self.logger.error("Function needs to be implemented by inheriting classes")
+        return False
 
     def _bitbake_fit_image(self, bb_vars):
         """Bitbake the FIT image and return the paths to the its file and the FIT image"""
-        self.fail("Function needs to be implemented by inheriting classes")
+        self.logger.error("Function needs to be implemented by inheriting classes")
+        return False
+
+    def _get_fit_image(self, bb_vars):
+        """Return the paths to the its file and the FIT image"""
+        self.logger.error("Function needs to be implemented by inheriting classes")
+        return False
 
     def _test_fitimage(self, bb_vars):
         """Check if the its file and the FIT image are created and signed correctly"""
@@ -392,13 +455,15 @@ class FitImageTestCase(OESelftestTestCase):
         self.assertExists(fitimage_path, "%s FIT image doesn't exist" % (fitimage_path))
 
         self.logger.debug("Checking its: %s" % fitimage_its_path)
-        self._check_its_file(bb_vars, fitimage_its_path)
+        self.assertTrue(self._check_its_file(bb_vars, fitimage_its_path))
 
         # Setup u-boot-tools-native
         uboot_tools_bindir = FitImageTestCase._setup_native('u-boot-tools-native')
 
         # Verify the FIT image
-        self._check_fitimage(bb_vars, fitimage_path, uboot_tools_bindir)
+        self.assertTrue(
+            self._check_fitimage(bb_vars, fitimage_path, uboot_tools_bindir)
+        )
 
 class KernelFitImageBase(FitImageTestCase):
     """Test cases for the linux-yocto-fitimage recipe"""
@@ -478,6 +543,13 @@ class KernelFitImageBase(FitImageTestCase):
         """Bitbake the kernel and return the paths to the its file and the FIT image"""
         bitbake(self.kernel_recipe)
 
+        fitimage_its_path, fitimage_path = self._get_fit_image(bb_vars)
+        if fitimage_its_path is None or fitimage_path is None:
+            self.fail('Unable to find FIT image')
+        return (fitimage_its_path, fitimage_path)
+
+    def _get_fit_image(self, bb_vars):
+        """Return the paths to the its file and the FIT image"""
         # Find the right its file and the final fitImage and check if both files are available
         deploy_dir_image = bb_vars['DEPLOY_DIR_IMAGE']
         initramfs_image = bb_vars['INITRAMFS_IMAGE']
@@ -494,7 +566,10 @@ class KernelFitImageBase(FitImageTestCase):
             fitimage_its_name = "fitImage-its-%s-%s" % (initramfs_image_name, kernel_fit_link_name)
             fitimage_name = "fitImage"  # or fitImage-${KERNEL_IMAGE_LINK_NAME}${KERNEL_IMAGE_BIN_EXT}
         else:
-            self.fail('Invalid configuration: INITRAMFS_IMAGE_BUNDLE = "1" and not INITRAMFS_IMAGE')
+            self.logger.error(
+                'Invalid configuration: INITRAMFS_IMAGE_BUNDLE = "1" and not INITRAMFS_IMAGE'
+            )
+            return (None, None)
         kernel_deploysubdir = bb_vars['KERNEL_DEPLOYSUBDIR']
         if kernel_deploysubdir:
             fitimage_its_path = os.path.realpath(os.path.join(deploy_dir_image, kernel_deploysubdir, fitimage_its_name))
@@ -722,7 +797,7 @@ class KernelFitImageBase(FitImageTestCase):
             self.logger.debug("Verifying signatures in the FIT image")
         else:
             self.logger.debug("FIT image is not signed. Signature verification is not needed.")
-            return
+            return True
 
         fit_hash_alg = bb_vars['FIT_HASH_ALG']
         fit_sign_alg = bb_vars['FIT_SIGN_ALG']
@@ -738,9 +813,17 @@ class KernelFitImageBase(FitImageTestCase):
             if section.startswith(bb_vars['FIT_CONF_PREFIX']):
                 sign_algo = values.get('Sign algo', None)
                 req_sign_algo = "%s,%s:%s" % (fit_hash_alg, fit_sign_alg, uboot_sign_keyname)
-                self.assertEqual(sign_algo, req_sign_algo, 'Signature algorithm for %s not expected value' % section)
+                if sign_algo != req_sign_algo:
+                    self.logger.error(
+                        'Signature algorithm for %s not expected value' % section
+                    )
+                    return False
                 sign_value = values.get('Sign value', None)
-                self.assertEqual(len(sign_value), fit_sign_alg_len, 'Signature value for section %s not expected length' % section)
+                if len(sign_value) != fit_sign_alg_len:
+                    self.logger.error(
+                        'Signature value for section %s not expected length' % section
+                    )
+                    return False
                 dtb_file_name = section.replace(bb_vars['FIT_CONF_PREFIX'], '')
                 dtb_path = os.path.join(deploy_dir_image, dtb_file_name)
                 if kernel_deploysubdir:
@@ -749,20 +832,39 @@ class KernelFitImageBase(FitImageTestCase):
                 dtb_path_ext = os.path.join(deploy_dir_image, "devicetree", dtb_file_name)
                 if os.path.exists(dtb_path_ext):
                     dtb_path = dtb_path_ext
-                self._verify_fit_image_signature(uboot_tools_bindir, fitimage_path, dtb_path, section)
+                if not (
+                    self._verify_fit_image_signature(uboot_tools_bindir, fitimage_path, dtb_path, section)
+                ):
+                    self.logger.error(
+                        'FIT image signature is not verified'
+                    )
+                    return False
             else:
                 # Image nodes always need a hash which gets indirectly signed by the config signature
                 hash_algo = values.get('Hash algo', None)
-                self.assertEqual(hash_algo, fit_hash_alg)
+                if hash_algo != fit_hash_alg:
+                    return False
                 hash_value = values.get('Hash value', None)
-                self.assertEqual(len(hash_value), fit_hash_alg_len, 'Hash value for section %s not expected length' % section)
+                if len(hash_value) != fit_hash_alg_len:
+                    self.logger.error(
+                        'Hash value for section %s not expected length' % section
+                    )
+                    return False
                 # Optionally, if FIT_SIGN_INDIVIDUAL = 1 also the image nodes have a signature (which is redundant but possible)
                 if fit_sign_individual == "1":
                     sign_algo = values.get('Sign algo', None)
                     req_sign_algo = "%s,%s:%s" % (fit_hash_alg, fit_sign_alg, uboot_sign_img_keyname)
-                    self.assertEqual(sign_algo, req_sign_algo, 'Signature algorithm for %s not expected value' % section)
+                    if sign_algo != req_sign_algo:
+                        self.logger.error(
+                            'Signature algorithm for %s not expected value' % section
+                        )
+                        return False
                     sign_value = values.get('Sign value', None)
-                    self.assertEqual(len(sign_value), fit_sign_alg_len, 'Signature value for section %s not expected length' % section)
+                    if len(sign_value) != fit_sign_alg_len:
+                       self.logger.error(
+                           'Signature value for section %s not expected length' % section
+                       )
+                       return False
 
         # Search for the string passed to mkimage in each signed section of the FIT image.
         # Looks like mkimage supports to add a comment but does not support to read it back.
@@ -770,8 +872,14 @@ class KernelFitImageBase(FitImageTestCase):
         self.logger.debug("a_comment: %s" % a_comment)
         if a_comment:
             found_comments = FitImageTestCase._find_string_in_bin_file(fitimage_path, a_comment)
-            self.assertEqual(found_comments, num_signatures, "Expected %d signed and commented (%s) sections in the fitImage." %
-                             (num_signatures, a_comment))
+            if found_comments != num_signatures:
+                self.logger.error(
+                    "Expected %d signed and commented (%s) sections in the fitImage." %
+                    (num_signatures, a_comment)
+                )
+                return False
+
+        return True
 
 class KernelFitImageRecipeTests(KernelFitImageBase):
     """Test cases for the kernel-fitimage bbclass"""
@@ -1150,7 +1258,7 @@ class FitImagePyTests(KernelFitImageBase):
 
         self.assertExists(fitimage_its_path, "%s image tree source doesn't exist" % (fitimage_its_path))
         self.logger.debug("Checking its: %s" % fitimage_its_path)
-        self._check_its_file(bb_vars, fitimage_its_path)
+        self.assertTrue(self._check_its_file(bb_vars, fitimage_its_path))
 
     def test_fitimage_py_default(self):
         self._test_fitimage_py()
@@ -1217,6 +1325,13 @@ class UBootFitImageTests(FitImageTestCase):
         """Bitbake the bootloader and return the paths to the its file and the FIT image"""
         bitbake(UBootFitImageTests.BOOTLOADER_RECIPE)
 
+        fitimage_its_path, fitimage_path = self._get_fit_image(bb_vars)
+        if fitimage_its_path is None or fitimage_path is None:
+            self.fail('Unable to find FIT image')
+        return (fitimage_its_path, fitimage_path)
+
+    def _get_fit_image(self, bb_vars):
+        """Return the paths to the its file and the FIT image"""
         deploy_dir_image = bb_vars['DEPLOY_DIR_IMAGE']
         machine = bb_vars['MACHINE']
         fitimage_its_path = os.path.join(deploy_dir_image, "u-boot-its-%s" % machine)
@@ -1364,12 +1479,12 @@ class UBootFitImageTests(FitImageTestCase):
             self.logger.debug("Verifying signatures in the FIT image")
         else:
             self.logger.debug("FIT image is not signed. Signature verification is not needed.")
-            return
+            return True
 
         uboot_fit_hash_alg = bb_vars['UBOOT_FIT_HASH_ALG']
         uboot_fit_sign_alg = bb_vars['UBOOT_FIT_SIGN_ALG']
         spl_sign_keyname = bb_vars['SPL_SIGN_KEYNAME']
-        fit_sign_alg_len = FitImageTestCase.MKIMAGE_SIGNATURE_LENGTHS[uboot_fit_sign_alg]
+        fit_sign_alg_len = self.MKIMAGE_SIGNATURE_LENGTHS[uboot_fit_sign_alg]
         for section, values in sections.items():
             # Configuration nodes are always signed with UBOOT_SIGN_KEYNAME (if UBOOT_SIGN_ENABLE = "1")
             if section.startswith("conf"):
@@ -1379,18 +1494,28 @@ class UBootFitImageTests(FitImageTestCase):
                 # uboot-sign does not add hash nodes, only image signatures
                 sign_algo = values.get('Sign algo', None)
                 req_sign_algo = "%s,%s:%s" % (uboot_fit_hash_alg, uboot_fit_sign_alg, spl_sign_keyname)
-                self.assertEqual(sign_algo, req_sign_algo, 'Signature algorithm for %s not expected value' % section)
+                if sign_algo != req_sign_algo:
+                    self.logger.error('Signature algorithm for %s not expected value' % section)
+                    return False
                 sign_value = values.get('Sign value', None)
-                self.assertEqual(len(sign_value), fit_sign_alg_len, 'Signature value for section %s not expected length' % section)
+                if len(sign_value) != fit_sign_alg_len:
+                    selg.logger.error('Signature value for section %s not expected length' % section)
+                    return False
 
         # Search for the string passed to mkimage in each signed section of the FIT image.
         # Looks like mkimage supports to add a comment but does not support to read it back.
         a_comment = FitImageTestCase._get_uboot_mkimage_sign_args(bb_vars['SPL_MKIMAGE_SIGN_ARGS'])
         self.logger.debug("a_comment: %s" % a_comment)
         if a_comment:
-            found_comments = FitImageTestCase._find_string_in_bin_file(fitimage_path, a_comment)
-            self.assertEqual(found_comments, num_signatures, "Expected %d signed and commented (%s) sections in the fitImage." %
-                             (num_signatures, a_comment))
+            found_comments = self._find_string_in_bin_file(fitimage_path, a_comment)
+            if found_comments != num_signatures:
+                self.logger.error(
+                    "Expected %d signed and commented (%s) sections in the fitImage." %
+                    (num_signatures, a_comment)
+                )
+                return False
+
+        return True
 
     def _check_kernel_dtb(self, bb_vars):
         """
@@ -1425,16 +1550,27 @@ class UBootFitImageTests(FitImageTestCase):
         if bb_vars['FIT_SIGN_INDIVIDUAL'] == "1":
             uboot_sign_img_keyname = bb_vars['UBOOT_SIGN_IMG_KEYNAME']
             key_dtb_path = "/signature/key-" + uboot_sign_img_keyname
-            self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "required", "image")
-            self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "algo", algo)
-            self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "key-name-hint", uboot_sign_img_keyname)
+            self.assertTrue(
+                self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "required", "image")
+            )
+            self.assertTrue(
+                self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "algo", algo)
+            )
+            self.assertTrue(
+                self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "key-name-hint", uboot_sign_img_keyname)
+            )
 
         uboot_sign_keyname = bb_vars['UBOOT_SIGN_KEYNAME']
         key_dtb_path = "/signature/key-" + uboot_sign_keyname
-        self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "required", "conf")
-        self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "algo", algo)
-        self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "key-name-hint", uboot_sign_keyname)
-
+        self.assertTrue(
+            self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "required", "conf")
+        )
+        self.assertTrue(
+            self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "algo", algo)
+        )
+        self.assertTrue(
+            self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "key-name-hint", uboot_sign_keyname)
+        )
 
     def test_uboot_fit_image(self):
         """

-- 
2.43.0

