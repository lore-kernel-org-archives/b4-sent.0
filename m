From: Sam Day <me@samcday.com>
Date: Wed, 10 Jun 2026 11:27:42 +1000
Subject: [PATCH v3 04/10] binman: Android boot image support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-android-binman-v3-4-710298a38fcc@samcday.com>
References: <20260610-android-binman-v3-0-710298a38fcc@samcday.com>
In-Reply-To: <20260610-android-binman-v3-0-710298a38fcc@samcday.com>
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Bryan Brattlof <bb@ti.com>, 
 Yannic Moog <y.moog@phytec.de>, Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Yegor Yefremov <yegorslists@googlemail.com>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Rasmus Villemoes <ravi@prevas.dk>, Javier Tia <floss@jetm.me>, 
 Minkyu Kang <mk7.kang@samsung.com>, 
 Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Henrik Grimler <henrik@grimler.se>, yan wang <yan.wang@softathome.com>, 
 Marek Vasut <marex@nabladev.com>, Denis Mukhin <dmukhin@ford.com>, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781054859; l=28487;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=MQwSQ5IxpOnBjvsfZiJ2+j2cjq1ED3jjs7UWG2saH3E=;
 b=qum7CeSRgr1I/mauz7SqB7jV8zUfLka5K0a3R38It0PviqqmCwdaj3BhJHmXMuHr7LUZctyfr
 BF2TmqS47KECr5vqaOvtjxVk3rL+CjF51kIkAfDJhhdIarc3QO9FDcO
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce initial support for Android boot images (abootimgs).

The AOSP implementation was used as a reference for this work.

We start with just v0 and v2 support. v1/v3/v4 are deliberately left
unimplemented for now as no use-case has been found for them yet.

Since we're targeting U-Boot use cases here, a couple of things were
omitted from this impl, namely "second" and recovery_dtbo support.

Link: https://android.googlesource.com/platform/system/tools/mkbootimg/
Signed-off-by: Sam Day <me@samcday.com>
---
 tools/binman/etype/android_boot.py                 | 285 +++++++++++++++++++++
 tools/binman/ftest.py                              | 148 +++++++++++
 tools/binman/test/android_boot_chonky_cells.dts    |  13 +
 tools/binman/test/android_boot_dtb_in_v0.dts       |  12 +
 tools/binman/test/android_boot_invalid_addr.dts    |  13 +
 .../binman/test/android_boot_invalid_pagesize.dts  |  11 +
 tools/binman/test/android_boot_invalid_subnode.dts |  12 +
 tools/binman/test/android_boot_missing_kernel.dts  |   9 +
 .../test/android_boot_oversized_bootname.dts       |  12 +
 .../test/android_boot_unsupported_version.dts      |  11 +
 tools/binman/test/android_boot_v0.dts              |  34 +++
 .../test/android_boot_v0_pagesize_too_smol.dts     |  12 +
 tools/binman/test/android_boot_v2.dts              |  50 ++++
 tools/binman/test/android_boot_v2_missing_dtb.dts  |  12 +
 .../test/android_boot_v2_pagesize_too_smol.dts     |  13 +
 tools/binman/test/android_boot_v2_vendor_dt.dts    |  14 +
 16 files changed, 661 insertions(+)

diff --git a/tools/binman/etype/android_boot.py b/tools/binman/etype/android_boot.py
new file mode 100644
index 00000000000..8b72d90acc5
--- /dev/null
+++ b/tools/binman/etype/android_boot.py
@@ -0,0 +1,285 @@
+# SPDX-License-Identifier: GPL-2.0+
+# Entry-type module for Android boot images
+
+import hashlib
+import struct
+
+from binman.entry import Entry
+from binman.etype.section import Entry_section
+from dtoc import fdt_util
+
+
+BOOT_MAGIC = b'ANDROID!'
+BOOT_NAME_SIZE = 16
+BOOT_ARGS_SIZE = 512
+IMAGE_ID_SIZE = 32
+BOOT_EXTRA_ARGS_SIZE = 1024
+
+BOOT_IMAGE_HEADER_V0 = '<{}s10I{}s{}s{}s'.format(len(BOOT_MAGIC),
+                                                    BOOT_NAME_SIZE,
+                                                    BOOT_ARGS_SIZE,
+                                                    IMAGE_ID_SIZE)
+BOOT_IMAGE_HEADER_V0_SIZE = struct.calcsize(BOOT_IMAGE_HEADER_V0)
+BOOT_IMAGE_HEADER_V2 = (BOOT_IMAGE_HEADER_V0 +
+                        '{}sIQIIQ'.format(BOOT_EXTRA_ARGS_SIZE))
+BOOT_IMAGE_HEADER_V2_SIZE = struct.calcsize(BOOT_IMAGE_HEADER_V2)
+
+
+class Entry_android_boot(Entry_section):
+    """Android boot image
+
+    This creates an Android v0 or v2 boot image.
+
+    A kernel payload, optional ramdisk payload can be supplied. A DTB payload
+    can also be provided when header_version == v2.
+
+    Properties / Entry arguments:
+        - header-version: Android boot image header version, must be 0 or 2,
+          defaults to 0
+        - page-size: Image page size, defaults to 2048
+        - base: Base address added to the offsets below, defaults to 0x10000000
+        - kernel-offset: Kernel load offset from base, defaults to 0x00008000
+        - ramdisk-offset: Ramdisk load offset from base, defaults to 0x01000000
+        - tags-offset: ATAGS/FDT offset from base, defaults to 0x00000100
+        - dtb-offset: DTB load offset from base, defaults to 0x01f00000
+        - os-version: Encoded Android OS version and patch level, defaults to 0
+        - boot-name: Android boot image board name
+        - cmdline: Android boot command line
+
+    This entry uses the following subnodes:
+        - kernel: section containing the executable payload
+        - dtb: section containing the DTB payload, used by header version 2 only
+        - ramdisk: optional section containing a ramdisk payload
+
+    Example::
+        A v2 abootimg with control FDT placed in the DTB section:
+
+        android-boot {
+            header-version = <2>;
+            page-size = <4096>;
+            base = <0x12345678>;
+            kernel-offset = <0xCAFED00D>;
+            ramdisk-offset = <0xBEEFBABE>;
+            tags-offset = <0xFEEDDEAD>;
+            dtb-offset = <0x06660666>;
+            cmdline = "foo bar";
+
+            kernel {
+                u-boot-nodtb {
+                    # Many Android bootloaders support gzipped kernels
+                    compress = "gzip";
+                };
+            };
+
+            dtb {
+                u-boot-dtb {
+                };
+            };
+        };
+
+    Example::
+        A v0 abootimg with embedded control FDT (v0 doesn't support DTBs) and
+        an empty ramdisk (some bootloaders insist on a ramdisk being present):
+
+        android-boot {
+            header-version = <0>;
+            page-size = <2048>;
+            base = <0x80200000>;
+
+            kernel {
+                u-boot {
+                    no-expanded;
+                };
+            };
+
+            ramdisk {
+                fill {
+                    size = <1>;
+                };
+            };
+        };
+    """
+
+    def ReadNode(self):
+        super().ReadNode()
+        self.header_version = fdt_util.GetInt(self._node, 'header-version', 0)
+        self.page_size = fdt_util.GetInt(self._node, 'page-size', 2048)
+        self.base = self._GetIntCells('base', 0x10000000)
+        self.kernel_offset = self._GetIntCells('kernel-offset', 0x00008000)
+        self.ramdisk_offset = self._GetIntCells('ramdisk-offset', 0x01000000)
+        self.tags_offset = self._GetIntCells('tags-offset', 0x00000100)
+        self.dtb_offset = self._GetIntCells('dtb-offset', 0x01f00000)
+        self.os_version = fdt_util.GetInt(self._node, 'os-version', 0)
+        self.boot_name = fdt_util.GetString(self._node, 'boot-name', '')
+        self.cmdline = fdt_util.GetString(self._node, 'cmdline', '')
+
+        if self.header_version not in (0, 2):
+            self.Raise('Only Android boot image header versions 0 and 2 are '
+                       'supported')
+        if self.page_size <= 0 or self.page_size & (self.page_size - 1):
+            self.Raise('page-size must be a power of two')
+        if 'kernel' not in self._entries:
+            self.Raise("Missing required subnode 'kernel'")
+
+        if self.header_version == 0:
+            if self.page_size < BOOT_IMAGE_HEADER_V0_SIZE:
+                self.Raise('page-size must fit the Android boot image header')
+            if 'dtb' in self._entries:
+                self.Raise("Subnode 'dtb' requires header-version 2")
+        else:
+            # v2
+            if self.page_size < BOOT_IMAGE_HEADER_V2_SIZE:
+                self.Raise('page-size must fit the Android boot image header')
+            if 'dtb' not in self._entries:
+                self.Raise("Missing required subnode 'dtb'")
+
+    def ReadEntries(self):
+        for node in self._node.subnodes:
+            if node.name not in ('kernel', 'ramdisk', 'dtb'):
+                self.Raise("Unexpected subnode '%s'" % node.name)
+
+            entry = Entry.Create(self, node, etype='section',
+                                 expanded=self.GetImage().use_expanded,
+                                 missing_etype=self.GetImage().missing_etype)
+            entry.ReadNode()
+            entry.SetPrefix(self._name_prefix)
+            self._entries[node.name] = entry
+
+    def _GetIntCells(self, propname, default):
+        prop = self._node.props.get(propname)
+        if not prop:
+            return default
+
+        values = prop.value if isinstance(prop.value, list) else [prop.value]
+        if len(values) > 2:
+            self.Raise("Property '%s' must contain one or two cells" %
+                       propname)
+
+        value = 0
+        for cell in values:
+            value = value << 32 | fdt_util.fdt32_to_cpu(cell)
+
+        return value
+
+    def _GetAddr(self, offset, name, size=32):
+        addr = self.base + offset
+        if addr >= 1 << size:
+            self.Raise('%s address %#x does not fit in %d bits' %
+                       (name, addr, size))
+
+        return addr
+
+    def _CheckFit(self, name, data, size):
+        if len(data) > size:
+            self.Raise('%s is %d bytes, maximum is %d' %
+                       (name, len(data), size))
+
+        return data + b'\0' * (size - len(data))
+
+    @staticmethod
+    def _BootId(*payloads):
+        digest = hashlib.sha1()
+        for data in payloads:
+            digest.update(data)
+            digest.update(struct.pack('<I', len(data)))
+
+        return digest.digest() + b'\0' * 12
+
+    def _SplitCmdline(self):
+        cmdline = self.cmdline.encode('ascii') + b'\0'
+        return (self._CheckFit('cmdline', cmdline[:BOOT_ARGS_SIZE],
+                               BOOT_ARGS_SIZE),
+                self._CheckFit('extra-cmdline', cmdline[BOOT_ARGS_SIZE:],
+                               BOOT_EXTRA_ARGS_SIZE))
+
+    def _GetEntryData(self, name, required, default=None):
+        entry = self._entries.get(name)
+        if not entry and default is not None:
+            return default
+        return entry.GetData(required)
+
+    def _BuildV0SectionData(self, required):
+        kernel = self._GetEntryData('kernel', required)
+        ramdisk = self._GetEntryData('ramdisk', required, b'')
+        if not required and (kernel is None or vendor_dt is None or
+                             ramdisk is None):
+            return None
+
+        boot_name = self._CheckFit('boot-name', self.boot_name.encode('ascii'),
+                                   BOOT_NAME_SIZE)
+        cmdline = self._CheckFit('cmdline', self.cmdline.encode('ascii'),
+                                 BOOT_ARGS_SIZE)
+
+        boot_id_payloads = [kernel, ramdisk, b'']
+        image_id = self._BootId(*boot_id_payloads)
+
+        header = struct.pack(BOOT_IMAGE_HEADER_V0,
+                             BOOT_MAGIC,
+                             len(kernel),
+                             self._GetAddr(self.kernel_offset, 'kernel'),
+                             len(ramdisk),
+                             self._GetAddr(self.ramdisk_offset, 'ramdisk'),
+                             0, # second_len
+                             0, # second_offset
+                             self._GetAddr(self.tags_offset, 'tags'),
+                             self.page_size,
+                             self.header_version,
+                             self.os_version,
+                             boot_name,
+                             cmdline,
+                             image_id)
+
+        image = bytearray()
+        image += self.PadToAlignment(header, self.page_size)
+        image += self.PadToAlignment(kernel, self.page_size)
+        image += self.PadToAlignment(ramdisk, self.page_size)
+
+        return bytes(image)
+
+    def _BuildV2SectionData(self, required):
+        kernel = self._GetEntryData('kernel', required)
+        dtb = self._GetEntryData('dtb', required)
+        ramdisk = self._GetEntryData('ramdisk', required, b'')
+        if not required and (kernel is None or dtb is None):
+            return None
+
+        boot_name = self._CheckFit('boot-name', self.boot_name.encode('ascii'),
+                                   BOOT_NAME_SIZE)
+        cmdline, extra_cmdline = self._SplitCmdline()
+        image_id = self._BootId(kernel, ramdisk, b'', b'', dtb)
+
+        header = struct.pack(BOOT_IMAGE_HEADER_V2,
+                             BOOT_MAGIC,
+                             len(kernel),
+                             self._GetAddr(self.kernel_offset, 'kernel'),
+                             len(ramdisk),
+                             self._GetAddr(self.ramdisk_offset, 'ramdisk'),
+                             0, # second_len
+                             0, # second_offset
+                             self._GetAddr(self.tags_offset, 'tags'),
+                             self.page_size,
+                             self.header_version,
+                             self.os_version,
+                             boot_name,
+                             cmdline,
+                             image_id,
+                             extra_cmdline,
+                             0, # recovery_dtbo_len
+                             0, # recovery_dtbo_offset
+                             BOOT_IMAGE_HEADER_V2_SIZE,
+                             len(dtb),
+                             self._GetAddr(self.dtb_offset, 'dtb', size=64))
+
+        image = bytearray()
+        image += self.PadToAlignment(header, self.page_size)
+        image += self.PadToAlignment(kernel, self.page_size)
+        image += self.PadToAlignment(ramdisk, self.page_size)
+        image += self.PadToAlignment(dtb, self.page_size)
+
+        return bytes(image)
+
+    def BuildSectionData(self, required):
+        if self.header_version == 0:
+            return self._BuildV0SectionData(required)
+
+        return self._BuildV2SectionData(required)
diff --git a/tools/binman/ftest.py b/tools/binman/ftest.py
index bf98b268ac1..71740205c72 100644
--- a/tools/binman/ftest.py
+++ b/tools/binman/ftest.py
@@ -5598,6 +5598,154 @@ fdt         fdtmap                Extract the devicetree blob from the fdtmap
         self.assertIn("Node '/binman/renesas-rcar4-sa0': SRAM data longer than 966656 Bytes",
                       str(exc.exception))
 
+    @staticmethod
+    def _AndroidBootId(*payloads):
+        digest = hashlib.sha1()
+        for data in payloads:
+            digest.update(data)
+            digest.update(struct.pack('<I', len(data)))
+
+        return digest.digest() + b'\0' * 12
+
+    def testAndroidBootUnsupportedVersion(self):
+        """Test that binman rejects versions other than v0 and v2"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('android_boot_unsupported_version.dts')
+        self.assertIn("Only Android boot image header versions 0 and 2 are supported",
+                      str(exc.exception))
+
+    def testAndroidBootInvalidPageSize(self):
+        """Test that binman rejects page sizes that are not a power of 2"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('android_boot_invalid_pagesize.dts')
+        self.assertIn("page-size must be a power of two",
+                      str(exc.exception))
+
+    def testAndroidBootV0PageSizeTooSmol(self):
+        """Test that binman rejects page sizes that are smaller than header size"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('android_boot_v0_pagesize_too_smol.dts')
+        self.assertIn("page-size must fit the Android boot image header",
+                      str(exc.exception))
+
+    def testAndroidBootMissingKernel(self):
+        """Test that binman rejects configurations missing a kernel{} subnode"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('android_boot_missing_kernel.dts')
+        self.assertIn("Missing required subnode 'kernel'",
+                      str(exc.exception))
+
+    def testAndroidBootInvalidSubnode(self):
+        """Test that binman rejects invalid subnodes"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('android_boot_invalid_subnode.dts')
+        self.assertIn("Unexpected subnode 'bacon'",
+                      str(exc.exception))
+
+    def testAndroidBootInvalidAddr(self):
+        """Test that binman rejects invalid addresses"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('android_boot_invalid_addr.dts')
+        self.assertIn("kernel address 0xdeadbeefdafed00d does not fit in 32 bits",
+                      str(exc.exception))
+
+    def testAndroidBootOversizedBootName(self):
+        """Test that binman rejects boot-name exceeding 16 chars"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('android_boot_oversized_bootname.dts')
+        self.assertIn("boot-name is 38 bytes, maximum is 16",
+                      str(exc.exception))
+
+    def testAndroidBootChonkyCells(self):
+        """Test that binman rejects >2 cell addresses"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('android_boot_chonky_cells.dts')
+        self.assertIn("Property 'base' must contain one or two cells",
+                      str(exc.exception))
+
+    def testAndroidBootV0(self):
+        """Test that binman can produce a plain legacy Android boot image"""
+        data = self._DoReadFile('android_boot_v0.dts')
+        header = struct.unpack_from('<8s10I16s512s32s', data, 0)
+
+        self.assertEqual(b'ANDROID!', header[0])
+        self.assertEqual(len(U_BOOT_DATA), header[1])
+        self.assertEqual(0x80208000, header[2])
+        self.assertEqual(1, header[3])
+        self.assertEqual(0x81200000, header[4])
+        self.assertEqual(0, header[5])
+        self.assertEqual(0, header[6])
+        self.assertEqual(0x80200100, header[7])
+        self.assertEqual(0x800, header[8])
+        self.assertEqual(0, header[9])
+        self.assertEqual(0, header[10])
+        self.assertEqual(b'foo', header[12].split(b'\0', 1)[0])
+        self.assertEqual(self._AndroidBootId(U_BOOT_DATA, b'\0', b''),
+                         header[13])
+
+    def testAndroidBootV0WithDTB(self):
+        """Test that binman rejects v0 abootimgs containing a dtb section"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('android_boot_dtb_in_v0.dts')
+        self.assertIn("Subnode 'dtb' requires header-version 2",
+                      str(exc.exception))
+
+    def testAndroidBootV2(self):
+        """Test that binman can produce an Android boot image"""
+        data = self._DoReadFile('android_boot_v2.dts')
+        header = struct.unpack_from('<8s10I16s512s32s1024sIQIIQ', data, 0)
+
+        self.assertEqual(b'ANDROID!', header[0])
+        self.assertEqual(len(U_BOOT_DATA), header[1])
+        self.assertEqual(0x80008000, header[2])
+        self.assertEqual(0, header[3])
+        self.assertEqual(0x81000000, header[4])
+        self.assertEqual(0, header[5])
+        self.assertEqual(0, header[6])
+        self.assertEqual(0x80000100, header[7])
+        self.assertEqual(0x800, header[8])
+        self.assertEqual(2, header[9])
+        self.assertEqual(0, header[10])
+        self.assertEqual(b'test-board', header[11].split(b'\0', 1)[0])
+        self.assertEqual(0, header[15])
+        self.assertEqual(0, header[16])
+        self.assertEqual(1660, header[17])
+        self.assertEqual(len(U_BOOT_DTB_DATA), header[18])
+        self.assertEqual(0x81f00000, header[19])
+        self.assertEqual(self._AndroidBootId(U_BOOT_DATA, b'', b'', b'',
+                                             U_BOOT_DTB_DATA), header[13])
+
+        cmdline = header[12].split(b'\0', 1)[0]
+        extra_cmdline = header[14].split(b'\0', 1)[0]
+        self.assertEqual(b"tests.. ", cmdline[-8:])
+        self.assertEqual(512, len(cmdline))
+        self.assertEqual(b'sup', extra_cmdline)
+
+        self.assertEqual(U_BOOT_DATA, data[0x800:0x800 + len(U_BOOT_DATA)])
+        self.assertEqual(U_BOOT_DTB_DATA,
+                         data[0x1000:0x1000 + len(U_BOOT_DTB_DATA)])
+
+    def testAndroidBootV2PageSizeTooSmol(self):
+        """Test that binman rejects page sizes that are smaller than header size"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('android_boot_v2_pagesize_too_smol.dts')
+        self.assertIn("page-size must fit the Android boot image header",
+                      str(exc.exception))
+
+    def testAndroidBootV2MissingDTB(self):
+        """Test that binman rejects v2 abootimgs missing a DTB section"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('android_boot_v2_missing_dtb.dts')
+        self.assertIn("Missing required subnode 'dtb'",
+                      str(exc.exception))
+
+    def testAndroidBootV2VendorDt(self):
+        """Test that binman rejects v2 abootimgs with a vendor-dt section"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('android_boot_v2_vendor_dt.dts')
+        self.assertIn("Subnode 'vendor-dt' requires header-version 0",
+                      str(exc.exception))
+
     def testFitFdtOper(self):
         """Check handling of a specified FIT operation"""
         entry_args = {
diff --git a/tools/binman/test/android_boot_chonky_cells.dts b/tools/binman/test/android_boot_chonky_cells.dts
new file mode 100644
index 00000000000..7fdc1c86f6b
--- /dev/null
+++ b/tools/binman/test/android_boot_chonky_cells.dts
@@ -0,0 +1,13 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		android-boot {
+			base = <0xDEADBEEF 0xCAFED00D 0xDECAF>;
+
+			kernel {};
+		};
+	};
+};
diff --git a/tools/binman/test/android_boot_dtb_in_v0.dts b/tools/binman/test/android_boot_dtb_in_v0.dts
new file mode 100644
index 00000000000..24b91f9a33c
--- /dev/null
+++ b/tools/binman/test/android_boot_dtb_in_v0.dts
@@ -0,0 +1,12 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		android-boot {
+			kernel {};
+			dtb {};
+		};
+	};
+};
diff --git a/tools/binman/test/android_boot_invalid_addr.dts b/tools/binman/test/android_boot_invalid_addr.dts
new file mode 100644
index 00000000000..0d7cb051921
--- /dev/null
+++ b/tools/binman/test/android_boot_invalid_addr.dts
@@ -0,0 +1,13 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		android-boot {
+			kernel-offset = <0xDEADBEEF 0xCAFED00D>;
+
+			kernel {};
+		};
+	};
+};
diff --git a/tools/binman/test/android_boot_invalid_pagesize.dts b/tools/binman/test/android_boot_invalid_pagesize.dts
new file mode 100644
index 00000000000..01925187475
--- /dev/null
+++ b/tools/binman/test/android_boot_invalid_pagesize.dts
@@ -0,0 +1,11 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		android-boot {
+			page-size = <2049>;
+		};
+	};
+};
diff --git a/tools/binman/test/android_boot_invalid_subnode.dts b/tools/binman/test/android_boot_invalid_subnode.dts
new file mode 100644
index 00000000000..747f95068be
--- /dev/null
+++ b/tools/binman/test/android_boot_invalid_subnode.dts
@@ -0,0 +1,12 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		android-boot {
+			kernel {};
+			bacon {};
+		};
+	};
+};
diff --git a/tools/binman/test/android_boot_missing_kernel.dts b/tools/binman/test/android_boot_missing_kernel.dts
new file mode 100644
index 00000000000..fe30eb5cbb3
--- /dev/null
+++ b/tools/binman/test/android_boot_missing_kernel.dts
@@ -0,0 +1,9 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		android-boot {};
+	};
+};
diff --git a/tools/binman/test/android_boot_oversized_bootname.dts b/tools/binman/test/android_boot_oversized_bootname.dts
new file mode 100644
index 00000000000..5f5564840f8
--- /dev/null
+++ b/tools/binman/test/android_boot_oversized_bootname.dts
@@ -0,0 +1,12 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		android-boot {
+			boot-name = "this is decidedly longer than 16 bytes";
+			kernel {};
+		};
+	};
+};
diff --git a/tools/binman/test/android_boot_unsupported_version.dts b/tools/binman/test/android_boot_unsupported_version.dts
new file mode 100644
index 00000000000..9843b368b3a
--- /dev/null
+++ b/tools/binman/test/android_boot_unsupported_version.dts
@@ -0,0 +1,11 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		android-boot {
+			header-version = <1>;
+		};
+	};
+};
diff --git a/tools/binman/test/android_boot_v0.dts b/tools/binman/test/android_boot_v0.dts
new file mode 100644
index 00000000000..18813ff3613
--- /dev/null
+++ b/tools/binman/test/android_boot_v0.dts
@@ -0,0 +1,34 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	binman {
+		/* confirm that android-boot can be referenced before it's built */
+		collection {
+			content = <&abootimg>;
+		};
+
+		abootimg: android-boot {
+			header-version = <0>;
+			page-size = <0x800>;
+			base = <0x80200000>;
+			cmdline = "foo";
+
+			kernel {
+				u-boot {
+					no-expanded;
+				};
+			};
+
+			ramdisk {
+				fill {
+					size = <1>;
+				};
+			};
+		};
+	};
+};
diff --git a/tools/binman/test/android_boot_v0_pagesize_too_smol.dts b/tools/binman/test/android_boot_v0_pagesize_too_smol.dts
new file mode 100644
index 00000000000..2c617f12a1e
--- /dev/null
+++ b/tools/binman/test/android_boot_v0_pagesize_too_smol.dts
@@ -0,0 +1,12 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		android-boot {
+			page-size = <32>;
+			kernel {};
+		};
+	};
+};
diff --git a/tools/binman/test/android_boot_v2.dts b/tools/binman/test/android_boot_v2.dts
new file mode 100644
index 00000000000..55fab329443
--- /dev/null
+++ b/tools/binman/test/android_boot_v2.dts
@@ -0,0 +1,50 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+#define CMDLINE(...) #__VA_ARGS__
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	binman {
+		/* confirm that android-boot can be referenced before it's built */
+		collection {
+			content = <&abootimg>;
+		};
+
+		abootimg: android-boot {
+			header-version = <2>;
+			page-size = <0x800>;
+			base = <0x80000000>;
+			kernel-offset = <0x00008000>;
+			ramdisk-offset = <0x01000000>;
+			tags-offset = <0x00000100>;
+			dtb-offset = <0x01f00000>;
+			boot-name = "test-board";
+			cmdline = CMDLINE(
+					  This is a very long commandline that is sure to exceed the
+					  512 chars that is allotted to the cmdline and this should
+					  spillover into extra_cmdline which is useful from a
+					  function testing standpoint. Gosh, it sure it hard to come
+					  up with enough filler text here to get over the 512 char
+					  limit though, huh? Even for someone as loquacious as
+					  myself. So anyway. How's your day going? I wrote a binman
+					  functional test today. It was fun. Did you know that
+					  binman is great. I like binman. I also like functional
+					  tests.. sup);
+
+			kernel {
+				u-boot {
+					no-expanded;
+				};
+			};
+
+			dtb {
+				u-boot-dtb {
+				};
+			};
+		};
+	};
+};
diff --git a/tools/binman/test/android_boot_v2_missing_dtb.dts b/tools/binman/test/android_boot_v2_missing_dtb.dts
new file mode 100644
index 00000000000..bf7bee622c4
--- /dev/null
+++ b/tools/binman/test/android_boot_v2_missing_dtb.dts
@@ -0,0 +1,12 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		android-boot {
+			header-version = <2>;
+			kernel {};
+		};
+	};
+};
diff --git a/tools/binman/test/android_boot_v2_pagesize_too_smol.dts b/tools/binman/test/android_boot_v2_pagesize_too_smol.dts
new file mode 100644
index 00000000000..0761ff20543
--- /dev/null
+++ b/tools/binman/test/android_boot_v2_pagesize_too_smol.dts
@@ -0,0 +1,13 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		android-boot {
+			header-version = <2>;
+			page-size = <32>;
+			kernel {};
+		};
+	};
+};
diff --git a/tools/binman/test/android_boot_v2_vendor_dt.dts b/tools/binman/test/android_boot_v2_vendor_dt.dts
new file mode 100644
index 00000000000..a7684d8492a
--- /dev/null
+++ b/tools/binman/test/android_boot_v2_vendor_dt.dts
@@ -0,0 +1,14 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		android-boot {
+			header-version = <2>;
+			kernel {};
+			dtb {};
+			vendor-dt {};
+		};
+	};
+};

-- 
2.54.0

