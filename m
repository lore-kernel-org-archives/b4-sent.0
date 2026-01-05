From: Louis Rannou <louis.rannou@non.se.com>
Date: Mon, 05 Jan 2026 11:49:28 +0100
Subject: [PATCH 3/4] oeqa: fitimage: split the selftest and create a
 generic library
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-fitimage-v1-3-e319258c4c4f@non.se.com>
References: <20260105-fitimage-v1-0-e319258c4c4f@non.se.com>
In-Reply-To: <20260105-fitimage-v1-0-e319258c4c4f@non.se.com>
To: openembedded-core@lists.openembedded.org
Cc: Louis Rannou <louis.rannou@non.se.com>, adrian.freihofer@siemens.com, 
 pascal.eberhard@se.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767610172; l=97442;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=2eiQO3BdRCgUiqBftdafnp5zDWUfSOshlC9wSY5eNqc=;
 b=1oKGM0V8jTrhHG4RraMxaK+MGWu3Ts2x6S6HzAZLQ/9eaz92kdH/QVenLctJ6N0T9APcuCVjs
 FKBWa6W1a2UBRqPXTOQEn+vdq4u9uL6JNxJcIrXrEGgH/oJzmm6TvEb
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move all the unittest-agnostic functions from fitimage selftest to a
dedicated library in oeqa/utils.

This leaves the selftest unimpacted and allow other types of tests (such as
sanity) to reuse those fitimage parsers and checks.

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
 meta/lib/oeqa/selftest/cases/fitimage.py | 960 ++-----------------------------
 meta/lib/oeqa/utils/fitimage.py          | 883 ++++++++++++++++++++++++++++
 2 files changed, 941 insertions(+), 902 deletions(-)

diff --git a/meta/lib/oeqa/selftest/cases/fitimage.py b/meta/lib/oeqa/selftest/cases/fitimage.py
index 214ed4d512..4a744146d2 100644
--- a/meta/lib/oeqa/selftest/cases/fitimage.py
+++ b/meta/lib/oeqa/selftest/cases/fitimage.py
@@ -5,8 +5,6 @@
 #
 
 import os
-import re
-import shlex
 import logging
 import pprint
 
@@ -14,6 +12,7 @@ import oe.fitimage
 
 from oeqa.selftest.case import OESelftestTestCase
 from oeqa.utils.commands import runCmd, bitbake, get_bb_vars, get_bb_var
+from oeqa.utils.fitimage import FitImageUtils, KernelFitImageUtils, UBootFitImageUtils
 
 
 class BbVarsMockGenKeys:
@@ -44,15 +43,12 @@ class FitImageTestCase(OESelftestTestCase):
         self._bitbake_fit_image()
 
         # Check if the its file contains the expected paths and attributes.
-        assert True: self._check_its_file()
+        assert True: FitImageUtils._check_its_file()
 
         # Call the dumpimage utiliy and check that it prints all the expected paths and attributes
-        assert True: self._check_fitimage()
+        assert True: FitImageUtils._check_fitimage()
     """
 
-    MKIMAGE_HASH_LENGTHS = { 'sha256': 64, 'sha384': 96, 'sha512': 128 }
-    MKIMAGE_SIGNATURE_LENGTHS = { 'rsa2048': 512 }
-
     def _gen_signing_key(self, bb_vars):
         """Generate a key pair and a singing certificate
 
@@ -111,343 +107,11 @@ class FitImageTestCase(OESelftestTestCase):
         vars = get_bb_vars(['RECIPE_SYSROOT_NATIVE', 'bindir'], native_recipe)
         return os.path.join(vars['RECIPE_SYSROOT_NATIVE'], vars['bindir'])
 
-    def _verify_fit_image_signature(self, uboot_tools_bindir, fitimage_path, dtb_path, conf_name=None):
-        """Verify the signature of a fit configuration
-
-        The fit_check_sign utility from u-boot-tools-native is called.
-        uboot-fit_check_sign -f fitImage -k $dtb_path -c conf-$dtb_name
-        dtb_path refers to a binary device tree containing the public key.
-        """
-        fit_check_sign_path = os.path.join(uboot_tools_bindir, 'uboot-fit_check_sign')
-        cmd = '%s -f %s -k %s' % (fit_check_sign_path, fitimage_path, dtb_path)
-        if conf_name:
-            cmd += ' -c %s' % conf_name
-        result = runCmd(cmd)
-        self.logger.debug("%s\nreturned: %s\n%s", cmd, str(result.status), result.output)
-        if "Signature check OK" not in result.output:
-            self.logger.error("'Signature verification failed (%s)' % result.output")
-            return False
-
-        return True
-
-    def _verify_dtb_property(self, dtc_bindir, dtb_path, node_path, property_name, req_property, absent=False):
-        """Verify device tree properties
-
-        The fdtget utility from dtc-native is called and the property is compared.
-        """
-        fdtget_path = os.path.join(dtc_bindir, 'fdtget')
-        cmd = '%s %s %s %s' % (fdtget_path, dtb_path, node_path, property_name)
-        if absent:
-            result = runCmd(cmd, ignore_status=True)
-            self.logger.debug("%s\nreturned: %s\n%s", cmd, str(result.status), result.output)
-            if "FDT_ERR_NOTFOUND" not in result.output:
-                self.logger.error('FDT_ERR_NOTFOUND is missing in device tree %s', dtb_path)
-                return False
-        else:
-            result = runCmd(cmd)
-            self.logger.debug("%s\nreturned: %s\n%s", cmd, str(result.status), result.output)
-            if req_property != result.output.strip():
-                self.logger.error('Property is not as expected: %s (%s != %s)' % (property_name, req_property, result.output.strip()))
-                return False
-
-        return True
-
-    @staticmethod
-    def _find_string_in_bin_file(file_path, search_string):
-        """find strings in a binary file
-
-        Shell equivalent: strings "$1" | grep "$2" | wc -l
-        return number of matches
-        """
-        found_positions = 0
-        with open(file_path, 'rb') as file:
-            content = file.read().decode('ascii', errors='ignore')
-            found_positions = content.count(search_string)
-        return found_positions
-
-    @staticmethod
-    def _get_uboot_mkimage_sign_args(uboot_mkimage_sign_args):
-        """Retrive the string passed via -c to the mkimage command
-
-        Example: If a build configutation defines
-          UBOOT_MKIMAGE_SIGN_ARGS = "-c 'a smart comment'"
-        this function returns "a smart comment"
-        """
-        a_comment = None
-        if uboot_mkimage_sign_args:
-            mkimage_args = shlex.split(uboot_mkimage_sign_args)
-            try:
-                c_index = mkimage_args.index('-c')
-                a_comment = mkimage_args[c_index+1]
-            except ValueError:
-                pass
-        return a_comment
-
-    @staticmethod
-    def _get_dtb_files(bb_vars):
-        """Return a list of devicetree names
-
-        The list should be used to check the dtb and conf nodes in the FIT image or its file.
-        In addition to the entries from KERNEL_DEVICETREE, the external devicetree and the
-        external devicetree overlay added by the test recipe bbb-dtbs-as-ext are handled as well.
-        """
-        kernel_devicetree = bb_vars.get('KERNEL_DEVICETREE')
-        all_dtbs = []
-        dtb_symlinks = []
-        if kernel_devicetree:
-            all_dtbs += [os.path.basename(dtb) for dtb in kernel_devicetree.split()]
-        # Support only the test recipe which provides 1 devicetree and 1 devicetree overlay
-        pref_prov_dtb = bb_vars.get('PREFERRED_PROVIDER_virtual/dtb')
-        if pref_prov_dtb == "bbb-dtbs-as-ext":
-            all_dtbs += ["BBORG_RELAY-00A2.dtbo", "am335x-bonegreen-ext.dtb"]
-            dtb_symlinks.append("am335x-bonegreen-ext-alias.dtb")
-        return (all_dtbs, dtb_symlinks)
-
-    def _is_req_dict_in_dict(self, found_dict, req_dict):
-        """
-        Check if all key-value pairs in the required dictionary are present in the found dictionary.
-
-        This function recursively checks if the required dictionary (`req_dict`) is a subset of the found dictionary (`found_dict`).
-        It supports nested dictionaries, strings, lists, and sets as values.
-
-        Args:
-            found_dict (dict): The dictionary to search within.
-            req_dict (dict): The dictionary containing the required key-value pairs.
-        """
-        for key, value in req_dict.items():
-            if key not in found_dict:
-                self.logger.error('Key not in expected dictionary: %s' % key)
-                return False
-            if isinstance(value, dict):
-                if not self._is_req_dict_in_dict(found_dict[key], value):
-                    return False
-            elif isinstance(value, str):
-                if not (value in found_dict[key]):
-                    self.logger.error(
-                        'Value is not in expected dictionary[%s]: %s' % (key, value)
-                    )
-                    return False
-            elif isinstance(value, list):
-                if not (set(value) <= set(found_dict[key])):
-                    self.logger.error(
-                        'List is not part of expected dictionary[%s]: %s' % (key, str(value))
-                    )
-                    return False
-            elif isinstance(value, set):
-                if not (value <= found_dict[key]):
-                    self.logger.error(
-                        'Set is not part of expected dictionary[%s]: %s' % (key, str(value))
-                    )
-                    return False
-            else:
-                if (value != found_dict[key]):
-                    self.logger.error(
-                        'Value is not equal in expected dictionary[%s]: %s := %s' % (key, str(value), str(found_dict[key]))
-                    )
-                    return False
-
-        return True
-
-    def _check_its_file(self, bb_vars, its_file_path):
-        """Check if the its file contains the expected sections and fields
-
-        # The _get_req_* functions are implemented by more specific child classes.
-            req_its_paths, not_req_its_paths = self._get_req_its_paths()
-            req_sigvalues_config = self._get_req_sigvalues_config()
-            req_sigvalues_image = self._get_req_sigvalues_image()
-            # Compare the its file against req_its_paths, not_req_its_paths,
-            #                              req_sigvalues_config, req_sigvalues_image
-        """
-        # print the its file for debugging
-        if logging.DEBUG >= self.logger.level:
-            with open(its_file_path) as its_file:
-                self.logger.debug("its file: %s" % its_file.read())
-
-        # Generate a list of expected paths in the its file
-        req_its_paths, not_req_its_paths = self._get_req_its_paths(bb_vars)
-        self.logger.debug("req_its_paths:\n%s\n" % pprint.pformat(req_its_paths, indent=4))
-        self.logger.debug("not_req_its_paths:\n%s\n" % pprint.pformat(not_req_its_paths, indent=4))
-
-        # Generate a dict of expected configuration signature nodes
-        req_sigvalues_config = self._get_req_sigvalues_config(bb_vars)
-        self.logger.debug("req_sigvalues_config:\n%s\n" % pprint.pformat(req_sigvalues_config, indent=4))
-
-        # Generate a dict of expected image signature nodes
-        req_sigvalues_image = self._get_req_sigvalues_image(bb_vars)
-        self.logger.debug("req_sigvalues_image:\n%s\n" % pprint.pformat(req_sigvalues_image, indent=4))
-
-        # Parse the its file for paths and signatures
-        its_path = []
-        its_paths = []
-        linect = 0
-        sigs = {}
-        with open(its_file_path) as its_file:
-            for line in its_file:
-                linect += 1
-                line = line.strip()
-                if line.endswith('};'):
-                    its_path.pop()
-                elif line.endswith('{'):
-                    its_path.append(line[:-1].strip())
-                    its_paths.append(its_path[:])
-                # kernel-fitimage uses signature-1, uboot-sign uses signature
-                elif its_path and (its_path[-1] == 'signature-1' or its_path[-1] == 'signature'):
-                    itsdotpath = '.'.join(its_path)
-                    if not itsdotpath in sigs:
-                        sigs[itsdotpath] = {}
-                    if not '=' in line or not line.endswith(';'):
-                        self.logger.error(
-                            'Unexpected formatting in %s sigs section line %d:%s' % (its_file_path, linect, line)
-                        )
-                        return False
-                    key, value = line.split('=', 1)
-                    sigs[itsdotpath][key.rstrip()] = value.lstrip().rstrip(';')
-
-        # Check if all expected paths are found in the its file
-        self.logger.debug("itspaths:\n%s\n" % pprint.pformat(its_paths, indent=4))
-        for req_path in req_its_paths:
-            if not req_path in its_paths:
-                self.logger.error(
-                    'Missing path in its file: %s (%s)' % (req_path, its_file_path)
-                )
-                return False
-
-        # check if all not expected paths are absent in the its file
-        for not_req_path in not_req_its_paths:
-            if not_req_path in its_paths:
-                self.logger.error(
-                    'Unexpected path found in its file: %s (%s)' % (not_req_path, its_file_path)
-                )
-                return False
-
-        # Check if all the expected singnature nodes (images and configurations) are found
-        self.logger.debug("sigs:\n%s\n" % pprint.pformat(sigs, indent=4))
-        if req_sigvalues_config or req_sigvalues_image:
-            for its_path, values in sigs.items():
-                if bb_vars.get('FIT_CONF_PREFIX', "conf-") in its_path:
-                    reqsigvalues = req_sigvalues_config
-                else:
-                    reqsigvalues = req_sigvalues_image
-                for reqkey, reqvalue in reqsigvalues.items():
-                    value = values.get(reqkey, None)
-                    if value is None:
-                        self.logger.error('Missing key "%s" in its file signature section %s (%s)' % (reqkey, its_path, its_file_path))
-                        return False
-                    if value != reqvalue:
-                        self.logger.error('Wrong value  for key "%s" in its file signature section %s (%s) (%s != %s)' % (reqkey, its_path, its_file_path, value, reqvalue))
-                        return False
-
-        # Generate a list of expected fields in the its file
-        req_its_fields = self._get_req_its_fields(bb_vars)
-        self.logger.debug("req_its_fields:\n%s\n" % pprint.pformat(req_its_fields, indent=4))
-
-        # Check if all expected fields are in the its file
-        if req_its_fields:
-            field_index = 0
-            field_index_last = len(req_its_fields) - 1
-            found_all = False
-            with open(its_file_path) as its_file:
-                for line in its_file:
-                    if req_its_fields[field_index] in line:
-                        if field_index < field_index_last:
-                            field_index += 1
-                        else:
-                            found_all = True
-                            break
-            if not found_all:
-                self.logger.error(
-                    "Fields in Image Tree Source File %s did not match, error in finding %s"
-                    % (its_file_path, req_its_fields[field_index])
-                )
-                return False
-
-        return True
-
-    def _check_fitimage(self, bb_vars, fitimage_path, uboot_tools_bindir):
-        """Run dumpimage on the final FIT image and parse the output into a dict
-
-        # The _get_req_* functions are implemented by more specific chield classes.
-            self._get_req_sections()
-            # Compare the output of the dumpimage utility against
-        """
-        dumpimage_path = os.path.join(uboot_tools_bindir, 'dumpimage')
-        cmd = '%s -l %s' % (dumpimage_path, fitimage_path)
-        self.logger.debug("Analyzing output from dumpimage: %s" % cmd)
-        dumpimage_result = runCmd(cmd)
-        in_section = None
-        sections = {}
-        self.logger.debug("dumpimage output: %s" % dumpimage_result.output)
-        for line in dumpimage_result.output.splitlines():
-            # Find potentially hashed and signed sections
-            if line.startswith((' Configuration', ' Image')):
-                in_section = re.search(r'\((.*)\)', line).groups()[0]
-            # Key value lines start with two spaces otherwise the section ended
-            elif not line.startswith("  "):
-                in_section = None
-            # Handle key value lines of this section
-            elif in_section:
-                if not in_section in sections:
-                    sections[in_section] = {}
-                try:
-                    key, value = line.split(':', 1)
-                    key = key.strip()
-                    value = value.strip()
-                except ValueError as val_err:
-                    # Handle multiple entries as e.g. for Loadables as a list
-                    if key and line.startswith("   "):
-                        value = sections[in_section][key] + "," + line.strip()
-                    else:
-                        raise ValueError(f"Error processing line: '{line}'. Original error: {val_err}")
-                sections[in_section][key] = value
-
-        # Check if the requested dictionary is a subset of the parsed dictionary
-        req_sections, num_signatures = self._get_req_sections(bb_vars)
-        self.logger.debug("req_sections: \n%s\n" % pprint.pformat(req_sections, indent=4))
-        self.logger.debug("dumpimage sections: \n%s\n" % pprint.pformat(sections, indent=4))
-        if not self._is_req_dict_in_dict(sections, req_sections):
-            self.logger.error(
-                "The requested dictionary is not a subset of the parsed dictionary"
-            )
-            return False
-
-        # Call the signing related checks if the function is provided by a inherited class
-        return self._check_signing(bb_vars, sections, num_signatures, uboot_tools_bindir, fitimage_path)
-
-    def _get_req_its_paths(self, bb_vars):
-        self.logger.error("This function needs to be implemented")
-        return ([], [])
-
-    def _get_req_its_fields(self, bb_vars):
-        self.logger.error("This function needs to be implemented")
-        return []
-
-    def _get_req_sigvalues_config(self, bb_vars):
-        self.logger.error("This function needs to be implemented")
-        return {}
-
-    def _get_req_sigvalues_image(self, bb_vars):
-        self.logger.error("This function needs to be implemented")
-        return {}
-
-    def _get_req_sections(self, bb_vars):
-        self.logger.error("This function needs to be implemented")
-        return ({}, 0)
-
-    def _check_signing(self, bb_vars, sections, num_signatures, uboot_tools_bindir, fitimage_path):
-        """Verify the signatures in the FIT image."""
-        self.logger.error("Function needs to be implemented by inheriting classes")
-        return False
-
     def _bitbake_fit_image(self, bb_vars):
         """Bitbake the FIT image and return the paths to the its file and the FIT image"""
         self.logger.error("Function needs to be implemented by inheriting classes")
         return False
 
-    def _get_fit_image(self, bb_vars):
-        """Return the paths to the its file and the FIT image"""
-        self.logger.error("Function needs to be implemented by inheriting classes")
-        return False
-
     def _test_fitimage(self, bb_vars):
         """Check if the its file and the FIT image are created and signed correctly"""
         fitimage_its_path, fitimage_path = self._bitbake_fit_image(bb_vars)
@@ -455,18 +119,23 @@ class FitImageTestCase(OESelftestTestCase):
         self.assertExists(fitimage_path, "%s FIT image doesn't exist" % (fitimage_path))
 
         self.logger.debug("Checking its: %s" % fitimage_its_path)
-        self.assertTrue(self._check_its_file(bb_vars, fitimage_its_path))
+        self.assertTrue(self.fitimage_utils._check_its_file(bb_vars, fitimage_its_path))
 
         # Setup u-boot-tools-native
         uboot_tools_bindir = FitImageTestCase._setup_native('u-boot-tools-native')
 
         # Verify the FIT image
         self.assertTrue(
-            self._check_fitimage(bb_vars, fitimage_path, uboot_tools_bindir)
+            self.fitimage_utils._check_fitimage(bb_vars, fitimage_path, uboot_tools_bindir)
         )
 
 class KernelFitImageBase(FitImageTestCase):
     """Test cases for the linux-yocto-fitimage recipe"""
+    @classmethod
+    def setUpClass(cls):
+        """Initialize the fitimage_utils"""
+        super(KernelFitImageBase, cls).setUpClass()
+        cls.fitimage_utils = KernelFitImageUtils(cls.logger)
 
     def _fit_get_bb_vars(self, additional_vars=[]):
         """Retrieve BitBake variables specific to the test case.
@@ -543,344 +212,12 @@ class KernelFitImageBase(FitImageTestCase):
         """Bitbake the kernel and return the paths to the its file and the FIT image"""
         bitbake(self.kernel_recipe)
 
-        fitimage_its_path, fitimage_path = self._get_fit_image(bb_vars)
+        # Find the right its file and the final fitImage and check if both files are available
+        fitimage_its_path, fitimage_path = self.fitimage_utils._get_fit_image(bb_vars)
         if fitimage_its_path is None or fitimage_path is None:
             self.fail('Unable to find FIT image')
         return (fitimage_its_path, fitimage_path)
 
-    def _get_fit_image(self, bb_vars):
-        """Return the paths to the its file and the FIT image"""
-        # Find the right its file and the final fitImage and check if both files are available
-        deploy_dir_image = bb_vars['DEPLOY_DIR_IMAGE']
-        initramfs_image = bb_vars['INITRAMFS_IMAGE']
-        initramfs_image_bundle = bb_vars['INITRAMFS_IMAGE_BUNDLE']
-        initramfs_image_name = bb_vars['INITRAMFS_IMAGE_NAME']
-        kernel_fit_link_name = bb_vars['KERNEL_FIT_LINK_NAME']
-        if not initramfs_image and initramfs_image_bundle != "1":
-            fitimage_its_name = "fitImage-its-%s" % kernel_fit_link_name
-            fitimage_name = "fitImage"
-        elif initramfs_image and initramfs_image_bundle != "1":
-            fitimage_its_name = "fitImage-its-%s-%s" % (initramfs_image_name, kernel_fit_link_name)
-            fitimage_name = "fitImage-%s-%s" % (initramfs_image_name, kernel_fit_link_name)
-        elif initramfs_image and initramfs_image_bundle == "1":
-            fitimage_its_name = "fitImage-its-%s-%s" % (initramfs_image_name, kernel_fit_link_name)
-            fitimage_name = "fitImage"  # or fitImage-${KERNEL_IMAGE_LINK_NAME}${KERNEL_IMAGE_BIN_EXT}
-        else:
-            self.logger.error(
-                'Invalid configuration: INITRAMFS_IMAGE_BUNDLE = "1" and not INITRAMFS_IMAGE'
-            )
-            return (None, None)
-        kernel_deploysubdir = bb_vars['KERNEL_DEPLOYSUBDIR']
-        if kernel_deploysubdir:
-            fitimage_its_path = os.path.realpath(os.path.join(deploy_dir_image, kernel_deploysubdir, fitimage_its_name))
-            fitimage_path = os.path.realpath(os.path.join(deploy_dir_image, kernel_deploysubdir, fitimage_name))
-        else:
-            fitimage_its_path = os.path.realpath(os.path.join(deploy_dir_image, fitimage_its_name))
-            fitimage_path = os.path.realpath(os.path.join(deploy_dir_image, fitimage_name))
-        return (fitimage_its_path, fitimage_path)
-
-    def _get_req_its_paths(self, bb_vars):
-        """Generate a list of expected and a list of not expected paths in the its file
-
-        Example:
-            [
-                ['/', 'images', 'kernel-1', 'hash-1'],
-                ['/', 'images', 'kernel-1', 'signature-1'],
-            ]
-        """
-        dtb_files, dtb_symlinks = FitImageTestCase._get_dtb_files(bb_vars)
-        fit_sign_individual = bb_vars['FIT_SIGN_INDIVIDUAL']
-        fit_uboot_env = bb_vars['FIT_UBOOT_ENV']
-        initramfs_image = bb_vars['INITRAMFS_IMAGE']
-        initramfs_image_bundle = bb_vars['INITRAMFS_IMAGE_BUNDLE']
-        uboot_sign_enable = bb_vars.get('UBOOT_SIGN_ENABLE')
-
-        # image nodes
-        images = ['kernel-1']
-        not_images = []
-
-        if dtb_files:
-            images += [ 'fdt-' + dtb for dtb in dtb_files ]
-
-        if fit_uboot_env:
-            images.append('bootscr-' + fit_uboot_env)
-        else:
-            not_images.append('bootscr-boot.cmd')
-
-        if bb_vars['MACHINE'] == "qemux86-64": # Not really the right if
-            images.append('setup-1')
-        else:
-            not_images.append('setup-1')
-
-        if initramfs_image and initramfs_image_bundle != "1":
-            images.append('ramdisk-1')
-        else:
-            not_images.append('ramdisk-1')
-
-        # configuration nodes (one per DTB and also one per symlink)
-        if dtb_files:
-            configurations = [bb_vars['FIT_CONF_PREFIX'] + conf for conf in dtb_files + dtb_symlinks]
-        else:
-            configurations = [bb_vars['FIT_CONF_PREFIX'] + '1']
-
-        # Create a list of paths for all image and configuration nodes
-        req_its_paths = []
-        for image in images:
-            req_its_paths.append(['/', 'images', image, 'hash-1'])
-            if uboot_sign_enable == "1" and fit_sign_individual == "1":
-                req_its_paths.append(['/', 'images', image, 'signature-1'])
-        for configuration in configurations:
-            req_its_paths.append(['/', 'configurations', configuration, 'hash-1'])
-            if uboot_sign_enable == "1":
-                req_its_paths.append(['/', 'configurations', configuration, 'signature-1'])
-
-        not_req_its_paths = []
-        for image in not_images:
-            not_req_its_paths.append(['/', 'images', image])
-
-        return (req_its_paths, not_req_its_paths)
-
-    def _get_req_its_fields(self, bb_vars):
-        initramfs_image = bb_vars['INITRAMFS_IMAGE']
-        initramfs_image_bundle = bb_vars['INITRAMFS_IMAGE_BUNDLE']
-        uboot_rd_loadaddress = bb_vars.get('UBOOT_RD_LOADADDRESS')
-        uboot_rd_entrypoint = bb_vars.get('UBOOT_RD_ENTRYPOINT')
-
-        its_field_check = [
-            'description = "%s";' % bb_vars['FIT_DESC'],
-            'description = "Linux kernel";',
-            'type = "' + str(bb_vars['UBOOT_MKIMAGE_KERNEL_TYPE']) + '";',
-            # 'compression = "' + str(bb_vars['FIT_KERNEL_COMP_ALG']) + '";', defined based on files in TMPDIR, not ideal...
-            'data = /incbin/("linux.bin");',
-            'arch = "' + str(bb_vars['UBOOT_ARCH']) + '";',
-            'os = "linux";',
-            'load = <' + str(bb_vars['UBOOT_LOADADDRESS']) + '>;',
-            'entry = <' + str(bb_vars['UBOOT_ENTRYPOINT']) + '>;',
-        ]
-        if initramfs_image and initramfs_image_bundle != "1":
-            its_field_check.append('type = "ramdisk";')
-            if uboot_rd_loadaddress:
-                its_field_check.append("load = <%s>;" % uboot_rd_loadaddress)
-            if uboot_rd_entrypoint:
-                its_field_check.append("entry = <%s>;" % uboot_rd_entrypoint)
-
-        fit_conf_default_dtb = bb_vars.get('FIT_CONF_DEFAULT_DTB')
-        if fit_conf_default_dtb:
-            fit_conf_prefix = bb_vars.get('FIT_CONF_PREFIX', "conf-")
-            its_field_check.append('default = "' + fit_conf_prefix + fit_conf_default_dtb + '";')
-
-        # configuration nodes (one per DTB and also one per symlink)
-        dtb_files, dtb_symlinks = FitImageTestCase._get_dtb_files(bb_vars)
-        if dtb_files:
-            for dtb in dtb_files:
-                its_field_check.append('kernel = "kernel-1";')
-                its_field_check.append('fdt = "fdt-%s";' % dtb)
-            for dtb in dtb_symlinks:
-                its_field_check.append('kernel = "kernel-1";')
-                # Works only for tests were the symlink is with -alias suffix
-                its_field_check.append('fdt = "fdt-%s";' % dtb.replace('-alias', ''))
-
-            if initramfs_image and initramfs_image_bundle != "1":
-                its_field_check.append('ramdisk = "ramdisk-1";')
-        else:
-            its_field_check.append('kernel = "kernel-1";')
-            if initramfs_image and initramfs_image_bundle != "1":
-                its_field_check.append('ramdisk = "ramdisk-1";')
-
-        return its_field_check
-
-    def _get_req_sigvalues_config(self, bb_vars):
-        """Generate a dictionary of expected configuration signature nodes"""
-        if bb_vars.get('UBOOT_SIGN_ENABLE') != "1":
-            return {}
-        sign_images = '"kernel", "fdt"'
-        if bb_vars['INITRAMFS_IMAGE'] and bb_vars['INITRAMFS_IMAGE_BUNDLE'] != "1":
-            sign_images += ', "ramdisk"'
-        if bb_vars['FIT_UBOOT_ENV']:
-            sign_images += ', "bootscr"'
-        req_sigvalues_config = {
-            'algo': '"%s,%s"' % (bb_vars['FIT_HASH_ALG'], bb_vars['FIT_SIGN_ALG']),
-            'key-name-hint': '"%s"' % bb_vars['UBOOT_SIGN_KEYNAME'],
-            'sign-images': sign_images,
-        }
-        return req_sigvalues_config
-
-    def _get_req_sigvalues_image(self, bb_vars):
-        """Generate a dictionary of expected image signature nodes"""
-        if bb_vars['FIT_SIGN_INDIVIDUAL'] != "1":
-            return {}
-        req_sigvalues_image = {
-            'algo': '"%s,%s"' % (bb_vars['FIT_HASH_ALG'], bb_vars['FIT_SIGN_ALG']),
-            'key-name-hint': '"%s"' % bb_vars['UBOOT_SIGN_IMG_KEYNAME'],
-        }
-        return req_sigvalues_image
-
-    def _get_req_sections(self, bb_vars):
-        """Generate a dictionary of expected sections in the output of dumpimage"""
-        dtb_files, dtb_symlinks = FitImageTestCase._get_dtb_files(bb_vars)
-        fit_hash_alg = bb_vars['FIT_HASH_ALG']
-        fit_sign_alg = bb_vars['FIT_SIGN_ALG']
-        fit_sign_individual = bb_vars['FIT_SIGN_INDIVIDUAL']
-        fit_uboot_env = bb_vars['FIT_UBOOT_ENV']
-        initramfs_image = bb_vars['INITRAMFS_IMAGE']
-        initramfs_image_bundle = bb_vars['INITRAMFS_IMAGE_BUNDLE']
-        uboot_sign_enable = bb_vars['UBOOT_SIGN_ENABLE']
-        uboot_sign_img_keyname = bb_vars['UBOOT_SIGN_IMG_KEYNAME']
-        uboot_sign_keyname = bb_vars['UBOOT_SIGN_KEYNAME']
-        num_signatures = 0
-        req_sections = {
-            "kernel-1": {
-                "Type": "Kernel Image",
-                "OS": "Linux",
-                "Load Address": bb_vars['UBOOT_LOADADDRESS'],
-                "Entry Point": bb_vars['UBOOT_ENTRYPOINT'],
-            }
-        }
-        # Create one section per DTB
-        for dtb in dtb_files:
-            req_sections['fdt-' + dtb] = {
-                "Type": "Flat Device Tree",
-            }
-        # Add a script section if there is a script
-        if fit_uboot_env:
-            req_sections['bootscr-' + fit_uboot_env] = { "Type": "Script" }
-        # Add the initramfs
-        if initramfs_image and initramfs_image_bundle != "1":
-            req_sections['ramdisk-1'] = {
-                "Type": "RAMDisk Image",
-                "Load Address": bb_vars['UBOOT_RD_LOADADDRESS'],
-                "Entry Point": bb_vars['UBOOT_RD_ENTRYPOINT']
-            }
-        # Create a configuration section for each DTB
-        if dtb_files:
-            for dtb in dtb_files + dtb_symlinks:
-                conf_name = bb_vars['FIT_CONF_PREFIX'] + dtb
-                # Assume that DTBs with an "-alias" in its name are symlink DTBs created e.g. by the
-                # bbb-dtbs-as-ext test recipe. Make the configuration node pointing to the real DTB.
-                real_dtb = dtb.replace("-alias", "")
-                # dtb overlays do not refer to a kernel (yet?)
-                if dtb.endswith('.dtbo'):
-                    req_sections[conf_name] = {
-                        "FDT": 'fdt-' + real_dtb,
-                    }
-                else:
-                    req_sections[conf_name] = {
-                        "Kernel": "kernel-1",
-                        "FDT": 'fdt-' + real_dtb,
-                    }
-                if initramfs_image and initramfs_image_bundle != "1":
-                    req_sections[conf_name]['Init Ramdisk'] = "ramdisk-1"
-        else:
-            conf_name = bb_vars['FIT_CONF_PREFIX'] +  '1'
-            req_sections[conf_name] = {
-                "Kernel": "kernel-1"
-            }
-            if initramfs_image and initramfs_image_bundle != "1":
-                req_sections[conf_name]['Init Ramdisk'] = "ramdisk-1"
-
-        # Add signing related properties if needed
-        if uboot_sign_enable == "1":
-            for section in req_sections:
-                req_sections[section]['Hash algo'] = fit_hash_alg
-                if section.startswith(bb_vars['FIT_CONF_PREFIX']):
-                    req_sections[section]['Hash value'] = "unavailable"
-                    req_sections[section]['Sign algo'] = "%s,%s:%s" % (fit_hash_alg, fit_sign_alg, uboot_sign_keyname)
-                    num_signatures += 1
-                elif fit_sign_individual == "1":
-                    req_sections[section]['Sign algo'] = "%s,%s:%s" % (fit_hash_alg, fit_sign_alg, uboot_sign_img_keyname)
-                    num_signatures += 1
-        return (req_sections, num_signatures)
-
-    def _check_signing(self, bb_vars, sections, num_signatures, uboot_tools_bindir, fitimage_path):
-        """Verify the signature nodes in the FIT image"""
-        if bb_vars['UBOOT_SIGN_ENABLE'] == "1":
-            self.logger.debug("Verifying signatures in the FIT image")
-        else:
-            self.logger.debug("FIT image is not signed. Signature verification is not needed.")
-            return True
-
-        fit_hash_alg = bb_vars['FIT_HASH_ALG']
-        fit_sign_alg = bb_vars['FIT_SIGN_ALG']
-        uboot_sign_keyname = bb_vars['UBOOT_SIGN_KEYNAME']
-        uboot_sign_img_keyname = bb_vars['UBOOT_SIGN_IMG_KEYNAME']
-        deploy_dir_image = bb_vars['DEPLOY_DIR_IMAGE']
-        kernel_deploysubdir = bb_vars['KERNEL_DEPLOYSUBDIR']
-        fit_sign_individual = bb_vars['FIT_SIGN_INDIVIDUAL']
-        fit_hash_alg_len = FitImageTestCase.MKIMAGE_HASH_LENGTHS[fit_hash_alg]
-        fit_sign_alg_len = FitImageTestCase.MKIMAGE_SIGNATURE_LENGTHS[fit_sign_alg]
-        for section, values in sections.items():
-            # Configuration nodes are always signed with UBOOT_SIGN_KEYNAME (if UBOOT_SIGN_ENABLE = "1")
-            if section.startswith(bb_vars['FIT_CONF_PREFIX']):
-                sign_algo = values.get('Sign algo', None)
-                req_sign_algo = "%s,%s:%s" % (fit_hash_alg, fit_sign_alg, uboot_sign_keyname)
-                if sign_algo != req_sign_algo:
-                    self.logger.error(
-                        'Signature algorithm for %s not expected value' % section
-                    )
-                    return False
-                sign_value = values.get('Sign value', None)
-                if len(sign_value) != fit_sign_alg_len:
-                    self.logger.error(
-                        'Signature value for section %s not expected length' % section
-                    )
-                    return False
-                dtb_file_name = section.replace(bb_vars['FIT_CONF_PREFIX'], '')
-                dtb_path = os.path.join(deploy_dir_image, dtb_file_name)
-                if kernel_deploysubdir:
-                    dtb_path = os.path.join(deploy_dir_image, kernel_deploysubdir, dtb_file_name)
-                # External devicetrees created by devicetree.bbclass are in a subfolder and have priority
-                dtb_path_ext = os.path.join(deploy_dir_image, "devicetree", dtb_file_name)
-                if os.path.exists(dtb_path_ext):
-                    dtb_path = dtb_path_ext
-                if not (
-                    self._verify_fit_image_signature(uboot_tools_bindir, fitimage_path, dtb_path, section)
-                ):
-                    self.logger.error(
-                        'FIT image signature is not verified'
-                    )
-                    return False
-            else:
-                # Image nodes always need a hash which gets indirectly signed by the config signature
-                hash_algo = values.get('Hash algo', None)
-                if hash_algo != fit_hash_alg:
-                    return False
-                hash_value = values.get('Hash value', None)
-                if len(hash_value) != fit_hash_alg_len:
-                    self.logger.error(
-                        'Hash value for section %s not expected length' % section
-                    )
-                    return False
-                # Optionally, if FIT_SIGN_INDIVIDUAL = 1 also the image nodes have a signature (which is redundant but possible)
-                if fit_sign_individual == "1":
-                    sign_algo = values.get('Sign algo', None)
-                    req_sign_algo = "%s,%s:%s" % (fit_hash_alg, fit_sign_alg, uboot_sign_img_keyname)
-                    if sign_algo != req_sign_algo:
-                        self.logger.error(
-                            'Signature algorithm for %s not expected value' % section
-                        )
-                        return False
-                    sign_value = values.get('Sign value', None)
-                    if len(sign_value) != fit_sign_alg_len:
-                       self.logger.error(
-                           'Signature value for section %s not expected length' % section
-                       )
-                       return False
-
-        # Search for the string passed to mkimage in each signed section of the FIT image.
-        # Looks like mkimage supports to add a comment but does not support to read it back.
-        a_comment = FitImageTestCase._get_uboot_mkimage_sign_args(bb_vars['UBOOT_MKIMAGE_SIGN_ARGS'])
-        self.logger.debug("a_comment: %s" % a_comment)
-        if a_comment:
-            found_comments = FitImageTestCase._find_string_in_bin_file(fitimage_path, a_comment)
-            if found_comments != num_signatures:
-                self.logger.error(
-                    "Expected %d signed and commented (%s) sections in the fitImage." %
-                    (num_signatures, a_comment)
-                )
-                return False
-
-        return True
-
 class KernelFitImageRecipeTests(KernelFitImageBase):
     """Test cases for the kernel-fitimage bbclass"""
 
@@ -1236,7 +573,7 @@ class FitImagePyTests(KernelFitImageBase):
             bb_vars.get('UBOOT_MKIMAGE_KERNEL_TYPE'), bb_vars.get("UBOOT_ENTRYSYMBOL")
         )
 
-        dtb_files, _ = FitImageTestCase._get_dtb_files(bb_vars)
+        dtb_files, _ = FitImageUtils._get_dtb_files(bb_vars)
         for dtb in dtb_files:
             root_node.fitimage_emit_section_dtb(dtb, os.path.join("a-dir", dtb),
                 bb_vars.get("UBOOT_DTB_LOADADDRESS"), bb_vars.get("UBOOT_DTBO_LOADADDRESS"))
@@ -1258,7 +595,7 @@ class FitImagePyTests(KernelFitImageBase):
 
         self.assertExists(fitimage_its_path, "%s image tree source doesn't exist" % (fitimage_its_path))
         self.logger.debug("Checking its: %s" % fitimage_its_path)
-        self.assertTrue(self._check_its_file(bb_vars, fitimage_its_path))
+        self.assertTrue(self.fitimage_utils._check_its_file(bb_vars, fitimage_its_path))
 
     def test_fitimage_py_default(self):
         self._test_fitimage_py()
@@ -1276,6 +613,12 @@ class UBootFitImageTests(FitImageTestCase):
 
     BOOTLOADER_RECIPE = "virtual/bootloader"
 
+    @classmethod
+    def setUpClass(cls):
+        """Initialize the fitimage_utils"""
+        super(UBootFitImageTests, cls).setUpClass()
+        cls.fitimage_utils = UBootFitImageUtils(cls.logger)
+
     def _fit_get_bb_vars(self, additional_vars=[]):
         """Get bb_vars as needed by _test_sign_fit_image
 
@@ -1325,197 +668,44 @@ class UBootFitImageTests(FitImageTestCase):
         """Bitbake the bootloader and return the paths to the its file and the FIT image"""
         bitbake(UBootFitImageTests.BOOTLOADER_RECIPE)
 
-        fitimage_its_path, fitimage_path = self._get_fit_image(bb_vars)
+        # Find the right its file and the final fitImage and check if both files are available
+        fitimage_its_path, fitimage_path = self.fitimage_utils._get_fit_image(bb_vars)
         if fitimage_its_path is None or fitimage_path is None:
             self.fail('Unable to find FIT image')
         return (fitimage_its_path, fitimage_path)
 
-    def _get_fit_image(self, bb_vars):
-        """Return the paths to the its file and the FIT image"""
-        deploy_dir_image = bb_vars['DEPLOY_DIR_IMAGE']
-        machine = bb_vars['MACHINE']
-        fitimage_its_path = os.path.join(deploy_dir_image, "u-boot-its-%s" % machine)
-        fitimage_path = os.path.join(deploy_dir_image, "u-boot-fitImage-%s" % machine)
-        return (fitimage_its_path, fitimage_path)
-
-    def _get_req_its_paths(self, bb_vars):
-        # image nodes
-        images = [ 'uboot', 'fdt',  ]
-        if bb_vars['UBOOT_FIT_TEE'] == "1":
-            images.append('tee')
-        if bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE'] == "1":
-            images.append('atf')
-        # if bb_vars['UBOOT_FIT_USER_SETTINGS']:
-
-        # configuration nodes
-        configurations = [ 'conf']
-
-        # Create a list of paths for all image and configuration nodes
-        req_its_paths = []
-        for image in images:
-            req_its_paths.append(['/', 'images', image])
-            if bb_vars['SPL_SIGN_ENABLE'] == "1":
-                req_its_paths.append(['/', 'images', image, 'signature'])
-        for configuration in configurations:
-            req_its_paths.append(['/', 'configurations', configuration])
-        return (req_its_paths, [])
-
-    def _get_req_its_fields(self, bb_vars):
-        loadables = ["uboot"]
-        its_field_check = [
-            'description = "%s";' % bb_vars['UBOOT_FIT_DESC'],
-            'description = "U-Boot image";',
-            'data = /incbin/("%s");' % bb_vars['UBOOT_NODTB_BINARY'],
-            'type = "standalone";',
-            'os = "u-boot";',
-            'arch = "%s";' % bb_vars['UBOOT_ARCH'],
-            'compression = "none";',
-            'load = <%s>;' % bb_vars['UBOOT_FIT_UBOOT_LOADADDRESS'],
-            'entry = <%s>;' % bb_vars['UBOOT_FIT_UBOOT_ENTRYPOINT'],
-            'description = "U-Boot FDT";',
-            'data = /incbin/("%s");' % bb_vars['UBOOT_DTB_BINARY'],
-            'type = "flat_dt";',
-            'arch = "%s";' % bb_vars['UBOOT_ARCH'],
-            'compression = "none";',
-        ]
-        if bb_vars['UBOOT_FIT_TEE'] == "1":
-            its_field_check += [
-                'description = "Trusted Execution Environment";',
-                'data = /incbin/("%s");' % bb_vars['UBOOT_FIT_TEE_IMAGE'],
-                'type = "tee";',
-                'arch = "%s";' % bb_vars['UBOOT_ARCH'],
-                'os = "tee";',
-                'load = <%s>;' % bb_vars['UBOOT_FIT_TEE_LOADADDRESS'],
-                'entry = <%s>;' % bb_vars['UBOOT_FIT_TEE_ENTRYPOINT'],
-                'compression = "none";',
-            ]
-            loadables.insert(0, "tee")
-        if bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE'] == "1":
-            its_field_check += [
-                'description = "ARM Trusted Firmware";',
-                'data = /incbin/("%s");' % bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE_IMAGE'],
-                'type = "firmware";',
-                'arch = "%s";' % bb_vars['UBOOT_ARCH'],
-                'os = "arm-trusted-firmware";',
-                'load = <%s>;' % bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE_LOADADDRESS'],
-                'entry = <%s>;' % bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE_ENTRYPOINT'],
-                'compression = "none";',
-            ]
-            loadables.insert(0, "atf")
-        its_field_check += [
-            'default = "conf";',
-            'description = "Boot with signed U-Boot FIT";',
-            'loadables = "%s";' % '", "'.join(loadables),
-            'fdt = "fdt";',
-        ]
-        return its_field_check
-
-    def _get_req_sigvalues_config(self, bb_vars):
-        # COnfigurations are not signed by uboot-sign
-        return {}
-
-    def _get_req_sigvalues_image(self, bb_vars):
-        if bb_vars['SPL_SIGN_ENABLE'] != "1":
-            return {}
-        req_sigvalues_image = {
-            'algo': '"%s,%s"' % (bb_vars['UBOOT_FIT_HASH_ALG'], bb_vars['UBOOT_FIT_SIGN_ALG']),
-            'key-name-hint': '"%s"' % bb_vars['SPL_SIGN_KEYNAME'],
-        }
-        return req_sigvalues_image
-
-    def _get_req_sections(self, bb_vars):
-        """Generate the expected output of dumpimage for beaglebone targets
-
-        The dict generated by this function is supposed to be compared against
-        the dict which is generated by the _dump_fitimage function.
+    def test_uboot_fit_image(self):
         """
-        loadables = ['uboot']
-        req_sections = {
-            "uboot": {
-                "Type": "Standalone Program",
-                "Load Address": bb_vars['UBOOT_FIT_UBOOT_LOADADDRESS'],
-                "Entry Point": bb_vars['UBOOT_FIT_UBOOT_ENTRYPOINT'],
-            },
-            "fdt": {
-                "Type": "Flat Device Tree",
-            }
-        }
-        if bb_vars['UBOOT_FIT_TEE'] == "1":
-            loadables.insert(0, "tee")
-            req_sections['tee'] = {
-                "Type": "Trusted Execution Environment Image",
-                # "Load Address": bb_vars['UBOOT_FIT_TEE_LOADADDRESS'], not printed by mkimage?
-                # "Entry Point": bb_vars['UBOOT_FIT_TEE_ENTRYPOINT'], not printed by mkimage?
-            }
-        if bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE'] == "1":
-            loadables.insert(0, "atf")
-            req_sections['atf'] = {
-                "Type": "Firmware",
-                "Load Address": bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE_LOADADDRESS'],
-                # "Entry Point": bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE_ENTRYPOINT'], not printed by mkimage?
-            }
-        req_sections["conf"] = {
-            "Kernel": "unavailable",
-            "FDT": "fdt",
-            "Loadables": ','.join(loadables),
-        }
+        Summary:     Check if Uboot FIT image and Image Tree Source
+                     (its) are built and the Image Tree Source has the
+                     correct fields.
+        Expected:    1. u-boot-fitImage and u-boot-its can be built
+                     2. The type, load address, entrypoint address and
+                     default values of U-boot image are correct in the
+                     Image Tree Source. Not all the fields are tested,
+                     only the key fields that wont vary between
+                     different architectures.
+        Product:     oe-core
+        Author:      Klaus Heinrich Kiwi <klaus@linux.vnet.ibm.com>
+                     based on work by Usama Arif <usama.arif@arm.com>
+        """
+        config = """
+# We need at least CONFIG_SPL_LOAD_FIT and CONFIG_SPL_OF_CONTROL set
+MACHINE:forcevariable = "qemuarm"
+UBOOT_MACHINE = "am57xx_evm_defconfig"
+SPL_BINARY = "MLO"
+
+# Enable creation of the U-Boot fitImage
+UBOOT_FITIMAGE_ENABLE = "1"
 
-        # Add signing related properties if needed
-        uboot_fit_hash_alg = bb_vars['UBOOT_FIT_HASH_ALG']
-        uboot_fit_sign_alg = bb_vars['UBOOT_FIT_SIGN_ALG']
-        spl_sign_enable = bb_vars['SPL_SIGN_ENABLE']
-        spl_sign_keyname = bb_vars['SPL_SIGN_KEYNAME']
-        num_signatures = 0
-        if spl_sign_enable == "1":
-            for section in req_sections:
-                if not section.startswith('conf'):
-                    req_sections[section]['Sign algo'] = "%s,%s:%s" % \
-                        (uboot_fit_hash_alg, uboot_fit_sign_alg, spl_sign_keyname)
-                    num_signatures += 1
-        return (req_sections, num_signatures)
-
-    def  _check_signing(self, bb_vars, sections, num_signatures, uboot_tools_bindir, fitimage_path):
-        if bb_vars['UBOOT_FITIMAGE_ENABLE'] == '1' and bb_vars['SPL_SIGN_ENABLE'] == "1":
-            self.logger.debug("Verifying signatures in the FIT image")
-        else:
-            self.logger.debug("FIT image is not signed. Signature verification is not needed.")
-            return True
-
-        uboot_fit_hash_alg = bb_vars['UBOOT_FIT_HASH_ALG']
-        uboot_fit_sign_alg = bb_vars['UBOOT_FIT_SIGN_ALG']
-        spl_sign_keyname = bb_vars['SPL_SIGN_KEYNAME']
-        fit_sign_alg_len = self.MKIMAGE_SIGNATURE_LENGTHS[uboot_fit_sign_alg]
-        for section, values in sections.items():
-            # Configuration nodes are always signed with UBOOT_SIGN_KEYNAME (if UBOOT_SIGN_ENABLE = "1")
-            if section.startswith("conf"):
-                # uboot-sign does not sign configuration nodes
-                pass
-            else:
-                # uboot-sign does not add hash nodes, only image signatures
-                sign_algo = values.get('Sign algo', None)
-                req_sign_algo = "%s,%s:%s" % (uboot_fit_hash_alg, uboot_fit_sign_alg, spl_sign_keyname)
-                if sign_algo != req_sign_algo:
-                    self.logger.error('Signature algorithm for %s not expected value' % section)
-                    return False
-                sign_value = values.get('Sign value', None)
-                if len(sign_value) != fit_sign_alg_len:
-                    selg.logger.error('Signature value for section %s not expected length' % section)
-                    return False
-
-        # Search for the string passed to mkimage in each signed section of the FIT image.
-        # Looks like mkimage supports to add a comment but does not support to read it back.
-        a_comment = FitImageTestCase._get_uboot_mkimage_sign_args(bb_vars['SPL_MKIMAGE_SIGN_ARGS'])
-        self.logger.debug("a_comment: %s" % a_comment)
-        if a_comment:
-            found_comments = self._find_string_in_bin_file(fitimage_path, a_comment)
-            if found_comments != num_signatures:
-                self.logger.error(
-                    "Expected %d signed and commented (%s) sections in the fitImage." %
-                    (num_signatures, a_comment)
-                )
-                return False
-
-        return True
+# (U-boot) fitImage properties
+UBOOT_LOADADDRESS = "0x80080000"
+UBOOT_ENTRYPOINT = "0x80080000"
+UBOOT_FIT_DESC = "A model description"
+"""
+        self.write_config(config)
+        bb_vars = self._fit_get_bb_vars()
+        self._test_fitimage(bb_vars)
 
     def _check_kernel_dtb(self, bb_vars):
         """
@@ -1551,61 +741,27 @@ class UBootFitImageTests(FitImageTestCase):
             uboot_sign_img_keyname = bb_vars['UBOOT_SIGN_IMG_KEYNAME']
             key_dtb_path = "/signature/key-" + uboot_sign_img_keyname
             self.assertTrue(
-                self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "required", "image")
+                self.fitimage_utils._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "required", "image")
             )
             self.assertTrue(
-                self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "algo", algo)
+                self.fitimage_utils._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "algo", algo)
             )
             self.assertTrue(
-                self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "key-name-hint", uboot_sign_img_keyname)
+                self.fitimage_utils._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "key-name-hint", uboot_sign_img_keyname)
             )
 
         uboot_sign_keyname = bb_vars['UBOOT_SIGN_KEYNAME']
         key_dtb_path = "/signature/key-" + uboot_sign_keyname
         self.assertTrue(
-            self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "required", "conf")
+            self.fitimage_utils._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "required", "conf")
         )
         self.assertTrue(
-            self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "algo", algo)
+            self.fitimage_utils._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "algo", algo)
         )
         self.assertTrue(
-            self._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "key-name-hint", uboot_sign_keyname)
+            self.fitimage_utils._verify_dtb_property(dtc_bindir, uboot_dtb_path, key_dtb_path, "key-name-hint", uboot_sign_keyname)
         )
 
-    def test_uboot_fit_image(self):
-        """
-        Summary:     Check if Uboot FIT image and Image Tree Source
-                     (its) are built and the Image Tree Source has the
-                     correct fields.
-        Expected:    1. u-boot-fitImage and u-boot-its can be built
-                     2. The type, load address, entrypoint address and
-                     default values of U-boot image are correct in the
-                     Image Tree Source. Not all the fields are tested,
-                     only the key fields that wont vary between
-                     different architectures.
-        Product:     oe-core
-        Author:      Klaus Heinrich Kiwi <klaus@linux.vnet.ibm.com>
-                     based on work by Usama Arif <usama.arif@arm.com>
-        """
-        config = """
-# We need at least CONFIG_SPL_LOAD_FIT and CONFIG_SPL_OF_CONTROL set
-MACHINE:forcevariable = "qemuarm"
-UBOOT_MACHINE = "am57xx_evm_defconfig"
-SPL_BINARY = "MLO"
-
-# Enable creation of the U-Boot fitImage
-UBOOT_FITIMAGE_ENABLE = "1"
-
-# (U-boot) fitImage properties
-UBOOT_LOADADDRESS = "0x80080000"
-UBOOT_ENTRYPOINT = "0x80080000"
-UBOOT_FIT_DESC = "A model description"
-"""
-        self.write_config(config)
-        bb_vars = self._fit_get_bb_vars()
-        self._test_fitimage(bb_vars)
-
-
     def test_sign_standalone_uboot_fit_image(self):
         """
         Summary:     Check if U-Boot FIT image and Image Tree Source (its) are
diff --git a/meta/lib/oeqa/utils/fitimage.py b/meta/lib/oeqa/utils/fitimage.py
new file mode 100644
index 0000000000..bfe594c968
--- /dev/null
+++ b/meta/lib/oeqa/utils/fitimage.py
@@ -0,0 +1,883 @@
+#
+# Copyright OpenEmbedded Contributors
+#
+# SPDX-License-Identifier: MIT
+#
+
+
+import logging
+import os
+import pprint
+import re
+import shlex
+
+from oeqa.utils.commands import runCmd
+
+
+class FitImageError(Exception):
+    pass
+
+
+class FitImageUtils():
+    """Kernel FIT image base library"""
+
+    MKIMAGE_HASH_LENGTHS = { 'sha256': 64, 'sha384': 96, 'sha512': 128 }
+    MKIMAGE_SIGNATURE_LENGTHS = { 'rsa2048': 512 }
+
+    def __init__(self, logger):
+        self.logger = logger
+
+    def _verify_fit_image_signature(self, uboot_tools_bindir, fitimage_path, dtb_path, conf_name=None):
+        """Verify the signature of a fit configuration
+
+        The fit_check_sign utility from u-boot-tools-native is called.
+        uboot-fit_check_sign -f fitImage -k $dtb_path -c conf-$dtb_name
+        dtb_path refers to a binary device tree containing the public key.
+        """
+        fit_check_sign_path = os.path.join(uboot_tools_bindir, 'uboot-fit_check_sign')
+        cmd = '%s -f %s -k %s' % (fit_check_sign_path, fitimage_path, dtb_path)
+        if conf_name:
+            cmd += ' -c %s' % conf_name
+        result = runCmd(cmd)
+        self.logger.debug("%s\nreturned: %s\n%s", cmd, str(result.status), result.output)
+        if "Signature check OK" not in result.output:
+            self.logger.error("'Signature verification failed (%s)' % result.output")
+            return False
+
+        return True
+
+    def _verify_dtb_property(self, dtc_bindir, dtb_path, node_path, property_name, req_property, absent=False):
+        """Verify device tree properties
+
+        The fdtget utility from dtc-native is called and the property is compared.
+        """
+        fdtget_path = os.path.join(dtc_bindir, 'fdtget')
+        cmd = '%s %s %s %s' % (fdtget_path, dtb_path, node_path, property_name)
+        if absent:
+            result = runCmd(cmd, ignore_status=True)
+            self.logger.debug("%s\nreturned: %s\n%s", cmd, str(result.status), result.output)
+            if "FDT_ERR_NOTFOUND" not in result.output:
+                self.logger.error('FDT_ERR_NOTFOUND is missing in device tree %s', dtb_path)
+                return False
+        else:
+            result = runCmd(cmd)
+            self.logger.debug("%s\nreturned: %s\n%s", cmd, str(result.status), result.output)
+            if req_property != result.output.strip():
+                self.logger.error('Property is not as expected: %s (%s != %s)' % (property_name, req_property, result.output.strip()))
+                return False
+
+        return True
+
+    @staticmethod
+    def _find_string_in_bin_file(file_path, search_string):
+        """find strings in a binary file
+
+        Shell equivalent: strings "$1" | grep "$2" | wc -l
+        return number of matches
+        """
+        found_positions = 0
+        with open(file_path, 'rb') as file:
+            content = file.read().decode('ascii', errors='ignore')
+            found_positions = content.count(search_string)
+        return found_positions
+
+    @staticmethod
+    def _get_uboot_mkimage_sign_args(uboot_mkimage_sign_args):
+        """Retrive the string passed via -c to the mkimage command
+
+        Example: If a build configutation defines
+          UBOOT_MKIMAGE_SIGN_ARGS = "-c 'a smart comment'"
+        this function returns "a smart comment"
+        """
+        a_comment = None
+        if uboot_mkimage_sign_args:
+            mkimage_args = shlex.split(uboot_mkimage_sign_args)
+            try:
+                c_index = mkimage_args.index('-c')
+                a_comment = mkimage_args[c_index+1]
+            except ValueError:
+                pass
+        return a_comment
+
+    @staticmethod
+    def _get_dtb_files(bb_vars):
+        """Return a list of devicetree names
+
+        The list should be used to check the dtb and conf nodes in the FIT image or its file.
+        In addition to the entries from KERNEL_DEVICETREE, the external devicetree and the
+        external devicetree overlay added by the test recipe bbb-dtbs-as-ext are handled as well.
+        """
+        kernel_devicetree = bb_vars.get('KERNEL_DEVICETREE')
+        all_dtbs = []
+        dtb_symlinks = []
+        if kernel_devicetree:
+            all_dtbs += [os.path.basename(dtb) for dtb in kernel_devicetree.split()]
+        # Support only the test recipe which provides 1 devicetree and 1 devicetree overlay
+        pref_prov_dtb = bb_vars.get('PREFERRED_PROVIDER_virtual/dtb')
+        if pref_prov_dtb == "bbb-dtbs-as-ext":
+            all_dtbs += ["BBORG_RELAY-00A2.dtbo", "am335x-bonegreen-ext.dtb"]
+            dtb_symlinks.append("am335x-bonegreen-ext-alias.dtb")
+        return (all_dtbs, dtb_symlinks)
+
+    def _is_req_dict_in_dict(self, found_dict, req_dict):
+        """
+        Check if all key-value pairs in the required dictionary are present in the found dictionary.
+
+        This function recursively checks if the required dictionary (`req_dict`) is a subset of the found dictionary (`found_dict`).
+        It supports nested dictionaries, strings, lists, and sets as values.
+
+        Args:
+            found_dict (dict): The dictionary to search within.
+            req_dict (dict): The dictionary containing the required key-value pairs.
+        """
+        for key, value in req_dict.items():
+            if key not in found_dict:
+                self.logger.error('Key not in expected dictionary: %s' % key)
+                return False
+            if isinstance(value, dict):
+                if not self._is_req_dict_in_dict(found_dict[key], value):
+                    return False
+            elif isinstance(value, str):
+                if not (value in found_dict[key]):
+                    self.logger.error(
+                        'Value is not in expected dictionary[%s]: %s' % (key, value)
+                    )
+                    return False
+            elif isinstance(value, list):
+                if not (set(value) <= set(found_dict[key])):
+                    self.logger.error(
+                        'List is not part of expected dictionary[%s]: %s' % (key, str(value))
+                    )
+                    return False
+            elif isinstance(value, set):
+                if not (value <= found_dict[key]):
+                    self.logger.error(
+                        'Set is not part of expected dictionary[%s]: %s' % (key, str(value))
+                    )
+                    return False
+            else:
+                if (value != found_dict[key]):
+                    self.logger.error(
+                        'Value is not equal in expected dictionary[%s]: %s := %s' % (key, str(value), str(found_dict[key]))
+                    )
+                    return False
+
+        return True
+
+    def _check_its_file(self, bb_vars, its_file_path):
+        """Check if the its file contains the expected sections and fields
+
+        # The _get_req_* functions are implemented by more specific child classes.
+            req_its_paths, not_req_its_paths = self._get_req_its_paths()
+            req_sigvalues_config = self._get_req_sigvalues_config()
+            req_sigvalues_image = self._get_req_sigvalues_image()
+            # Compare the its file against req_its_paths, not_req_its_paths,
+            #                              req_sigvalues_config, req_sigvalues_image
+        """
+        # print the its file for debugging
+        if logging.DEBUG >= self.logger.level:
+            with open(its_file_path) as its_file:
+                self.logger.debug("its file: %s" % its_file.read())
+
+        # Generate a list of expected paths in the its file
+        req_its_paths, not_req_its_paths = self._get_req_its_paths(bb_vars)
+        self.logger.debug("req_its_paths:\n%s\n" % pprint.pformat(req_its_paths, indent=4))
+        self.logger.debug("not_req_its_paths:\n%s\n" % pprint.pformat(not_req_its_paths, indent=4))
+
+        # Generate a dict of expected configuration signature nodes
+        req_sigvalues_config = self._get_req_sigvalues_config(bb_vars)
+        self.logger.debug("req_sigvalues_config:\n%s\n" % pprint.pformat(req_sigvalues_config, indent=4))
+
+        # Generate a dict of expected image signature nodes
+        req_sigvalues_image = self._get_req_sigvalues_image(bb_vars)
+        self.logger.debug("req_sigvalues_image:\n%s\n" % pprint.pformat(req_sigvalues_image, indent=4))
+
+        # Parse the its file for paths and signatures
+        its_path = []
+        its_paths = []
+        linect = 0
+        sigs = {}
+        with open(its_file_path) as its_file:
+            for line in its_file:
+                linect += 1
+                line = line.strip()
+                if line.endswith('};'):
+                    its_path.pop()
+                elif line.endswith('{'):
+                    its_path.append(line[:-1].strip())
+                    its_paths.append(its_path[:])
+                # kernel-fitimage uses signature-1, uboot-sign uses signature
+                elif its_path and (its_path[-1] == 'signature-1' or its_path[-1] == 'signature'):
+                    itsdotpath = '.'.join(its_path)
+                    if not itsdotpath in sigs:
+                        sigs[itsdotpath] = {}
+                    if not '=' in line or not line.endswith(';'):
+                        self.logger.error(
+                            'Unexpected formatting in %s sigs section line %d:%s' % (its_file_path, linect, line)
+                        )
+                        return False
+                    key, value = line.split('=', 1)
+                    sigs[itsdotpath][key.rstrip()] = value.lstrip().rstrip(';')
+
+        # Check if all expected paths are found in the its file
+        self.logger.debug("itspaths:\n%s\n" % pprint.pformat(its_paths, indent=4))
+        for req_path in req_its_paths:
+            if not req_path in its_paths:
+                self.logger.error(
+                    'Missing path in its file: %s (%s)' % (req_path, its_file_path)
+                )
+                return False
+
+        # check if all not expected paths are absent in the its file
+        for not_req_path in not_req_its_paths:
+            if not_req_path in its_paths:
+                self.logger.error(
+                    'Unexpected path found in its file: %s (%s)' % (not_req_path, its_file_path)
+                )
+                return False
+
+        # Check if all the expected singnature nodes (images and configurations) are found
+        self.logger.debug("sigs:\n%s\n" % pprint.pformat(sigs, indent=4))
+        if req_sigvalues_config or req_sigvalues_image:
+            for its_path, values in sigs.items():
+                if bb_vars.get('FIT_CONF_PREFIX', "conf-") in its_path:
+                    reqsigvalues = req_sigvalues_config
+                else:
+                    reqsigvalues = req_sigvalues_image
+                for reqkey, reqvalue in reqsigvalues.items():
+                    value = values.get(reqkey, None)
+                    if value is None:
+                        self.logger.error('Missing key "%s" in its file signature section %s (%s)' % (reqkey, its_path, its_file_path))
+                        return False
+                    if value != reqvalue:
+                        self.logger.error('Wrong value  for key "%s" in its file signature section %s (%s) (%s != %s)' % (reqkey, its_path, its_file_path, value, reqvalue))
+                        return False
+
+        # Generate a list of expected fields in the its file
+        req_its_fields = self._get_req_its_fields(bb_vars)
+        self.logger.debug("req_its_fields:\n%s\n" % pprint.pformat(req_its_fields, indent=4))
+
+        # Check if all expected fields are in the its file
+        if req_its_fields:
+            field_index = 0
+            field_index_last = len(req_its_fields) - 1
+            found_all = False
+            with open(its_file_path) as its_file:
+                for line in its_file:
+                    if req_its_fields[field_index] in line:
+                        if field_index < field_index_last:
+                            field_index += 1
+                        else:
+                            found_all = True
+                            break
+            if not found_all:
+                self.logger.error(
+                    "Fields in Image Tree Source File %s did not match, error in finding %s"
+                    % (its_file_path, req_its_fields[field_index])
+                )
+                return False
+
+        return True
+
+    def _check_fitimage(self, bb_vars, fitimage_path, uboot_tools_bindir):
+        """Run dumpimage on the final FIT image and parse the output into a dict
+
+        # The _get_req_* functions are implemented by more specific chield classes.
+            self._get_req_sections()
+            # Compare the output of the dumpimage utility against
+        """
+        dumpimage_path = os.path.join(uboot_tools_bindir, 'dumpimage')
+        cmd = '%s -l %s' % (dumpimage_path, fitimage_path)
+        self.logger.debug("Analyzing output from dumpimage: %s" % cmd)
+        dumpimage_result = runCmd(cmd)
+        in_section = None
+        sections = {}
+        self.logger.debug("dumpimage output: %s" % dumpimage_result.output)
+        for line in dumpimage_result.output.splitlines():
+            # Find potentially hashed and signed sections
+            if line.startswith((' Configuration', ' Image')):
+                in_section = re.search(r'\((.*)\)', line).groups()[0]
+            # Key value lines start with two spaces otherwise the section ended
+            elif not line.startswith("  "):
+                in_section = None
+            # Handle key value lines of this section
+            elif in_section:
+                if not in_section in sections:
+                    sections[in_section] = {}
+                try:
+                    key, value = line.split(':', 1)
+                    key = key.strip()
+                    value = value.strip()
+                except ValueError as val_err:
+                    # Handle multiple entries as e.g. for Loadables as a list
+                    if key and line.startswith("   "):
+                        value = sections[in_section][key] + "," + line.strip()
+                    else:
+                        raise ValueError(f"Error processing line: '{line}'. Original error: {val_err}")
+                sections[in_section][key] = value
+
+        # Check if the requested dictionary is a subset of the parsed dictionary
+        req_sections, num_signatures = self._get_req_sections(bb_vars)
+        self.logger.debug("req_sections: \n%s\n" % pprint.pformat(req_sections, indent=4))
+        self.logger.debug("dumpimage sections: \n%s\n" % pprint.pformat(sections, indent=4))
+        if not self._is_req_dict_in_dict(sections, req_sections):
+            self.logger.error(
+                "The requested dictionary is not a subset of the parsed dictionary"
+            )
+            return False
+
+        # Call the signing related checks if the function is provided by a inherited class
+        return self._check_signing(bb_vars, sections, num_signatures, uboot_tools_bindir, fitimage_path)
+
+    def _get_req_its_paths(self, bb_vars):
+        self.logger.error("This function needs to be implemented")
+        return ([], [])
+
+    def _get_req_its_fields(self, bb_vars):
+        self.logger.error("This function needs to be implemented")
+        return []
+
+    def _get_req_sigvalues_config(self, bb_vars):
+        self.logger.error("This function needs to be implemented")
+        return {}
+
+    def _get_req_sigvalues_image(self, bb_vars):
+        self.logger.error("This function needs to be implemented")
+        return {}
+
+    def _get_req_sections(self, bb_vars):
+        self.logger.error("This function needs to be implemented")
+        return ({}, 0)
+
+    def _check_signing(self, bb_vars, sections, num_signatures, uboot_tools_bindir, fitimage_path):
+        """Verify the signatures in the FIT image."""
+        self.logger.error("Function needs to be implemented by inheriting classes")
+        return False
+
+    def _get_fit_image(self, bb_vars):
+        """Return the paths to the its file and the FIT image"""
+        self.logger.error("Function needs to be implemented by inheriting classes")
+        return False
+
+
+class KernelFitImageUtils(FitImageUtils):
+
+    def _get_fit_image(self, bb_vars):
+        """Return the paths to the its file and the FIT image"""
+        deploy_dir_image = bb_vars['DEPLOY_DIR_IMAGE']
+        initramfs_image = bb_vars['INITRAMFS_IMAGE']
+        initramfs_image_bundle = bb_vars['INITRAMFS_IMAGE_BUNDLE']
+        initramfs_image_name = bb_vars['INITRAMFS_IMAGE_NAME']
+        kernel_fit_link_name = bb_vars['KERNEL_FIT_LINK_NAME']
+        if not initramfs_image and initramfs_image_bundle != "1":
+            fitimage_its_name = "fitImage-its-%s" % kernel_fit_link_name
+            fitimage_name = "fitImage"
+        elif initramfs_image and initramfs_image_bundle != "1":
+            fitimage_its_name = "fitImage-its-%s-%s" % (initramfs_image_name, kernel_fit_link_name)
+            fitimage_name = "fitImage-%s-%s" % (initramfs_image_name, kernel_fit_link_name)
+        elif initramfs_image and initramfs_image_bundle == "1":
+            fitimage_its_name = "fitImage-its-%s-%s" % (initramfs_image_name, kernel_fit_link_name)
+            fitimage_name = "fitImage"  # or fitImage-${KERNEL_IMAGE_LINK_NAME}${KERNEL_IMAGE_BIN_EXT}
+        else:
+            self.logger.error('Invalid configuration: INITRAMFS_IMAGE_BUNDLE = "1" and not INITRAMFS_IMAGE')
+            return (None, None)
+        kernel_deploysubdir = bb_vars['KERNEL_DEPLOYSUBDIR']
+        if kernel_deploysubdir:
+            fitimage_its_path = os.path.realpath(os.path.join(deploy_dir_image, kernel_deploysubdir, fitimage_its_name))
+            fitimage_path = os.path.realpath(os.path.join(deploy_dir_image, kernel_deploysubdir, fitimage_name))
+        else:
+            fitimage_its_path = os.path.realpath(os.path.join(deploy_dir_image, fitimage_its_name))
+            fitimage_path = os.path.realpath(os.path.join(deploy_dir_image, fitimage_name))
+        return (fitimage_its_path, fitimage_path)
+
+    def _get_req_its_paths(self, bb_vars):
+        """Generate a list of expected and a list of not expected paths in the its file
+
+        Example:
+            [
+                ['/', 'images', 'kernel-1', 'hash-1'],
+                ['/', 'images', 'kernel-1', 'signature-1'],
+            ]
+        """
+        dtb_files, dtb_symlinks = FitImageUtils._get_dtb_files(bb_vars)
+        fit_sign_individual = bb_vars['FIT_SIGN_INDIVIDUAL']
+        fit_uboot_env = bb_vars['FIT_UBOOT_ENV']
+        initramfs_image = bb_vars['INITRAMFS_IMAGE']
+        initramfs_image_bundle = bb_vars['INITRAMFS_IMAGE_BUNDLE']
+        uboot_sign_enable = bb_vars.get('UBOOT_SIGN_ENABLE')
+
+        # image nodes
+        images = ['kernel-1']
+        not_images = []
+
+        if dtb_files:
+            images += [ 'fdt-' + dtb for dtb in dtb_files ]
+
+        if fit_uboot_env:
+            images.append('bootscr-' + fit_uboot_env)
+        else:
+            not_images.append('bootscr-boot.cmd')
+
+        if bb_vars['MACHINE'] == "qemux86-64": # Not really the right if
+            images.append('setup-1')
+        else:
+            not_images.append('setup-1')
+
+        if initramfs_image and initramfs_image_bundle != "1":
+            images.append('ramdisk-1')
+        else:
+            not_images.append('ramdisk-1')
+
+        # configuration nodes (one per DTB and also one per symlink)
+        if dtb_files:
+            configurations = [bb_vars['FIT_CONF_PREFIX'] + conf for conf in dtb_files + dtb_symlinks]
+        else:
+            configurations = [bb_vars['FIT_CONF_PREFIX'] + '1']
+
+        # Create a list of paths for all image and configuration nodes
+        req_its_paths = []
+        for image in images:
+            req_its_paths.append(['/', 'images', image, 'hash-1'])
+            if uboot_sign_enable == "1" and fit_sign_individual == "1":
+                req_its_paths.append(['/', 'images', image, 'signature-1'])
+        for configuration in configurations:
+            req_its_paths.append(['/', 'configurations', configuration, 'hash-1'])
+            if uboot_sign_enable == "1":
+                req_its_paths.append(['/', 'configurations', configuration, 'signature-1'])
+
+        not_req_its_paths = []
+        for image in not_images:
+            not_req_its_paths.append(['/', 'images', image])
+
+        return (req_its_paths, not_req_its_paths)
+
+    def _get_req_its_fields(self, bb_vars):
+        initramfs_image = bb_vars['INITRAMFS_IMAGE']
+        initramfs_image_bundle = bb_vars['INITRAMFS_IMAGE_BUNDLE']
+        uboot_rd_loadaddress = bb_vars.get('UBOOT_RD_LOADADDRESS')
+        uboot_rd_entrypoint = bb_vars.get('UBOOT_RD_ENTRYPOINT')
+
+        its_field_check = [
+            'description = "%s";' % bb_vars['FIT_DESC'],
+            'description = "Linux kernel";',
+            'type = "' + str(bb_vars['UBOOT_MKIMAGE_KERNEL_TYPE']) + '";',
+            # 'compression = "' + str(bb_vars['FIT_KERNEL_COMP_ALG']) + '";', defined based on files in TMPDIR, not ideal...
+            'data = /incbin/("linux.bin");',
+            'arch = "' + str(bb_vars['UBOOT_ARCH']) + '";',
+            'os = "linux";',
+            'load = <' + str(bb_vars['UBOOT_LOADADDRESS']) + '>;',
+            'entry = <' + str(bb_vars['UBOOT_ENTRYPOINT']) + '>;',
+        ]
+        if initramfs_image and initramfs_image_bundle != "1":
+            its_field_check.append('type = "ramdisk";')
+            if uboot_rd_loadaddress:
+                its_field_check.append("load = <%s>;" % uboot_rd_loadaddress)
+            if uboot_rd_entrypoint:
+                its_field_check.append("entry = <%s>;" % uboot_rd_entrypoint)
+
+        fit_conf_default_dtb = bb_vars.get('FIT_CONF_DEFAULT_DTB')
+        if fit_conf_default_dtb:
+            fit_conf_prefix = bb_vars.get('FIT_CONF_PREFIX', "conf-")
+            its_field_check.append('default = "' + fit_conf_prefix + fit_conf_default_dtb + '";')
+
+        # configuration nodes (one per DTB and also one per symlink)
+        dtb_files, dtb_symlinks = FitImageUtils._get_dtb_files(bb_vars)
+        if dtb_files:
+            for dtb in dtb_files:
+                its_field_check.append('kernel = "kernel-1";')
+                its_field_check.append('fdt = "fdt-%s";' % dtb)
+            for dtb in dtb_symlinks:
+                its_field_check.append('kernel = "kernel-1";')
+                # Works only for tests were the symlink is with -alias suffix
+                its_field_check.append('fdt = "fdt-%s";' % dtb.replace('-alias', ''))
+
+            if initramfs_image and initramfs_image_bundle != "1":
+                its_field_check.append('ramdisk = "ramdisk-1";')
+        else:
+            its_field_check.append('kernel = "kernel-1";')
+            if initramfs_image and initramfs_image_bundle != "1":
+                its_field_check.append('ramdisk = "ramdisk-1";')
+
+        return its_field_check
+
+    def _get_req_sigvalues_config(self, bb_vars):
+        """Generate a dictionary of expected configuration signature nodes"""
+        if bb_vars.get('UBOOT_SIGN_ENABLE') != "1":
+            return {}
+        sign_images = '"kernel", "fdt"'
+        if bb_vars['INITRAMFS_IMAGE'] and bb_vars['INITRAMFS_IMAGE_BUNDLE'] != "1":
+            sign_images += ', "ramdisk"'
+        if bb_vars['FIT_UBOOT_ENV']:
+            sign_images += ', "bootscr"'
+        req_sigvalues_config = {
+            'algo': '"%s,%s"' % (bb_vars['FIT_HASH_ALG'], bb_vars['FIT_SIGN_ALG']),
+            'key-name-hint': '"%s"' % bb_vars['UBOOT_SIGN_KEYNAME'],
+            'sign-images': sign_images,
+        }
+        return req_sigvalues_config
+
+    def _get_req_sigvalues_image(self, bb_vars):
+        """Generate a dictionary of expected image signature nodes"""
+        if bb_vars['FIT_SIGN_INDIVIDUAL'] != "1":
+            return {}
+        req_sigvalues_image = {
+            'algo': '"%s,%s"' % (bb_vars['FIT_HASH_ALG'], bb_vars['FIT_SIGN_ALG']),
+            'key-name-hint': '"%s"' % bb_vars['UBOOT_SIGN_IMG_KEYNAME'],
+        }
+        return req_sigvalues_image
+
+    def _get_req_sections(self, bb_vars):
+        """Generate a dictionary of expected sections in the output of dumpimage"""
+        dtb_files, dtb_symlinks = FitImageUtils._get_dtb_files(bb_vars)
+        fit_hash_alg = bb_vars['FIT_HASH_ALG']
+        fit_sign_alg = bb_vars['FIT_SIGN_ALG']
+        fit_sign_individual = bb_vars['FIT_SIGN_INDIVIDUAL']
+        fit_uboot_env = bb_vars['FIT_UBOOT_ENV']
+        initramfs_image = bb_vars['INITRAMFS_IMAGE']
+        initramfs_image_bundle = bb_vars['INITRAMFS_IMAGE_BUNDLE']
+        uboot_sign_enable = bb_vars['UBOOT_SIGN_ENABLE']
+        uboot_sign_img_keyname = bb_vars['UBOOT_SIGN_IMG_KEYNAME']
+        uboot_sign_keyname = bb_vars['UBOOT_SIGN_KEYNAME']
+        num_signatures = 0
+        req_sections = {
+            "kernel-1": {
+                "Type": "Kernel Image",
+                "OS": "Linux",
+                "Load Address": bb_vars['UBOOT_LOADADDRESS'],
+                "Entry Point": bb_vars['UBOOT_ENTRYPOINT'],
+            }
+        }
+        # Create one section per DTB
+        for dtb in dtb_files:
+            req_sections['fdt-' + dtb] = {
+                "Type": "Flat Device Tree",
+            }
+        # Add a script section if there is a script
+        if fit_uboot_env:
+            req_sections['bootscr-' + fit_uboot_env] = { "Type": "Script" }
+        # Add the initramfs
+        if initramfs_image and initramfs_image_bundle != "1":
+            req_sections['ramdisk-1'] = {
+                "Type": "RAMDisk Image",
+                "Load Address": bb_vars['UBOOT_RD_LOADADDRESS'],
+                "Entry Point": bb_vars['UBOOT_RD_ENTRYPOINT']
+            }
+        # Create a configuration section for each DTB
+        if dtb_files:
+            for dtb in dtb_files + dtb_symlinks:
+                conf_name = bb_vars['FIT_CONF_PREFIX'] + dtb
+                # Assume that DTBs with an "-alias" in its name are symlink DTBs created e.g. by the
+                # bbb-dtbs-as-ext test recipe. Make the configuration node pointing to the real DTB.
+                real_dtb = dtb.replace("-alias", "")
+                # dtb overlays do not refer to a kernel (yet?)
+                if dtb.endswith('.dtbo'):
+                    req_sections[conf_name] = {
+                        "FDT": 'fdt-' + real_dtb,
+                    }
+                else:
+                    req_sections[conf_name] = {
+                        "Kernel": "kernel-1",
+                        "FDT": 'fdt-' + real_dtb,
+                    }
+                if initramfs_image and initramfs_image_bundle != "1":
+                    req_sections[conf_name]['Init Ramdisk'] = "ramdisk-1"
+        else:
+            conf_name = bb_vars['FIT_CONF_PREFIX'] +  '1'
+            req_sections[conf_name] = {
+                "Kernel": "kernel-1"
+            }
+            if initramfs_image and initramfs_image_bundle != "1":
+                req_sections[conf_name]['Init Ramdisk'] = "ramdisk-1"
+
+        # Add signing related properties if needed
+        if uboot_sign_enable == "1":
+            for section in req_sections:
+                req_sections[section]['Hash algo'] = fit_hash_alg
+                if section.startswith(bb_vars['FIT_CONF_PREFIX']):
+                    req_sections[section]['Hash value'] = "unavailable"
+                    req_sections[section]['Sign algo'] = "%s,%s:%s" % (fit_hash_alg, fit_sign_alg, uboot_sign_keyname)
+                    num_signatures += 1
+                elif fit_sign_individual == "1":
+                    req_sections[section]['Sign algo'] = "%s,%s:%s" % (fit_hash_alg, fit_sign_alg, uboot_sign_img_keyname)
+                    num_signatures += 1
+        return (req_sections, num_signatures)
+
+    def _check_signing(self, bb_vars, sections, num_signatures, uboot_tools_bindir, fitimage_path):
+        """Verify the signature nodes in the FIT image"""
+        if bb_vars['UBOOT_SIGN_ENABLE'] == "1":
+            self.logger.debug("Verifying signatures in the FIT image")
+        else:
+            self.logger.debug("FIT image is not signed. Signature verification is not needed.")
+            return True
+
+        fit_hash_alg = bb_vars['FIT_HASH_ALG']
+        fit_sign_alg = bb_vars['FIT_SIGN_ALG']
+        uboot_sign_keyname = bb_vars['UBOOT_SIGN_KEYNAME']
+        uboot_sign_img_keyname = bb_vars['UBOOT_SIGN_IMG_KEYNAME']
+        deploy_dir_image = bb_vars['DEPLOY_DIR_IMAGE']
+        kernel_deploysubdir = bb_vars['KERNEL_DEPLOYSUBDIR']
+        fit_sign_individual = bb_vars['FIT_SIGN_INDIVIDUAL']
+        fit_hash_alg_len = FitImageUtils.MKIMAGE_HASH_LENGTHS[fit_hash_alg]
+        fit_sign_alg_len = FitImageUtils.MKIMAGE_SIGNATURE_LENGTHS[fit_sign_alg]
+        for section, values in sections.items():
+            # Configuration nodes are always signed with UBOOT_SIGN_KEYNAME (if UBOOT_SIGN_ENABLE = "1")
+            if section.startswith(bb_vars['FIT_CONF_PREFIX']):
+                sign_algo = values.get('Sign algo', None)
+                req_sign_algo = "%s,%s:%s" % (fit_hash_alg, fit_sign_alg, uboot_sign_keyname)
+                if sign_algo != req_sign_algo:
+                    self.logger.error(
+                        'Signature algorithm for %s not expected value' % section
+                    )
+                    return False
+                sign_value = values.get('Sign value', None)
+                if len(sign_value) != fit_sign_alg_len:
+                    self.logger.error(
+                        'Signature value for section %s not expected length' % section
+                    )
+                    return False
+                dtb_file_name = section.replace(bb_vars['FIT_CONF_PREFIX'], '')
+                dtb_path = os.path.join(deploy_dir_image, dtb_file_name)
+                if kernel_deploysubdir:
+                    dtb_path = os.path.join(deploy_dir_image, kernel_deploysubdir, dtb_file_name)
+                # External devicetrees created by devicetree.bbclass are in a subfolder and have priority
+                dtb_path_ext = os.path.join(deploy_dir_image, "devicetree", dtb_file_name)
+                if os.path.exists(dtb_path_ext):
+                    dtb_path = dtb_path_ext
+                if not (
+                    self._verify_fit_image_signature(uboot_tools_bindir, fitimage_path, dtb_path, section)
+                ):
+                    self.logger.error(
+                        'FIT image signature is not verified'
+                    )
+                    return False
+            else:
+                # Image nodes always need a hash which gets indirectly signed by the config signature
+                hash_algo = values.get('Hash algo', None)
+                if hash_algo != fit_hash_alg:
+                    return False
+                hash_value = values.get('Hash value', None)
+                if len(hash_value) != fit_hash_alg_len:
+                    self.logger.error(
+                        'Hash value for section %s not expected length' % section
+                    )
+                    return False
+                # Optionally, if FIT_SIGN_INDIVIDUAL = 1 also the image nodes have a signature (which is redundant but possible)
+                if fit_sign_individual == "1":
+                    sign_algo = values.get('Sign algo', None)
+                    req_sign_algo = "%s,%s:%s" % (fit_hash_alg, fit_sign_alg, uboot_sign_img_keyname)
+                    if sign_algo != req_sign_algo:
+                        self.logger.error(
+                            'Signature algorithm for %s not expected value' % section
+                        )
+                        return False
+                    sign_value = values.get('Sign value', None)
+                    if len(sign_value) != fit_sign_alg_len:
+                       self.logger.error(
+                           'Signature value for section %s not expected length' % section
+                       )
+                       return False
+
+        # Search for the string passed to mkimage in each signed section of the FIT image.
+        # Looks like mkimage supports to add a comment but does not support to read it back.
+        a_comment = FitImageUtils._get_uboot_mkimage_sign_args(bb_vars['UBOOT_MKIMAGE_SIGN_ARGS'])
+        self.logger.debug("a_comment: %s" % a_comment)
+        if a_comment:
+            found_comments = FitImageUtils._find_string_in_bin_file(fitimage_path, a_comment)
+            if found_comments != num_signatures:
+                self.logger.error(
+                    "Expected %d signed and commented (%s) sections in the fitImage." %
+                    (num_signatures, a_comment)
+                )
+                return False
+
+        return True
+
+
+class UBootFitImageUtils(FitImageUtils):
+
+    def _get_fit_image(self, bb_vars):
+        """Return the paths to the its file and the FIT image"""
+        deploy_dir_image = bb_vars['DEPLOY_DIR_IMAGE']
+        machine = bb_vars['MACHINE']
+        fitimage_its_path = os.path.join(deploy_dir_image, "u-boot-its-%s" % machine)
+        fitimage_path = os.path.join(deploy_dir_image, "u-boot-fitImage-%s" % machine)
+        return (fitimage_its_path, fitimage_path)
+
+    def _get_req_its_paths(self, bb_vars):
+        # image nodes
+        images = [ 'uboot', 'fdt',  ]
+        if bb_vars['UBOOT_FIT_TEE'] == "1":
+            images.append('tee')
+        if bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE'] == "1":
+            images.append('atf')
+        # if bb_vars['UBOOT_FIT_USER_SETTINGS']:
+
+        # configuration nodes
+        configurations = [ 'conf']
+
+        # Create a list of paths for all image and configuration nodes
+        req_its_paths = []
+        for image in images:
+            req_its_paths.append(['/', 'images', image])
+            if bb_vars['SPL_SIGN_ENABLE'] == "1":
+                req_its_paths.append(['/', 'images', image, 'signature'])
+        for configuration in configurations:
+            req_its_paths.append(['/', 'configurations', configuration])
+        return (req_its_paths, [])
+
+    def _get_req_its_fields(self, bb_vars):
+        loadables = ["uboot"]
+        its_field_check = [
+            'description = "%s";' % bb_vars['UBOOT_FIT_DESC'],
+            'description = "U-Boot image";',
+            'data = /incbin/("%s");' % bb_vars['UBOOT_NODTB_BINARY'],
+            'type = "standalone";',
+            'os = "u-boot";',
+            'arch = "%s";' % bb_vars['UBOOT_ARCH'],
+            'compression = "none";',
+            'load = <%s>;' % bb_vars['UBOOT_FIT_UBOOT_LOADADDRESS'],
+            'entry = <%s>;' % bb_vars['UBOOT_FIT_UBOOT_ENTRYPOINT'],
+            'description = "U-Boot FDT";',
+            'data = /incbin/("%s");' % bb_vars['UBOOT_DTB_BINARY'],
+            'type = "flat_dt";',
+            'arch = "%s";' % bb_vars['UBOOT_ARCH'],
+            'compression = "none";',
+        ]
+        if bb_vars['UBOOT_FIT_TEE'] == "1":
+            its_field_check += [
+                'description = "Trusted Execution Environment";',
+                'data = /incbin/("%s");' % bb_vars['UBOOT_FIT_TEE_IMAGE'],
+                'type = "tee";',
+                'arch = "%s";' % bb_vars['UBOOT_ARCH'],
+                'os = "tee";',
+                'load = <%s>;' % bb_vars['UBOOT_FIT_TEE_LOADADDRESS'],
+                'entry = <%s>;' % bb_vars['UBOOT_FIT_TEE_ENTRYPOINT'],
+                'compression = "none";',
+            ]
+            loadables.insert(0, "tee")
+        if bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE'] == "1":
+            its_field_check += [
+                'description = "ARM Trusted Firmware";',
+                'data = /incbin/("%s");' % bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE_IMAGE'],
+                'type = "firmware";',
+                'arch = "%s";' % bb_vars['UBOOT_ARCH'],
+                'os = "arm-trusted-firmware";',
+                'load = <%s>;' % bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE_LOADADDRESS'],
+                'entry = <%s>;' % bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE_ENTRYPOINT'],
+                'compression = "none";',
+            ]
+            loadables.insert(0, "atf")
+        its_field_check += [
+            'default = "conf";',
+            'description = "Boot with signed U-Boot FIT";',
+            'loadables = "%s";' % '", "'.join(loadables),
+            'fdt = "fdt";',
+        ]
+        return its_field_check
+
+    def _get_req_sigvalues_config(self, bb_vars):
+        # COnfigurations are not signed by uboot-sign
+        return {}
+
+    def _get_req_sigvalues_image(self, bb_vars):
+        if bb_vars['SPL_SIGN_ENABLE'] != "1":
+            return {}
+        req_sigvalues_image = {
+            'algo': '"%s,%s"' % (bb_vars['UBOOT_FIT_HASH_ALG'], bb_vars['UBOOT_FIT_SIGN_ALG']),
+            'key-name-hint': '"%s"' % bb_vars['SPL_SIGN_KEYNAME'],
+        }
+        return req_sigvalues_image
+
+    def _get_req_sections(self, bb_vars):
+        """Generate the expected output of dumpimage for beaglebone targets
+
+        The dict generated by this function is supposed to be compared against
+        the dict which is generated by the _dump_fitimage function.
+        """
+        loadables = ['uboot']
+        req_sections = {
+            "uboot": {
+                "Type": "Standalone Program",
+                "Load Address": bb_vars['UBOOT_FIT_UBOOT_LOADADDRESS'],
+                "Entry Point": bb_vars['UBOOT_FIT_UBOOT_ENTRYPOINT'],
+            },
+            "fdt": {
+                "Type": "Flat Device Tree",
+            }
+        }
+        if bb_vars['UBOOT_FIT_TEE'] == "1":
+            loadables.insert(0, "tee")
+            req_sections['tee'] = {
+                "Type": "Trusted Execution Environment Image",
+                # "Load Address": bb_vars['UBOOT_FIT_TEE_LOADADDRESS'], not printed by mkimage?
+                # "Entry Point": bb_vars['UBOOT_FIT_TEE_ENTRYPOINT'], not printed by mkimage?
+            }
+        if bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE'] == "1":
+            loadables.insert(0, "atf")
+            req_sections['atf'] = {
+                "Type": "Firmware",
+                "Load Address": bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE_LOADADDRESS'],
+                # "Entry Point": bb_vars['UBOOT_FIT_ARM_TRUSTED_FIRMWARE_ENTRYPOINT'], not printed by mkimage?
+            }
+        req_sections["conf"] = {
+            "Kernel": "unavailable",
+            "FDT": "fdt",
+            "Loadables": ','.join(loadables),
+        }
+
+        # Add signing related properties if needed
+        uboot_fit_hash_alg = bb_vars['UBOOT_FIT_HASH_ALG']
+        uboot_fit_sign_alg = bb_vars['UBOOT_FIT_SIGN_ALG']
+        spl_sign_enable = bb_vars['SPL_SIGN_ENABLE']
+        spl_sign_keyname = bb_vars['SPL_SIGN_KEYNAME']
+        num_signatures = 0
+        if spl_sign_enable == "1":
+            for section in req_sections:
+                if not section.startswith('conf'):
+                    req_sections[section]['Sign algo'] = "%s,%s:%s" % \
+                        (uboot_fit_hash_alg, uboot_fit_sign_alg, spl_sign_keyname)
+                    num_signatures += 1
+        return (req_sections, num_signatures)
+
+    def  _check_signing(self, bb_vars, sections, num_signatures, uboot_tools_bindir, fitimage_path):
+        if bb_vars['UBOOT_FITIMAGE_ENABLE'] == '1' and bb_vars['SPL_SIGN_ENABLE'] == "1":
+            self.logger.debug("Verifying signatures in the FIT image")
+        else:
+            self.logger.debug("FIT image is not signed. Signature verification is not needed.")
+            return True
+
+        uboot_fit_hash_alg = bb_vars['UBOOT_FIT_HASH_ALG']
+        uboot_fit_sign_alg = bb_vars['UBOOT_FIT_SIGN_ALG']
+        spl_sign_keyname = bb_vars['SPL_SIGN_KEYNAME']
+        fit_sign_alg_len = self.MKIMAGE_SIGNATURE_LENGTHS[uboot_fit_sign_alg]
+        for section, values in sections.items():
+            # Configuration nodes are always signed with UBOOT_SIGN_KEYNAME (if UBOOT_SIGN_ENABLE = "1")
+            if section.startswith("conf"):
+                # uboot-sign does not sign configuration nodes
+                pass
+            else:
+                # uboot-sign does not add hash nodes, only image signatures
+                sign_algo = values.get('Sign algo', None)
+                req_sign_algo = "%s,%s:%s" % (uboot_fit_hash_alg, uboot_fit_sign_alg, spl_sign_keyname)
+                if sign_algo != req_sign_algo:
+                    self.logger.error('Signature algorithm for %s not expected value' % section)
+                    return False
+                sign_value = values.get('Sign value', None)
+                if len(sign_value) != fit_sign_alg_len:
+                    selg.logger.error('Signature value for section %s not expected length' % section)
+                    return False
+
+        # Search for the string passed to mkimage in each signed section of the FIT image.
+        # Looks like mkimage supports to add a comment but does not support to read it back.
+        a_comment = FitImageUtils._get_uboot_mkimage_sign_args(bb_vars['SPL_MKIMAGE_SIGN_ARGS'])
+        self.logger.debug("a_comment: %s" % a_comment)
+        if a_comment:
+            found_comments = self._find_string_in_bin_file(fitimage_path, a_comment)
+            if found_comments != num_signatures:
+                self.logger.error(
+                    "Expected %d signed and commented (%s) sections in the fitImage." %
+                    (num_signatures, a_comment)
+                )
+                return False
+
+        return True

-- 
2.43.0

