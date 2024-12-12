From: Ernst Persson <ernst.persson@non.se.com>
Date: Thu, 12 Dec 2024 15:36:59 +0100
Subject: [PATCH OE-core kirkstone] package.bbclass: Use shlex instead of
 deprecated pipes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241212-b4-package-shlex-kirkstone-v1-1-27e5f76049b8@non.se.com>
X-B4-Tracking: v=1; b=H4sIAAr1WmcC/z2MQQrCMBBFr1Jm7YAJwaJ71x5AXEyTqR0iSZkpU
 ii9u9GFy/c/721grMIGl24D5beY1NLAHTqIE5Uno6TG4I8+OO88DgFnipnaY9OLV8yi2ZZaGE9
 9oDTQ2MdzghaYlUdZf/E73K4Yq/J3/xvw2PcPcUpTsIIAAAA=
X-Change-ID: 20241212-b4-package-shlex-kirkstone-674adbaf7c9d
To: openembedded-core@lists.openembedded.org
Cc: Ernst Persson <ernst.persson@non.se.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1492;
 i=ernst.persson@non.se.com; h=from:subject:message-id;
 bh=pOWG8/NAjjVhQAcB8v1I3LsMBWvK7F5TrcY04gl3v9U=;
 b=owEB7QES/pANAwAKAbrk269F2n0DAcsmYgBnWvUdF5QAav9F/DwIqWM1wQNIfZEwONV9/lz4y
 2S4onj1Z0SJAbMEAAEKAB0WIQRqWagaLrShCohIFwi65NuvRdp9AwUCZ1r1HQAKCRC65NuvRdp9
 A7HqDADUBl4dHHuUlRmf3j1P2N+T9zW8Ya+o3V0PrMEnCwxwMF+h0zr5RFp2HG5Qg08x9Yp3eHS
 ayICAOtJ69sxpfMzKfLtgknlbsMU+P+Q5Il7B0dH3xG4U+u+JXQN+EHtI7SE8qH1lZIHKnRy36r
 q4rFzTetBuJsEhR7XyPOPYZoP02i3e/sPeh4C8hLSNxvtCF36Npae3QhnWI0pmHp3zGxAGGbDWV
 5E/fEyZgyiYFo5SWh4K9E8iJkOg3S3NIjDwJ5LAC+Rbo99/IA2adLou/4AXzqYLrfJ6CkiZDztG
 BvpqOPem3/BWs7Vbth3P5ZUJrWvK2PWBYL0E8iXtwGf3SArWDQBjcNC/BAfZFiNbmVt5CkBDjCr
 6UcfaJpGbWS9B+LxhFV4hrHLTqA1j98I23eRish2qAOxBW+uuAVXiOnKAI5mOfiZAiAl9rLqt46
 WeRm4CZTbfcCUEBsyWNddr3HKwHSQup4dZuu6JIepGl4tc0B1f035x4oqc/zVc3Hw2UDc=
X-Developer-Key: i=ernst.persson@non.se.com; a=openpgp;
 fpr=6A59A81A2EB4A10A88481708BAE4DBAF45DA7D03
X-Endpoint-Received: by B4 Relay for ernst.persson@non.se.com/default with auth_id=297
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The pipes library is deprecated in Python 3.11 and will be removed in
Python 3.13. pipes.quote is just an import of shlex.quote anyway.

Signed-off-by: Ernst Persson <ernst.persson@non.se.com>
---
This patch is only for Kirkstone, the code has changed
in later versions.
---
 meta/classes/package.bbclass | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/meta/classes/package.bbclass b/meta/classes/package.bbclass
index 07bf5eb426e2561512e762729144dfcb5d0bda15..e6ba79346c4468ede9da4bf35be2aebbb261b311 100644
--- a/meta/classes/package.bbclass
+++ b/meta/classes/package.bbclass
@@ -1850,7 +1850,7 @@ SHLIBSWORKDIR = "${PKGDESTWORK}/${MLPREFIX}shlibs2"
 
 python package_do_shlibs() {
     import itertools
-    import re, pipes
+    import re, shlex
     import subprocess
 
     exclude_shlibs = d.getVar('EXCLUDE_FROM_SHLIBS', False)
@@ -1894,7 +1894,7 @@ python package_do_shlibs() {
         sonames = set()
         renames = []
         ldir = os.path.dirname(file).replace(pkgdest + "/" + pkg, '')
-        cmd = d.getVar('OBJDUMP') + " -p " + pipes.quote(file) + " 2>/dev/null"
+        cmd = d.getVar('OBJDUMP') + " -p " + shlex.quote(file) + " 2>/dev/null"
         fd = os.popen(cmd)
         lines = fd.readlines()
         fd.close()

---
base-commit: ccf5b0a8896eba43f59151885aeb30b6cfc0573f
change-id: 20241212-b4-package-shlex-kirkstone-674adbaf7c9d

Best regards,
-- 
Ernst Persson <ernst.persson@non.se.com>

