From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 05 Dec 2024 18:22:00 +0100
Subject: [PATCH] powerpc: Support using upstream devicetrees
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241205-upstream-dts-v1-1-5a6bf6ccdfc4@posteo.net>
X-B4-Tracking: v=1; b=H4sIADfhUWcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDQyNL3dKC4pKi1MRc3ZSSYl3LRMPUJBNTI5MkU2MloJaCotS0zAqwcdG
 xtbUAubBqs14AAAA=
X-Change-ID: 20241129-upstream-dts-9a1eb4524b53
To: Tom Rini <trini@konsulko.com>, Sumit Garg <sumit.garg@linaro.org>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733419327; l=934;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=+qRUMnidrcaVmH3kl29PIN2BKtB/G2mg7uQctbHVEAE=;
 b=ibfCqMCme5GanDlomhTRM2CqVWzEaU2whEVP+gcUAkGChO3h2Om8FLNRc3n0FmLunyopfCQ1X
 3WMc3TAE3ZLBYVgiowEKiaN81V9+P8imX7D+Gsb5cKBK7UFdu52pAP9
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For new PowerPC developments, it will be useful to borrow devicetrees
from Linux. This patch makes it possible.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
This may seem hypothetical, but I'm working on a new U-Boot port for a
PowerPC board.
---
 dts/upstream/src/powerpc/Makefile | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/dts/upstream/src/powerpc/Makefile b/dts/upstream/src/powerpc/Makefile
new file mode 100644
index 0000000000000000000000000000000000000000..721ec5cb229e2a8ae57e90c9407f86054fcb7ad9
--- /dev/null
+++ b/dts/upstream/src/powerpc/Makefile
@@ -0,0 +1,6 @@
+# SPDX-License-Identifier: GPL-2.0+
+
+include $(srctree)/scripts/Makefile.dts
+
+# Add any required device tree compiler flags here
+DTC_FLAGS +=

---
base-commit: 98dd010b311e68b8398428cadf56a6381f7de202
change-id: 20241129-upstream-dts-9a1eb4524b53

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

