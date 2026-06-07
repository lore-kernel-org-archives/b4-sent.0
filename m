From: Sam Day <me@samcday.com>
Date: Mon, 08 Jun 2026 09:37:12 +1000
Subject: [PATCH v2 3/8] binman: android_boot: vendor-dt support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-android-binman-v2-3-b8203682507f@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780875433; l=8105;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=GQgb51aLgFmcyCU/kZdYTjDq4Hwe1k3YAmd3h0qEd24=;
 b=lqPxszgR4ljxPt908nQxFNgQe5SU2WHYc15yWmMDebffc5+r6VmbCCoGgMEVZs2trYMzMtCiv
 0gZfq2aawJZC5FcVVmC2jgTJN4HbwAd11I0AINBfnJLkGFj+JbUcrXT
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There's many Android bootloaders out there that expect non-standard
abootimgs. Samsung and Qualcomm, and likely many others. This quirk has
been codified in the widely used osm0sis fork/rewrite of mkbootimg.

Presumably, these vendor-specific abootimgs were conceived before the v2
format was widely available or specified. The evidence for this is their
hijacking of the header_version field to specify the length of a payload
that follows the main abootimg.

At least QCDT and DTBH (both of which will be implemented as binman
etypes in following commits) use this approach.

Link: https://github.com/osm0sis/mkbootimg
Signed-off-by: Sam Day <me@samcday.com>
---
 tools/binman/etype/android_boot.py                 | 37 ++++++++++++++++++++--
 tools/binman/ftest.py                              | 11 ++++++-
 .../binman/test/vendor/android_boot_vendor_dt.dts  | 27 ++++++++++++++++
 3 files changed, 72 insertions(+), 3 deletions(-)

diff --git a/tools/binman/etype/android_boot.py b/tools/binman/etype/android_boot.py
index 5af7d48e16b..5b0f08f27db 100644
--- a/tools/binman/etype/android_boot.py
+++ b/tools/binman/etype/android_boot.py
@@ -40,6 +40,9 @@ class Entry_android_boot(Entry_section):
     A kernel payload, optional ramdisk payload can be supplied. A DTB payload
     can also be provided when header_version == v2.
 
+    Vendor-specific payloads are also supported. These are non-standard
+    v0 images with a special DT container format appended.
+
     Properties / Entry arguments:
         - header-version: Android boot image header version, must be 0 or 2,
           defaults to 0
@@ -57,6 +60,7 @@ class Entry_android_boot(Entry_section):
         - kernel: section containing the executable payload
         - dtb: section containing the DTB payload, used by header version 2 only
         - ramdisk: optional section containing a ramdisk payload
+        - vendor-dt: legacy vendor DT payload, used by header version 0 only
 
     Example::
         A v2 abootimg with control FDT placed in the DTB section:
@@ -117,6 +121,7 @@ class Entry_android_boot(Entry_section):
         self.os_version = fdt_util.GetInt(self._node, 'os-version', 0)
         self.boot_name = fdt_util.GetString(self._node, 'boot-name', '')
         self.cmdline = fdt_util.GetString(self._node, 'cmdline', '')
+        self.vendor_dt_node = self._node.FindNode('vendor-dt')
 
         if self.header_version not in (0, 2):
             self.Raise('Only Android boot image header versions 0 and 2 are '
@@ -131,17 +136,26 @@ class Entry_android_boot(Entry_section):
                 self.Raise('page-size must fit the Android boot image header')
             if 'dtb' in self._entries:
                 self.Raise("Subnode 'dtb' requires header-version 2")
+            if self.vendor_dt_node and self.os_version:
+                self.Raise("os_version not allowed when vendor-dt is in use")
         else:
             # v2
             if self.page_size < BOOT_IMAGE_HEADER_V2_SIZE:
                 self.Raise('page-size must fit the Android boot image header')
             if 'dtb' not in self._entries:
                 self.Raise("Missing required subnode 'dtb'")
+            if self.vendor_dt_node:
+                self.Raise("Subnode 'vendor-dt' requires header-version 0")
 
     def ReadEntries(self):
         for node in self._node.subnodes:
             if self.IsSpecialSubnode(node):
                 continue
+
+            if node.name == 'vendor-dt':
+                self._ReadVendorDtEntries(node)
+                continue
+
             if node.name not in ('kernel', 'ramdisk', 'dtb'):
                 self.Raise("Unexpected subnode '%s'" % node.name)
 
@@ -152,6 +166,15 @@ class Entry_android_boot(Entry_section):
             entry.SetPrefix(self._name_prefix)
             self._entries[node.name] = entry
 
+    def _ReadVendorDtEntries(self, vendor_dt_node):
+        entry = Entry.Create(self, vendor_dt_node, etype='section',
+                             expanded=self.GetImage().use_expanded,
+                             missing_etype=self.GetImage().missing_etype)
+        entry.page_size = fdt_util.GetInt(self._node, 'page-size', 2048)
+        entry.ReadNode()
+        entry.SetPrefix(self._name_prefix)
+        self._entries[vendor_dt_node.name] = entry
+
     def _GetIntCells(self, propname, default):
         prop = self._node.props.get(propname)
         if not prop:
@@ -219,11 +242,18 @@ class Entry_android_boot(Entry_section):
 
         return data
 
+    def _BuildVendorDt(self, required):
+        if not self.vendor_dt_node:
+            return b''
+        return self._GetEntryData('vendor-dt', required)
+
     def _BuildV0SectionData(self, required):
         kernel = self._GetEntryData('kernel', required)
         if kernel is None:
             return None
-
+        vendor_dt = self._BuildVendorDt(required)
+        if vendor_dt is None:
+            return None
         ramdisk = self._GetOptionalEntryData('ramdisk', required)
         if ramdisk is None:
             return None
@@ -234,6 +264,8 @@ class Entry_android_boot(Entry_section):
                                  BOOT_ARGS_SIZE)
 
         boot_id_payloads = [kernel, ramdisk, b'']
+        if self.vendor_dt_node:
+            boot_id_payloads.append(vendor_dt)
         image_id = self._BootId(*boot_id_payloads)
 
         header = struct.pack(BOOT_IMAGE_HEADER_V0,
@@ -246,7 +278,7 @@ class Entry_android_boot(Entry_section):
                              0, # second_offset
                              self._GetAddr(self.tags_offset, 'tags'),
                              self.page_size,
-                             self.header_version,
+                             len(vendor_dt),
                              self.os_version,
                              boot_name,
                              cmdline,
@@ -256,6 +288,7 @@ class Entry_android_boot(Entry_section):
         image += _pad(header, self.page_size)
         image += _pad(kernel, self.page_size)
         image += _pad(ramdisk, self.page_size)
+        image += _pad(vendor_dt, self.page_size)
 
         return bytes(image)
 
diff --git a/tools/binman/ftest.py b/tools/binman/ftest.py
index e92a231417b..80219e519f6 100644
--- a/tools/binman/ftest.py
+++ b/tools/binman/ftest.py
@@ -5662,7 +5662,16 @@ fdt         fdtmap                Extract the devicetree blob from the fdtmap
         self.assertEqual(U_BOOT_DTB_DATA,
                          data[0x1000:0x1000 + len(U_BOOT_DTB_DATA)])
 
-        self.assertEqual(U_BOOT_DATA, data[0x800:0x800 + len(U_BOOT_DATA)])
+    def testAndroidBootVendorDt(self):
+        """Test that android-boot can embed an arbitrary vendor-dt section"""
+        data = self._DoReadFile('vendor/android_boot_vendor_dt.dts')
+        header = struct.unpack_from('<8s10I16s512s32s', data, 0)
+        vendor_dt = b'howdy'
+        self.assertEqual(len(vendor_dt), header[9])
+        self.assertEqual(0, header[10])
+        self.assertEqual(self._AndroidBootId(U_BOOT_DATA, b'\0', b'',
+                                             vendor_dt), header[13])
+        self.assertEqual(vendor_dt, data[0x1800:0x1805])
 
     def testFitFdtOper(self):
         """Check handling of a specified FIT operation"""
diff --git a/tools/binman/test/vendor/android_boot_vendor_dt.dts b/tools/binman/test/vendor/android_boot_vendor_dt.dts
new file mode 100644
index 00000000000..194396a0880
--- /dev/null
+++ b/tools/binman/test/vendor/android_boot_vendor_dt.dts
@@ -0,0 +1,27 @@
+// SPDX-License-Identifier: GPL-2.0+
+/dts-v1/;
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+	binman {
+		android-boot {
+			header-version = <0>;
+			kernel {
+				u-boot {
+					no-expanded;
+				};
+			};
+			ramdisk {
+				fill {
+					size = <1>;
+				};
+			};
+			vendor-dt {
+				text {
+					size = <5>;
+					text = "howdy";
+				};
+			};
+		};
+	};
+};

-- 
2.54.0

