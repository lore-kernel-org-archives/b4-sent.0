From: Sam Day <me@samcday.com>
Date: Wed, 10 Jun 2026 11:27:45 +1000
Subject: [PATCH v3 07/10] binman: Add QCDT support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-android-binman-v3-7-710298a38fcc@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781054859; l=19523;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=kKIOBgCfw8CwjZXYhzBAj7pVFU1WSSUL1LlBASMjr1s=;
 b=Q9DWksI4bzXaiH0ulTC0wlI8SuLPDCsKFpFbzudyfVDEP1E8CHQhd81O9GeAvlgF+qwUSGnrS
 WK379cIxligB9mNgQVTYvIIpcC3YQwtTMFXOwPlhLObw0qFOBMYgBO7
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This vendor-specific format is used by many bootloaders on older qcom
SoCs, such as msm8916. It's a container for N FDTs. Each one is
contained in a record that includes metadata about the platform/variant
it targets. The previous bootloader picks the "right" record based on
this metadata.

This initial impl targets a streamlined v2 path, with no support for
different versions or multiple qcom,msm-id/qcom,board-id tuples. If/when
that's needed it will be implemented in a follow-up.

In the following commit, support for DTBH will also be introduced.
Because QCDT and DTBH share a lot of common behaviour, this commit also
introduces a Entry_Android_vendor_dt_table base class.

This impl was based on the lk2nd/CAF LK dtbTool script.

Link: https://github.com/msm8916-mainline/lk2nd/blob/main/lk2nd/scripts/dtbTool
Signed-off-by: Sam Day <me@samcday.com>
---
 tools/binman/android_vendor_dt_table.py            | 104 +++++++++++++++++++++
 tools/binman/etype/android_boot.py                 |  31 ++++++
 tools/binman/etype/qcdt.py                         |  80 ++++++++++++++++
 tools/binman/ftest.py                              |  96 +++++++++++++++++++
 tools/binman/test/qcdt.dts                         |  36 +++++++
 tools/binman/test/qcdt_bad_msm_id.dts              |  17 ++++
 tools/binman/test/qcdt_invalid_pagesize.dts        |  12 +++
 tools/binman/test/qcdt_missing_msm_id.dts          |  12 +++
 tools/binman/test/qcdt_missing_payload.dts         |  14 +++
 tools/binman/test/qcdt_missing_subnodes.dts        |  13 +++
 tools/binman/test/qcdt_multiple_dtbs.dts           |  34 +++++++
 tools/binman/test/qcdt_page_size_from_abootimg.dts |  33 +++++++
 tools/binman/test/qcdt_zero_pagesize.dts           |  12 +++
 13 files changed, 494 insertions(+)

diff --git a/tools/binman/android_vendor_dt_table.py b/tools/binman/android_vendor_dt_table.py
new file mode 100644
index 00000000000..91b785f274e
--- /dev/null
+++ b/tools/binman/android_vendor_dt_table.py
@@ -0,0 +1,104 @@
+# SPDX-License-Identifier: GPL-2.0+
+
+from binman.entry import Entry
+from binman.etype.section import Entry_section
+from dtoc import fdt_util
+
+
+class Entry_Android_vendor_dt_table(Entry_section):
+    """Base class for legacy Android vendor DT table entries"""
+
+    @staticmethod
+    def _DtbEntryName(node):
+        return '_dtb_%s' % node.name
+
+    def ReadNode(self):
+        super().ReadNode()
+        self._page_size = fdt_util.GetInt(self._node, 'page-size')
+        if (self._page_size is not None and
+                (self._page_size <= 0 or
+                 self._page_size & (self._page_size - 1))):
+            self.Raise('page-size must be a power of two')
+
+    def _GetPayloadSubnodes(self, node):
+        return [subnode for subnode in node.subnodes
+                if not self.IsSpecialSubnode(subnode)]
+
+    def ReadEntries(self):
+        for node in self._node.subnodes:
+            if self.IsSpecialSubnode(node):
+                continue
+
+            payloads = self._GetPayloadSubnodes(node)
+            if len(payloads) > 1:
+                self.Raise("subnode '%s': must contain exactly one DTB "
+                           "payload subnode" % node.name)
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
+        section = self.section
+        while section:
+            if section.etype == 'android-boot':
+                return section.page_size
+            section = section.section
+
+        return 2048
+
+    def _GetU32Cells(self, node, propname):
+        prop = node.props.get(propname)
+        if not prop:
+            self.Raise("subnode '%s': Missing required property '%s'" %
+                       (node.name, propname))
+
+        values = prop.value if isinstance(prop.value, list) else [prop.value]
+        return [fdt_util.fdt32_to_cpu(value) for value in values]
+
+    def _GetU32Tuple(self, node, propname, width):
+        values = self._GetU32Cells(node, propname)
+        if len(values) != width:
+            self.Raise("subnode '%s': Property '%s' must contain exactly "
+                       "%d cells" % (node.name, propname, width))
+
+        return tuple(values)
+
+    def _GetDtbData(self, node, required):
+        entry = self._entries.get(self._DtbEntryName(node))
+        if not entry:
+            self.Raise("subnode '%s': Missing required DTB payload subnode" %
+                       node.name)
+
+        data = entry.GetData(required)
+        if data is None and not required:
+            return None
+
+        return data
+
+    def _GetDtbRecordData(self, node, required):
+        return self._GetDtbData(node, required)
+
+    def _ReadDtbRecords(self, required, read_record):
+        records = []
+        for node in self._node.subnodes:
+            if self.IsSpecialSubnode(node):
+                continue
+
+            data = self._GetDtbRecordData(node, required)
+            if data is None and not required:
+                return None
+            records.append(read_record(node, data))
+
+        if not records:
+            self.Raise('Missing required DTB subnodes')
+
+        return records
diff --git a/tools/binman/etype/android_boot.py b/tools/binman/etype/android_boot.py
index 5cfa71ee981..57900e3d523 100644
--- a/tools/binman/etype/android_boot.py
+++ b/tools/binman/etype/android_boot.py
@@ -102,6 +102,37 @@ class Entry_android_boot(Entry_section):
                 };
             };
         };
+
+    Example::
+        A legacy QCDT abootimg, the kind msm8916 bootloaders expect:
+
+        android-boot {
+            base = <0x80000000>;
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
+
+            vendor-dt {
+                qcdt {
+                    dtb-0 {
+                        qcom,msm-id = <206 0>;
+                        qcom,board-id = <0xce08ff01 1>;
+
+                        u-boot-dtb {
+                        };
+                    };
+                };
+            };
+        };
     """
 
     def ReadNode(self):
diff --git a/tools/binman/etype/qcdt.py b/tools/binman/etype/qcdt.py
new file mode 100644
index 00000000000..ccf566af29f
--- /dev/null
+++ b/tools/binman/etype/qcdt.py
@@ -0,0 +1,80 @@
+# SPDX-License-Identifier: GPL-2.0+
+# Entry-type module for Qualcomm Android device tree tables
+
+import struct
+
+from binman.android_vendor_dt_table import Entry_Android_vendor_dt_table
+
+
+QCDT_MAGIC = b'QCDT'
+QCDT_VERSION = 2
+QCDT_HEADER = '<4sII'
+QCDT_HEADER_SIZE = struct.calcsize(QCDT_HEADER)
+QCDT_RECORD = '<IIIIII'
+QCDT_RECORD_SIZE = struct.calcsize(QCDT_RECORD)
+
+
+class Entry_qcdt(Entry_Android_vendor_dt_table):
+    """Qualcomm Android device tree table
+
+    This creates a QCDT table, the legacy device-tree table format used by
+    some Qualcomm Android bootloaders.
+
+    Properties / Entry arguments:
+        - page-size: QCDT page size, defaults to 2048, unless there's a parent
+          android-boot node with an explicit page-size
+
+    This entry uses the following subnodes:
+        - dtb-*: DTB records, each containing qcom,msm-id, qcom,board-id and
+          exactly one DTB payload entry
+
+    Example::
+
+        qcdt {
+            dtb-0 {
+                qcom,msm-id = <206 0>;
+                qcom,board-id = <0xce08ff01 1>;
+
+                u-boot-dtb {
+                };
+            };
+        };
+    """
+
+    def _GetDtbRecordData(self, node, required):
+        msm_id = self._GetU32Tuple(node, 'qcom,msm-id', 2)
+        board_id = self._GetU32Tuple(node, 'qcom,board-id', 2)
+        data = super()._GetDtbRecordData(node, required)
+        if data is None and not required:
+            return None
+
+        return (msm_id, board_id, data)
+
+    def _ReadDtbRecord(self, node, data):
+        return data
+
+    def BuildSectionData(self, required):
+        page_size = self._GetPageSize()
+        dtbs = self._ReadDtbRecords(required, self._ReadDtbRecord)
+        if dtbs is None:
+            return None
+
+        size = QCDT_HEADER_SIZE + len(dtbs) * QCDT_RECORD_SIZE
+        dtb_offset = self.AlignUp(size, page_size)
+        records = []
+        payloads = bytearray()
+        for msm_id, board_id, dtb in dtbs:
+            platform_id, soc_rev = msm_id
+            variant_id, board_hw_subtype = board_id
+            dtb_size = self.AlignUp(len(dtb), page_size)
+            records.append((platform_id, variant_id, board_hw_subtype,
+                            soc_rev, dtb_offset, dtb_size))
+            payloads += self.PadToAlignment(dtb, page_size)
+            dtb_offset += dtb_size
+
+        qcdt = bytearray(struct.pack(QCDT_HEADER, QCDT_MAGIC, QCDT_VERSION,
+                                     len(records)))
+        for record in records:
+            qcdt += struct.pack(QCDT_RECORD, *record)
+
+        return self.PadToAlignment(qcdt, page_size) + bytes(payloads)
diff --git a/tools/binman/ftest.py b/tools/binman/ftest.py
index bbdcb721eca..b18d584c688 100644
--- a/tools/binman/ftest.py
+++ b/tools/binman/ftest.py
@@ -5761,6 +5761,102 @@ fdt         fdtmap                Extract the devicetree blob from the fdtmap
                          data[vendor_dt_offset:vendor_dt_offset + page_size])
         self.assertEqual(vendor_dt_offset + page_size, len(data))
 
+    def testQcdt(self):
+        """Test that binman can produce a QCDT container"""
+        data, dtb_data, _map, _dtb = self._DoReadFileDtb(
+            'qcdt.dts', use_real_dtb=True)
+
+        dtb_size = tools.align(len(dtb_data), 0x800)
+
+        self.assertEqual(b'QCDT', data[:4])
+        self.assertEqual((2, 2), struct.unpack_from('<II', data, 4))
+        self.assertEqual((0xce, 0xce08ff01, 1, 0, 0x800, dtb_size),
+                          struct.unpack_from('<IIIIII', data, 12))
+        self.assertEqual((0xcf, 0xce08ff02, 2, 1, 0x800 + dtb_size,
+                          dtb_size), struct.unpack_from('<IIIIII', data, 36))
+        self.assertEqual(0xd00dfeed,
+                          struct.unpack_from('>I', data, 0x800)[0])
+        self.assertEqual(dtb_data, data[0x800:0x800 + len(dtb_data)])
+        self.assertEqual(dtb_data, data[0x800 + dtb_size:0x800 + dtb_size +
+                                         len(dtb_data)])
+
+    def testQcdtPageSizeFromParent(self):
+        """Test that QCDT inherits page-size from parent android-boot node"""
+        data, dtb_data, _map, _dtb = self._DoReadFileDtb(
+            'qcdt_page_size_from_abootimg.dts')
+
+        # header+kernel are aligned to 4096, vendor-dt follows after that.
+        vendor_dt_offset = 4096*2
+
+        self.assertEqual(b'QCDT', data[vendor_dt_offset:vendor_dt_offset + 4])
+        self.assertEqual((4096, 4096),
+                         struct.unpack_from('<16xII', data,
+                                            vendor_dt_offset + 12))
+
+    def testQcdtBadMsmId(self):
+        """Test that QCDT rejects invalid msm-id properties"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('qcdt_bad_msm_id.dts')
+        self.assertIn("Property 'qcom,msm-id' must contain exactly 2 cells",
+                      str(exc.exception))
+
+    def testQcdtMissingMsmId(self):
+        """Test that QCDT rejects missing qcom,msm-id"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('qcdt_missing_msm_id.dts')
+        self.assertIn("Missing required property 'qcom,msm-id'",
+                      str(exc.exception))
+
+    def testQcdtMissingDTBPayload(self):
+        """Test that QCDT rejects missing DTB payload"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('qcdt_missing_payload.dts')
+        self.assertIn("Missing required DTB payload subnode",
+                      str(exc.exception))
+
+    def testQcdtMissingSubnodes(self):
+        """Test that QCDT rejects missing dtb subnodes"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('qcdt_missing_subnodes.dts')
+        self.assertIn("Missing required DTB subnodes",
+                      str(exc.exception))
+
+    def testQcdtInvalidPageSize(self):
+        """Test that QCDT rejects invalid page-size"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('qcdt_invalid_pagesize.dts')
+        self.assertIn("page-size must be a power of two",
+                      str(exc.exception))
+
+    def testQcdtZeroPageSize(self):
+        """Test that QCDT rejects zero page-size"""
+        with self.assertRaises(ValueError) as exc:
+            self._DoReadFile('qcdt_zero_pagesize.dts')
+        self.assertIn("page-size must be a power of two",
+                      str(exc.exception))
+
+    def testQcdtMultipleDTBs(self):
+        """Test that QCDT handles multiple embedded DTBs"""
+        data = self._DoReadFile('qcdt_multiple_dtbs.dts')
+
+        page_size = 0x100
+        payload_size = page_size
+        payload_pad = tools.get_bytes(0, page_size - 1)
+
+        self.assertEqual(b'QCDT', data[:4])
+        self.assertEqual((2, 2), struct.unpack_from('<II', data, 4))
+        self.assertEqual((0xce, 0xce08ff01, 1, 0, page_size,
+                          payload_size),
+                         struct.unpack_from('<IIIIII', data, 12))
+        self.assertEqual((0xcf, 0xce08ff02, 3, 2,
+                          page_size + payload_size, payload_size),
+                         struct.unpack_from('<IIIIII', data, 36))
+        self.assertEqual(tools.get_bytes(0x11, 1) + payload_pad,
+                         data[page_size:page_size + payload_size])
+        self.assertEqual(tools.get_bytes(0x22, 1) + payload_pad,
+                         data[page_size + payload_size:
+                              page_size + payload_size * 2])
+
     def testFitFdtOper(self):
         """Check handling of a specified FIT operation"""
         entry_args = {
diff --git a/tools/binman/test/qcdt.dts b/tools/binman/test/qcdt.dts
new file mode 100644
index 00000000000..cdbd1a85379
--- /dev/null
+++ b/tools/binman/test/qcdt.dts
@@ -0,0 +1,36 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	binman {
+		/* confirm that qcdt can be referenced before it's built */
+		collection {
+			content = <&qcdt>;
+		};
+
+		qcdt: qcdt {
+			hash {
+			};
+
+			dtb-0 {
+				qcom,msm-id = <0xce 0>;
+				qcom,board-id = <0xce08ff01 1>;
+
+				u-boot-dtb {
+				};
+			};
+
+			dtb-1 {
+				qcom,msm-id = <0xcf 1>;
+				qcom,board-id = <0xce08ff02 2>;
+
+				u-boot-dtb {
+				};
+			};
+		};
+	};
+};
diff --git a/tools/binman/test/qcdt_bad_msm_id.dts b/tools/binman/test/qcdt_bad_msm_id.dts
new file mode 100644
index 00000000000..1c3d4ec1a2e
--- /dev/null
+++ b/tools/binman/test/qcdt_bad_msm_id.dts
@@ -0,0 +1,17 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	binman {
+		qcdt {
+			dtb-0 {
+				qcom,msm-id = <0xce 0 1>;
+				qcom,board-id = <0xce08ff01 1>;
+			};
+		};
+	};
+};
diff --git a/tools/binman/test/qcdt_invalid_pagesize.dts b/tools/binman/test/qcdt_invalid_pagesize.dts
new file mode 100644
index 00000000000..d8eff98c7ac
--- /dev/null
+++ b/tools/binman/test/qcdt_invalid_pagesize.dts
@@ -0,0 +1,12 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		qcdt {
+			page-size = <2049>;
+			dtb-0 {};
+		};
+	};
+};
diff --git a/tools/binman/test/qcdt_missing_msm_id.dts b/tools/binman/test/qcdt_missing_msm_id.dts
new file mode 100644
index 00000000000..3eda1acb6c2
--- /dev/null
+++ b/tools/binman/test/qcdt_missing_msm_id.dts
@@ -0,0 +1,12 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		qcdt {
+			dtb-0 {
+			};
+		};
+	};
+};
diff --git a/tools/binman/test/qcdt_missing_payload.dts b/tools/binman/test/qcdt_missing_payload.dts
new file mode 100644
index 00000000000..ae2c41cbcf8
--- /dev/null
+++ b/tools/binman/test/qcdt_missing_payload.dts
@@ -0,0 +1,14 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		qcdt {
+			dtb-0 {
+				qcom,msm-id = <0xce 0>;
+				qcom,board-id = <0xce08ff01 1>;
+			};
+		};
+	};
+};
diff --git a/tools/binman/test/qcdt_missing_subnodes.dts b/tools/binman/test/qcdt_missing_subnodes.dts
new file mode 100644
index 00000000000..4b1af9570b6
--- /dev/null
+++ b/tools/binman/test/qcdt_missing_subnodes.dts
@@ -0,0 +1,13 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	binman {
+		qcdt {
+		};
+	};
+};
diff --git a/tools/binman/test/qcdt_multiple_dtbs.dts b/tools/binman/test/qcdt_multiple_dtbs.dts
new file mode 100644
index 00000000000..db04c122a6e
--- /dev/null
+++ b/tools/binman/test/qcdt_multiple_dtbs.dts
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
+		qcdt {
+			page-size = <0x100>;
+
+			dtb-0 {
+				qcom,msm-id = <0xce 0>;
+				qcom,board-id = <0xce08ff01 1>;
+
+				fill {
+					size = <1>;
+					fill-byte = [11];
+				};
+			};
+
+			dtb-1 {
+				qcom,msm-id = <0xcf 2>;
+				qcom,board-id = <0xce08ff02 3>;
+
+				fill {
+					size = <1>;
+					fill-byte = [22];
+				};
+			};
+		};
+	};
+};
diff --git a/tools/binman/test/qcdt_page_size_from_abootimg.dts b/tools/binman/test/qcdt_page_size_from_abootimg.dts
new file mode 100644
index 00000000000..557863d8834
--- /dev/null
+++ b/tools/binman/test/qcdt_page_size_from_abootimg.dts
@@ -0,0 +1,33 @@
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
+			page-size = <4096>;
+
+			kernel {
+				fill {
+					size = <1>;
+				};
+			};
+
+			vendor-dt {
+				qcdt {
+					dtb-0 {
+						qcom,msm-id = <0 0>;
+						qcom,board-id = <0 0>;
+
+						fill {
+							size = <1>;
+						};
+					};
+				};
+			};
+		};
+	};
+};
diff --git a/tools/binman/test/qcdt_zero_pagesize.dts b/tools/binman/test/qcdt_zero_pagesize.dts
new file mode 100644
index 00000000000..8ca802719f0
--- /dev/null
+++ b/tools/binman/test/qcdt_zero_pagesize.dts
@@ -0,0 +1,12 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	binman {
+		qcdt {
+			page-size = <0>;
+			dtb-0 {};
+		};
+	};
+};

-- 
2.54.0

