From: Sam Day <me@samcday.com>
Date: Mon, 08 Jun 2026 09:37:15 +1000
Subject: [PATCH v2 6/8] binman: Add DTBH support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-android-binman-v2-6-b8203682507f@samcday.com>
References: <20260608-android-binman-v2-0-b8203682507f@samcday.com>
In-Reply-To: <20260608-android-binman-v2-0-b8203682507f@samcday.com>
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
 Henrik Grimler <henrik@grimler.se>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780875433; l=10971;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=wTL3ixG4dvQtSEKNkxymUSexx1/w+eyUxys9adZuNnI=;
 b=oudZ/nvwNMDT7mauMw127xO9s9gdzmolSuvZSMKIEzG+IdfG6kCudXJDbSuMKh8xycKEOcgtI
 mUs5LDD8dsAB9dYYLaSNaquLnbdk6httvImc7Q4qnykngeB/3wDyN7r
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DTBH, used by Samsung S-BOOT bootloaders, is similar to QCDT. That is,
it's a multi-record container that carries vendor-specific magic values
to assist the previous bootloader in picking the appropriate FDT for the
booting device.

dtbTool-exynos was used as a reference for this implementation.

Link: https://github.com/dsankouski/dtbtool-exynos
Signed-off-by: Sam Day <me@samcday.com>
---
 tools/binman/etype/android_boot.py               |  20 +++
 tools/binman/etype/dtbh.py                       | 173 +++++++++++++++++++++++
 tools/binman/ftest.py                            |  24 ++++
 tools/binman/test/vendor/dtbh.dts                |  29 ++++
 tools/binman/test/vendor/dtbh_bad_model_info.dts |  19 +++
 5 files changed, 265 insertions(+)

diff --git a/tools/binman/etype/android_boot.py b/tools/binman/etype/android_boot.py
index c7acb2bb66e..291de6ac9b0 100644
--- a/tools/binman/etype/android_boot.py
+++ b/tools/binman/etype/android_boot.py
@@ -141,6 +141,26 @@ class Entry_android_boot(Entry_section):
                 };
             };
         };
+
+        A legacy DTBH abootimg, the kind some Samsung bootloaders expect:
+
+        android-boot {
+            header-version = <0>;
+
+            kernel {
+                u-boot-nodtb {
+                };
+            };
+
+            vendor-dt {
+                dtbh {
+                    dtb-0 {
+                        u-boot-dtb {
+                        };
+                    };
+                };
+            };
+        };
     """
 
     def ReadNode(self):
diff --git a/tools/binman/etype/dtbh.py b/tools/binman/etype/dtbh.py
new file mode 100644
index 00000000000..90769e5d016
--- /dev/null
+++ b/tools/binman/etype/dtbh.py
@@ -0,0 +1,173 @@
+# SPDX-License-Identifier: GPL-2.0+
+# Entry-type module for Samsung Android DTBH tables
+
+import struct
+
+from binman.entry import Entry
+from binman.etype.section import Entry_section
+from dtoc import fdt_util
+
+
+DTBH_MAGIC = b'DTBH'
+DTBH_VERSION = 2
+DTBH_PLATFORM_CODE_DEF = 0x50a6
+DTBH_SUBTYPE_CODE_DEF = 0x217584da
+DTBH_SPACE = 0x20
+
+
+def _align_up(value, align):
+    return (value + align - 1) & ~(align - 1)
+
+
+def _pad(data, align):
+    return data + b'\0' * (_align_up(len(data), align) - len(data))
+
+
+class Entry_dtbh(Entry_section):
+    """Samsung Android device tree table
+
+    This creates a DTBH table, the legacy device-tree table format used by
+    some Samsung Android bootloaders.
+
+    Properties / Entry arguments:
+        - page-size: DTBH page size, defaults to the parent android-boot page
+          size or 2048 when used elsewhere
+        - platform: DTBH platform code, defaults to 0x50a6
+        - subtype: DTBH subtype code, defaults to 0x217584da
+
+    This entry uses the following subnodes:
+        - dtb-*: DTB records, each containing exactly one DTB payload entry
+
+    Each payload DTB must contain these root properties:
+        - model_info-chip
+        - model_info-hw_rev
+        - model_info-hw_rev_end
+
+    Example::
+
+        dtbh {
+            dtb-0 {
+                u-boot-dtb {
+                };
+            };
+        };
+    """
+
+    @staticmethod
+    def _DtbEntryName(node):
+        return '_dtb_%s' % node.name
+
+    def _GetPayloadSubnodes(self, node):
+        return [subnode for subnode in node.subnodes
+                if not self.IsSpecialSubnode(subnode)]
+
+    def ReadNode(self):
+        super().ReadNode()
+        self._page_size = fdt_util.GetInt(self._node, 'page-size')
+        if (self._page_size is not None and
+                (self._page_size <= 0 or
+                 self._page_size & (self._page_size - 1))):
+            self.Raise('page-size must be a power of two')
+        self.platform = fdt_util.GetInt(self._node, 'platform',
+                                        DTBH_PLATFORM_CODE_DEF)
+        self.subtype = fdt_util.GetInt(self._node, 'subtype',
+                                       DTBH_SUBTYPE_CODE_DEF)
+
+    def ReadEntries(self):
+        for node in self._node.subnodes:
+            if self.IsSpecialSubnode(node):
+                continue
+
+            payloads = self._GetPayloadSubnodes(node)
+            if len(payloads) > 1:
+                raise ValueError("Node '%s': must contain exactly one DTB "
+                                 "payload subnode" % node.path)
+            if not payloads:
+                continue
+
+            entry = Entry.Create(self, payloads[0],
+                                 expanded=self.GetImage().use_expanded,
+                                 missing_etype=self.GetImage().missing_etype)
+            entry.ReadNode()
+            entry.SetPrefix(self._name_prefix)
+            self._entries[self._DtbEntryName(node)] = entry
+
+    def _GetPageSize(self):
+        if self._page_size is not None:
+            return self._page_size
+
+        return getattr(self.section, 'page_size', 2048)
+
+    def _GetDtbData(self, node, required):
+        entry = self._entries.get(self._DtbEntryName(node))
+        if not entry:
+            raise ValueError("Node '%s': Missing required DTB payload subnode" %
+                             node.path)
+
+        data = entry.GetData(required)
+        if data is None and not required:
+            return None
+
+        return data
+
+    @staticmethod
+    def _GetDtbRootU32(node, data, propname):
+        import libfdt
+
+        try:
+            fdt = libfdt.Fdt(data)
+            root = fdt.path_offset('/')
+            prop = fdt.getprop(root, propname)
+        except libfdt.FdtException as exc:
+            raise ValueError("Node '%s': Missing required DTB root property "
+                             "'%s'" % (node.path, propname)) from exc
+
+        if len(prop) != 4:
+            raise ValueError("Node '%s': DTB root property '%s' must contain "
+                             "exactly 1 cell" % (node.path, propname))
+
+        return fdt_util.fdt32_to_cpu(prop)
+
+    def BuildSectionData(self, required):
+        if not self._node.subnodes:
+            raise ValueError("Node '%s': Missing required DTB subnodes" %
+                             self._node.path)
+
+        page_size = self._GetPageSize()
+        dtbs = []
+        for node in self._node.subnodes:
+            if self.IsSpecialSubnode(node):
+                continue
+
+            data = self._GetDtbData(node, required)
+            if data is None and not required:
+                return None
+
+            chip = self._GetDtbRootU32(node, data, 'model_info-chip')
+            hw_rev = self._GetDtbRootU32(node, data, 'model_info-hw_rev')
+            hw_rev_end = self._GetDtbRootU32(node, data,
+                                             'model_info-hw_rev_end')
+            dtbs.append((chip, self.platform, self.subtype, hw_rev,
+                         hw_rev_end, data))
+
+        if not dtbs:
+            raise ValueError("Node '%s': Missing required DTB subnodes" %
+                             self._node.path)
+
+        header_size = _align_up(12 + len(dtbs) * 32 + 4, page_size)
+        dtb_offset = header_size
+        records = []
+        payloads = bytearray()
+        for chip, platform, subtype, hw_rev, hw_rev_end, dtb in dtbs:
+            dtb_size = _align_up(len(dtb), page_size)
+            records.append((chip, platform, subtype, hw_rev, hw_rev_end,
+                            dtb_offset, dtb_size, DTBH_SPACE))
+            payloads += _pad(dtb, page_size)
+            dtb_offset += dtb_size
+
+        dtbh = bytearray(struct.pack('<4sII', DTBH_MAGIC, DTBH_VERSION,
+                                     len(records)))
+        for record in records:
+            dtbh += struct.pack('<8I', *record)
+
+        return _pad(dtbh, page_size) + bytes(payloads)
diff --git a/tools/binman/ftest.py b/tools/binman/ftest.py
index 1f3e94908d9..df544992e07 100644
--- a/tools/binman/ftest.py
+++ b/tools/binman/ftest.py
@@ -5701,6 +5701,30 @@ fdt         fdtmap                Extract the devicetree blob from the fdtmap
         self.assertIn("Property 'qcom,msm-id' must contain exactly 2 cells",
                       str(exc.exception))
 
+    def testAndroidBootDtbh(self):
+        """Test that binman can produce a DTBH container"""
+        data, dtb_data, _map, _dtb = self._DoReadFileDtb(
+            'vendor/dtbh.dts', use_real_dtb=True)
+
+        dtb_size = tools.align(len(dtb_data), 0x800)
+
+        self.assertEqual(b'DTBH', data[:4])
+        self.assertEqual((2, 1), struct.unpack_from('<II', data, 4))
+        self.assertEqual((7870, 0x50a6, 0x217584da, 6, 6, 0x800,
+                          dtb_size, 0x20),
+                         struct.unpack_from('<8I', data, 12))
+        self.assertEqual(0xd00dfeed,
+                         struct.unpack_from('>I', data, 0x800)[0])
+        self.assertEqual(dtb_data, data[0x800:0x800 + len(dtb_data)])
+
+    def testAndroidBootDtbhBadModelInfo(self):
+        """Test that DTBH rejects invalid model_info properties"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFileDtb('vendor/dtbh_bad_model_info.dts',
+                                use_real_dtb=True)
+        self.assertIn("DTB root property 'model_info-chip' must contain "
+                      "exactly 1 cell", str(exc.exception))
+
     def testFitFdtOper(self):
         """Check handling of a specified FIT operation"""
         entry_args = {
diff --git a/tools/binman/test/vendor/dtbh.dts b/tools/binman/test/vendor/dtbh.dts
new file mode 100644
index 00000000000..934a76dde59
--- /dev/null
+++ b/tools/binman/test/vendor/dtbh.dts
@@ -0,0 +1,29 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	#address-cells = <2>;
+	#size-cells = <1>;
+	model = "Samsung Galaxy J7 (2016)";
+	compatible = "samsung,j7xelte", "samsung,exynos7870";
+	model_info-chip = <7870>;
+	model_info-hw_rev = <6>;
+	model_info-hw_rev_end = <6>;
+
+	chosen {
+	};
+
+	memory@40000000 {
+		device_type = "memory";
+		reg = <0 0x40000000 0x3e400000>;
+	};
+
+	binman {
+		dtbh {
+			dtb-0 {
+				u-boot-dtb {};
+			};
+		};
+	};
+};
diff --git a/tools/binman/test/vendor/dtbh_bad_model_info.dts b/tools/binman/test/vendor/dtbh_bad_model_info.dts
new file mode 100644
index 00000000000..58c368e71dc
--- /dev/null
+++ b/tools/binman/test/vendor/dtbh_bad_model_info.dts
@@ -0,0 +1,19 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	#address-cells = <2>;
+	#size-cells = <1>;
+	model_info-chip = <7870 1>;
+	model_info-hw_rev = <6>;
+	model_info-hw_rev_end = <6>;
+
+	binman {
+		dtbh {
+			dtb-0 {
+				u-boot-dtb {};
+			};
+		};
+	};
+};

-- 
2.54.0

