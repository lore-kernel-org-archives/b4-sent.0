From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 09:39:03 +0200
Subject: [PATCH v2 4/6] binman: test: Add tests for fit,compress
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-binman-fit-fdt-compression-v2-4-d7e290847543@protonmail.com>
References: <20261017-b4-binman-fit-fdt-compression-v2-0-d7e290847543@protonmail.com>
In-Reply-To: <20261017-b4-binman-fit-fdt-compression-v2-0-d7e290847543@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, Tom Rini <trini@konsulko.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Marek Vasut <marex@nabladev.com>, 
 Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Petr Pavlata <petr@acrux.cz>, David Heidelberg <david@ixit.cz>, 
 Alexey Charkov <alchark@flipper.net>, 
 James Hilliard <james.hilliard1@gmail.com>, 
 Aristo Chen <aristo.chen@canonical.com>, 
 Philippe Reynes <philippe.reynes@softathome.com>, 
 Daniel Golle <daniel@makrotopia.org>, Johan Jonker <jbx6244@gmail.com>, 
 Quentin Schulz <u-boot@0leil.net>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792222776; l=3140;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=6IPRRVuoewG+dDLGaql2qM+1Y8ADSTKQ9Qq9kD87Z9g=;
 b=me/eiuxWmJjcbflkZ+6Hp89xwM0tVV+7D3thZ4ahly8Tw9JUAfa5OCNdAB3Ssf0h/TlQdzQnp
 mzvCRGFYKkdCVcjwxlcMQW6Zykrf/Suw6u+d+W+DTFJbRBj7Kq5KzAH
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check that generated fdt images are compressed and that 'compression'
is set from 'fit,compress', that an unknown algorithm is rejected and
that a missing compression tool is reported.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 tools/binman/ftest.py | 44 ++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 44 insertions(+)

diff --git a/tools/binman/ftest.py b/tools/binman/ftest.py
index 8caf275d466..fdb22b0965f 100644
--- a/tools/binman/ftest.py
+++ b/tools/binman/ftest.py
@@ -4357,6 +4357,50 @@ class TestFunctional(unittest.TestCase):
         """Test an image with an FIT with multiple FDT images"""
         self.CheckFitFdt()
 
+    def _FitFdtCompress(self, fname):
+        entry_args = {'of-list': 'test-fdt1 test-fdt2'}
+        extra_indirs = [os.path.join(self._indir, TEST_FDT_SUBDIR)]
+        return self._DoReadFileDtb(fname, entry_args=entry_args,
+                                   extra_indirs=extra_indirs)[0]
+
+    def testFitFdtCompress(self):
+        """Test that fit,compress compresses generated fdt images"""
+        bintool = self.comp_bintools['lzma_alone']
+        self._CheckBintool(bintool)
+        data = self._FitFdtCompress('fit/fdt_compress.dts')
+        dtb = fdt.Fdt.FromData(data)
+        dtb.Scan()
+        for seq, expected in ((1, TEST_FDT1_DATA), (2, TEST_FDT2_DATA)):
+            fnode = dtb.GetNode('/images/fdt-%d' % seq)
+            self.assertEqual('lzma', fnode.props['compression'].value)
+            self.assertNotIn('fit,compress', fnode.props)
+            comp = fnode.props['data'].bytes
+            self.assertNotEqual(expected, comp)
+            self.assertEqual(expected, bintool.decompress(comp))
+
+    def testFitFdtCompressBad(self):
+        """Test an unsupported fdt compression algorithm"""
+        with self.assertRaises(ValueError) as e:
+            self._FitFdtCompress('fit/fdt_compress_bad.dts')
+        self.assertIn("Unknown algorithm 'bad'", str(e.exception))
+
+    def testFitFdtCompressXz(self):
+        """Test that xz is rejected as it is not a FIT compression"""
+        with self.assertRaises(ValueError) as e:
+            self._FitFdtCompress('fit/fdt_compress_xz.dts')
+        self.assertIn("fit,compress 'xz' is not a FIT compression",
+                      str(e.exception))
+
+    def testFitFdtCompressMissing(self):
+        """Test that a missing compression tool is an error"""
+        with self.assertRaises(ValueError) as e:
+            self._DoTestFile('fit/fdt_compress.dts', allow_missing=True,
+                             force_missing_bintools='lzma_alone',
+                             entry_args={'of-list': 'test-fdt1 test-fdt2'},
+                             extra_indirs=[os.path.join(self._indir,
+                                                        TEST_FDT_SUBDIR)])
+        self.assertIn("tool 'lzma_alone' is missing", str(e.exception))
+
     def testFitFdtMissingList(self):
         """Test handling of a missing 'of-list' entry arg"""
         with self.assertRaises(ValueError) as e:

-- 
2.55.0

