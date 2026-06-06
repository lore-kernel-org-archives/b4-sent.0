From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 10:52:35 +1000
Subject: [PATCH 01/13] binman: Android boot image support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-android-binman-v1-1-c7a3c14b8a3d@samcday.com>
References: <20260606-android-binman-v1-0-c7a3c14b8a3d@samcday.com>
In-Reply-To: <20260606-android-binman-v1-0-c7a3c14b8a3d@samcday.com>
To: u-boot@lists.denx.de, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Bryan Brattlof <bb@ti.com>, 
 Yannic Moog <y.moog@phytec.de>, Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Yegor Yefremov <yegorslists@googlemail.com>, 
 Denis Mukhin <dmukhin@ford.com>, Rasmus Villemoes <ravi@prevas.dk>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, Javier Tia <floss@jetm.me>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Minkyu Kang <mk7.kang@samsung.com>, 
 Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Henrik Grimler <henrik@grimler.se>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780707158; l=19454;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=yuVLY8MAUAkmt0erq0eQjYaAN4jKDbG++C9AbZFyHjI=;
 b=gscowGUeBNoo0Dr2yfXMb+BKjjEg4oD973GjUlDB6DOxyzqubJKNCiRFwf6yY4zETMFV7Uoyv
 PVDTTRcTQAYD+M7Nx5qhTyrHqKa2GuCjX6XK54xyi3WzKYztW4FPtIZ
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce initial support for Android boot images (abootimgs). This
initial stab supports both v0 and v2 headers. The AOSP implementation
was used as a reference.

Since we're targeting U-Boot use cases here, a couple of things were
omitted from this impl, namely "second" and recovery_dtbo support.

Link: https://android.googlesource.com/platform/system/tools/mkbootimg/
Signed-off-by: Sam Day <me@samcday.com>
---
 tools/binman/etype/android_boot.py           | 337 +++++++++++++++++++++++++++
 tools/binman/ftest.py                        |  66 ++++++
 tools/binman/test/vendor/android_boot_v0.dts |  29 +++
 tools/binman/test/vendor/android_boot_v2.dts |  46 ++++
 4 files changed, 478 insertions(+)

diff --git a/tools/binman/etype/android_boot.py b/tools/binman/etype/android_boot.py
new file mode 100644
index 00000000000..adf8248ee12
--- /dev/null
+++ b/tools/binman/etype/android_boot.py
@@ -0,0 +1,337 @@
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
+def _align_up(value, align):
+    return (value + align - 1) & ~(align - 1)
+
+
+def _pad(data, align):
+    return data + b'\0' * (_align_up(len(data), align) - len(data))
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
+        A v0 abootimg with embedded control FDT (v0 doesn't support DTBs) and
+        an empty ramdisk (some bootloaders insist on a ramdisk being present):
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
+            if self.IsSpecialSubnode(node):
+                continue
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
+    @staticmethod
+    def _CheckFit(name, data, size):
+        if len(data) > size:
+            raise ValueError('%s is %d bytes, maximum is %d' %
+                             (name, len(data), size))
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
+    def _GetEntryData(self, name, required):
+        entry = self._entries.get(name)
+        data = entry.GetData(required)
+        if data is None and not required:
+            return None
+
+        return data
+
+    def _GetOptionalEntryData(self, name, required, default=b''):
+        entry = self._entries.get(name)
+        if not entry:
+            return default
+
+        data = entry.GetData(required)
+        if data is None and not required:
+            return None
+
+        return data
+
+    @staticmethod
+    def _BuildDtb(node):
+        import libfdt
+
+        fsw = libfdt.FdtSw()
+        fsw.INC_SIZE = 65536
+        fsw.finish_reservemap()
+
+        def _AddNode(in_node):
+            for pname, prop in in_node.props.items():
+                fsw.property(pname, prop.bytes)
+            for subnode in in_node.subnodes:
+                with fsw.add_node(subnode.name):
+                    _AddNode(subnode)
+
+        with fsw.add_node(''):
+            _AddNode(node)
+            if not node.FindNode('chosen'):
+                with fsw.add_node('chosen'):
+                    pass
+        fdt = fsw.as_fdt()
+        fdt.pack()
+        return bytes(fdt.as_bytearray())
+
+    def _BuildV0SectionData(self, required):
+        kernel = self._GetEntryData('kernel', required)
+        if kernel is None:
+            return None
+
+        ramdisk = self._GetOptionalEntryData('ramdisk', required)
+        if ramdisk is None:
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
+        image += _pad(header, self.page_size)
+        image += _pad(kernel, self.page_size)
+        image += _pad(ramdisk, self.page_size)
+
+        return bytes(image)
+
+    def _BuildV2SectionData(self, required):
+        kernel = self._GetEntryData('kernel', required)
+        if kernel is None:
+            return None
+
+        dtb = self._GetEntryData('dtb', required)
+        if dtb is None:
+            return None
+
+        ramdisk = self._GetOptionalEntryData('ramdisk', required)
+        if ramdisk is None:
+            return None
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
+        image += _pad(header, self.page_size)
+        image += _pad(kernel, self.page_size)
+        image += _pad(ramdisk, self.page_size)
+        image += _pad(dtb, self.page_size)
+
+        return bytes(image)
+
+    def BuildSectionData(self, required):
+        if self.header_version == 0:
+            return self._BuildV0SectionData(required)
+
+        return self._BuildV2SectionData(required)
diff --git a/tools/binman/ftest.py b/tools/binman/ftest.py
index 9a3811c1732..e92a231417b 100644
--- a/tools/binman/ftest.py
+++ b/tools/binman/ftest.py
@@ -5598,6 +5598,72 @@ fdt         fdtmap                Extract the devicetree blob from the fdtmap
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
+    def testAndroidBootV0(self):
+        """Test that binman can produce a plain legacy Android boot image"""
+        data = self._DoReadFile('vendor/android_boot_v0.dts')
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
+    def testAndroidBootV2(self):
+        """Test that binman can produce an Android boot image"""
+        data = self._DoReadFile('vendor/android_boot_v2.dts')
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
+        self.assertEqual(U_BOOT_DATA, data[0x800:0x800 + len(U_BOOT_DATA)])
+
     def testFitFdtOper(self):
         """Check handling of a specified FIT operation"""
         entry_args = {
diff --git a/tools/binman/test/vendor/android_boot_v0.dts b/tools/binman/test/vendor/android_boot_v0.dts
new file mode 100644
index 00000000000..ec97741e754
--- /dev/null
+++ b/tools/binman/test/vendor/android_boot_v0.dts
@@ -0,0 +1,29 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	binman {
+		android-boot {
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
diff --git a/tools/binman/test/vendor/android_boot_v2.dts b/tools/binman/test/vendor/android_boot_v2.dts
new file mode 100644
index 00000000000..20de6e2f1af
--- /dev/null
+++ b/tools/binman/test/vendor/android_boot_v2.dts
@@ -0,0 +1,46 @@
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
+		android-boot {
+			header-version = <2>;
+			page-size = <0x800>;
+			base = <0x80000000>;
+			kernel-offset = <0x00008000>;
+			ramdisk-offset = <0x01000000>;
+			second-offset = <0x00f00000>;
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

-- 
2.54.0

