From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 16:24:47 +0200
Subject: [PATCH 3/4] binman: test: Check compression of generated fit fdt
 images
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-binman-fit-fdt-compression-v1-3-4465558758cc@protonmail.com>
References: <20261010-b4-binman-fit-fdt-compression-v1-0-4465558758cc@protonmail.com>
In-Reply-To: <20261010-b4-binman-fit-fdt-compression-v1-0-4465558758cc@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, Tom Rini <trini@konsulko.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Marek Vasut <marex@nabladev.com>, 
 Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Petr Pavlata <petr@acrux.cz>, David Heidelberg <david@ixit.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791642291; l=2355;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=5uoc82yqjzMue5G0o5xpNb6IgLiTO164mNPRh9g5zeM=;
 b=KyI/u3jzbRSxYnEbc3LMCb1CpnoH3wheqzQ9La/u2aeHO69OahQP3lvhaNvARYGHg6MFAEhU+
 AaIam2IXGpXBXM+laa7Zfi+4O6Jimg18I8V33Sx8wparWp4722Qd4Ff
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add testFitFdtCompressed, which builds a FIT with lzma-compressed fdt
images and checks that each embedded image.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 tools/binman/ftest.py | 29 +++++++++++++++++++++++++++++
 1 file changed, 29 insertions(+)

diff --git a/tools/binman/ftest.py b/tools/binman/ftest.py
index bf98b268ac1..587400ff308 100644
--- a/tools/binman/ftest.py
+++ b/tools/binman/ftest.py
@@ -4349,6 +4349,35 @@ class TestFunctional(unittest.TestCase):
         """Test an image with an FIT with multiple FDT images"""
         self.CheckFitFdt()
 
+    def testFitFdtCompressed(self):
+        """Test that fdt images are really compressed when asked"""
+        bintool = self.comp_bintools['lzma_alone']
+        self._CheckBintool(bintool)
+        entry_args = {'of-list': 'test-fdt1 test-fdt2',
+                      'default-dt': 'test-fdt2'}
+        extra_indirs = [os.path.join(self._indir, TEST_FDT_SUBDIR)]
+        data = self._DoReadFileDtb('fit/fdt_lzma.dts', entry_args=entry_args,
+                                   extra_indirs=extra_indirs)[0]
+        fit_data = data[len(U_BOOT_DATA):-len(U_BOOT_NODTB_DATA)]
+        dtb = fdt.Fdt.FromData(fit_data)
+        dtb.Scan()
+        for seq, expected in ((1, TEST_FDT1_DATA), (2, TEST_FDT2_DATA)):
+            fnode = dtb.GetNode('/images/fdt-%d' % seq)
+            self.assertEqual('lzma', fnode.props['compression'].value)
+            comp = fnode.props['data'].bytes
+            self.assertNotEqual(expected, comp)
+            self.assertEqual(expected, bintool.decompress(comp))
+
+    def testFitFdtBadCompression(self):
+        """Test an unsupported fdt compression algorithm"""
+        entry_args = {'of-list': 'test-fdt1 test-fdt2',
+                      'default-dt': 'test-fdt2'}
+        extra_indirs = [os.path.join(self._indir, TEST_FDT_SUBDIR)]
+        with self.assertRaises(ValueError) as e:
+            self._DoReadFileDtb('fit/fdt_bad_comp.dts', entry_args=entry_args,
+                                extra_indirs=extra_indirs)
+        self.assertIn("Unsupported fdt compression 'bzip2'", str(e.exception))
+
     def testFitFdtMissingList(self):
         """Test handling of a missing 'of-list' entry arg"""
         with self.assertRaises(ValueError) as e:

-- 
2.55.0

