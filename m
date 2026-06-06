From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 10:52:42 +1000
Subject: [PATCH 08/13] binman: android_boot: SEANDROIDENFORCE support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-android-binman-v1-8-c7a3c14b8a3d@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780707158; l=4423;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=lG4YyGgMeyAkpsez/qDqni7sEvyORfqtBM9mfabuH+k=;
 b=ovdMjerWsMlNABldtRrETkzuPF2pzxg7+a5rA2nMQPduwkZic0jAopHxKVHVkq/+TOZe+kJl0
 i7sQV8kbHrmCJb+fPy5jDuWTaZdVTu5ljWslcDygwziHN53GU85yIwF
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some older MSM8916-era bootloaders want to see this string appended to
the abootimg, or they log an ugly warning to the screen.

Signed-off-by: Sam Day <me@samcday.com>
---
 tools/binman/etype/android_boot.py                 | 11 +++++++++++
 tools/binman/ftest.py                              |  6 ++++++
 .../test/vendor/android_boot_seandroidenforce.dts  | 22 ++++++++++++++++++++++
 3 files changed, 39 insertions(+)

diff --git a/tools/binman/etype/android_boot.py b/tools/binman/etype/android_boot.py
index aa68848f579..7d4543209a1 100644
--- a/tools/binman/etype/android_boot.py
+++ b/tools/binman/etype/android_boot.py
@@ -24,6 +24,8 @@ BOOT_IMAGE_HEADER_V2 = (BOOT_IMAGE_HEADER_V0 +
                         '{}sIQIIQ'.format(BOOT_EXTRA_ARGS_SIZE))
 BOOT_IMAGE_HEADER_V2_SIZE = struct.calcsize(BOOT_IMAGE_HEADER_V2)
 
+SEANDROIDENFORCE = b'SEANDROIDENFORCE'
+
 def _align_up(value, align):
     return (value + align - 1) & ~(align - 1)
 
@@ -56,6 +58,7 @@ class Entry_android_boot(Entry_section):
         - boot-name: Android boot image board name
         - cmdline: Android boot command line
           used by header version 0 only
+        - append-seandroid-enforce: Append Samsung SEANDROIDENFORCE trailer,
 
     This entry uses the following subnodes:
         - kernel: section containing the executable payload
@@ -113,6 +116,7 @@ class Entry_android_boot(Entry_section):
 
         android-boot {
             base = <0x80000000>;
+            append-seandroid-enforce;
 
             kernel {
                 u-boot {
@@ -152,6 +156,8 @@ class Entry_android_boot(Entry_section):
         self.os_version = fdt_util.GetInt(self._node, 'os-version', 0)
         self.boot_name = fdt_util.GetString(self._node, 'boot-name', '')
         self.cmdline = fdt_util.GetString(self._node, 'cmdline', '')
+        self.append_seandroid = fdt_util.GetBool(self._node,
+                                                 'append-seandroid-enforce')
         self.vendor_dt_node = self._node.FindNode('vendor-dt')
 
         if self.header_version not in (0, 2):
@@ -175,6 +181,9 @@ class Entry_android_boot(Entry_section):
                 self.Raise('page-size must fit the Android boot image header')
             if 'dtb' not in self._entries:
                 self.Raise("Missing required subnode 'dtb'")
+            if self.append_seandroid:
+                self.Raise("Property 'append-seandroid-enforce' requires "
+                           "header-version 0")
             if self.vendor_dt_node:
                 self.Raise("Subnode 'vendor-dt' requires header-version 0")
 
@@ -344,6 +353,8 @@ class Entry_android_boot(Entry_section):
         image += _pad(kernel, self.page_size)
         image += _pad(ramdisk, self.page_size)
         image += _pad(vendor_dt, self.page_size)
+        if self.append_seandroid:
+            image += SEANDROIDENFORCE
 
         return bytes(image)
 
diff --git a/tools/binman/ftest.py b/tools/binman/ftest.py
index c96748bd1dd..1f3e94908d9 100644
--- a/tools/binman/ftest.py
+++ b/tools/binman/ftest.py
@@ -5673,6 +5673,12 @@ fdt         fdtmap                Extract the devicetree blob from the fdtmap
                                              vendor_dt), header[13])
         self.assertEqual(vendor_dt, data[0x1800:0x1805])
 
+    def testAndroidBootSeAndroidEnforce(self):
+        """Test that binman appends SEANDROIDENFORCE"""
+        data = self._DoReadFile('vendor/android_boot_seandroidenforce.dts')
+
+        self.assertEqual(b'SEANDROIDENFORCE', data[-16:])
+
     def testAndroidBootQcdt(self):
         """Test that binman can produce a QCDT container"""
         data, dtb_data, _map, _dtb = self._DoReadFileDtb(
diff --git a/tools/binman/test/vendor/android_boot_seandroidenforce.dts b/tools/binman/test/vendor/android_boot_seandroidenforce.dts
new file mode 100644
index 00000000000..dc8374f84c7
--- /dev/null
+++ b/tools/binman/test/vendor/android_boot_seandroidenforce.dts
@@ -0,0 +1,22 @@
+// SPDX-License-Identifier: GPL-2.0+
+/dts-v1/;
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+	binman {
+		android-boot {
+			header-version = <0>;
+			append-seandroid-enforce;
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
+		};
+	};
+};

-- 
2.54.0

