From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 03 Mar 2026 16:31:42 +0100
Subject: [PATCH] powerpc: 83xx: km83xx: Fix keymile vendor prefix
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260303-keymile-v1-1-463a11e71702@posteo.net>
X-B4-Tracking: v=1; b=H4sIAN3+pmkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDQwNj3ezUytzMnFRdM6M0CwsjSyPjpDQzJaDqgqLUtMwKsEnRsbW1APO
 hQ5NZAAAA
X-Change-ID: 20260103-keymile-62f882923bf6
To: "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Holger Brunck <holger.brunck@keymile.com>, Heiko Schocher <hs@denx.de>, 
 Kumar Gala <galak@kernel.crashing.org>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772551910; l=1138;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=Rm4lk8+WysP9Sf46IHCnA/JZCuWDkU+j8PEcMpxO19k=;
 b=lXaauy67JDFSz/HeSMxLJ0Dww8xpDizCxKm4SOSBrzxXfhqGne+M5ux2AVVaHL2gQW8ivULGM
 yryxC8kKe8IDUDEcGnu3AjZBCTT3w5wB3z1EH7138eI8viayFAs6uRD
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When kmeter.c was refactored into km83xx.c in 2011, the "keymile" vendor
prefix was changed to upper-case "Keymile". The devicetree at
arch/powerpc/boot/dts/kmeter1.dts never underwent the same change,
suggesting that this was simply a mistake.

Fixes: 93e2b95c81042d ("powerpc/83xx: rename and update kmeter1")
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/platforms/83xx/km83xx.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/powerpc/platforms/83xx/km83xx.c b/arch/powerpc/platforms/83xx/km83xx.c
index 2b5d187d9b62d5..9ef8fb39dd1b18 100644
--- a/arch/powerpc/platforms/83xx/km83xx.c
+++ b/arch/powerpc/platforms/83xx/km83xx.c
@@ -155,8 +155,8 @@ machine_device_initcall(mpc83xx_km, mpc83xx_declare_of_platform_devices);
 
 /* list of the supported boards */
 static char *board[] __initdata = {
-	"Keymile,KMETER1",
-	"Keymile,kmpbec8321",
+	"keymile,KMETER1",
+	"keymile,kmpbec8321",
 	NULL
 };
 

---
base-commit: 9448598b22c50c8a5bb77a9103e2d49f134c9578
change-id: 20260103-keymile-62f882923bf6

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

