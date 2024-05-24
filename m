From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 24 May 2024 14:29:54 -0500
Subject: [PATCH v2] powerpc/pseries/lparcfg: drop error message from guest
 name lookup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240524-lparcfg-updates-v2-1-62e2e9d28724@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIALLqUGYC/2WNywqDMBBFf0Vm3UgmRi1d9T+KixhHHfAREhWL+
 O+Nbrs8B+65BwTyTAFeyQGeNg48TxHUIwHbm6kjwU1kUFJlqFCJwRlv206srjELBUEt5jorbZG
 XEuLKeWp5v4ufKnLPYZn99z7Y8LJXS0uU+q+1oUBRFEbiUxtNNb4HntY95XpM7TxCdZ7nD2v1R
 f2yAAAA
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 "Naveen N. Rao" <naveen.n.rao@linux.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716578998; l=1381;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=NEUhSoj0WlsPQRe4cTFyD/u1YuoW2Ozw67ZFMVrHt8s=;
 b=8dDzzlfhfwDYt/+lQsriCZU9IsT5xbUPTZR+JEVH3hp8IOKBL4E+ZAzPklOxA5xc9KBLyldxu
 ErXiV9kd143BL3FQsGuzqbkxAOt48q/t9IPGBg68X7uzXJjjwDSO10z
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's not an error or exceptional situation when the hosting
environment does not expose a name for the LP/guest via RTAS or the
device tree. This happens with qemu when run without the '-name'
option. The message also lacks a newline. Remove it.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
Fixes: eddaa9a40275 ("powerpc/pseries: read the lpar name from the firmware")
---
Changes in v2:
- Added Fixes: tag
- Link to v1: https://lore.kernel.org/r/20240104-lparcfg-updates-v1-1-66a0184a4eb1@linux.ibm.com
---
 arch/powerpc/platforms/pseries/lparcfg.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/powerpc/platforms/pseries/lparcfg.c b/arch/powerpc/platforms/pseries/lparcfg.c
index 6e7029640c0c..62da20f9700a 100644
--- a/arch/powerpc/platforms/pseries/lparcfg.c
+++ b/arch/powerpc/platforms/pseries/lparcfg.c
@@ -371,8 +371,8 @@ static int read_dt_lpar_name(struct seq_file *m)
 
 static void read_lpar_name(struct seq_file *m)
 {
-	if (read_rtas_lpar_name(m) && read_dt_lpar_name(m))
-		pr_err_once("Error can't get the LPAR name");
+	if (read_rtas_lpar_name(m))
+		read_dt_lpar_name(m);
 }
 
 #define SPLPAR_MAXLENGTH 1026*(sizeof(char))

---
base-commit: 61700f816e6f58f6b1aaa881a69a784d146e30f0
change-id: 20231212-lparcfg-updates-ef15437c6570

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

