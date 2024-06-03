From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 03 Jun 2024 14:31:32 -0500
Subject: [PATCH] powerpc/mm/drmem: Silence drmem_init() early return
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240603-silence-drmem_init-v1-1-e9d71646bc3d@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIABMaXmYC/x3M3QpAMBiH8VvRe2w1zEduRRLbH28x2iSl3bvl8
 HfwPC95OIanNnnJ4WbPh43I0oT0OtoFgk005TJXspKF8LzBagjjduwDW76EGVVZ12jkpDTF8HS
 Y+fmnXR/CBysngiRkAAAA
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 "Naveen N. Rao" <naveen.n.rao@linux.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717443097; l=939;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=ArKgFOJwaRqH7ZIf89ZHqTfwAzZfHpebTMperM6RitI=;
 b=rq41dBW5bVWytILVb8ARF1MR+WzjqtCGpcm7z8zm3h9fUhcoF8ykkRTGOgOWYA1AIt1MVG2Ss
 tn46YYWpZBuC0dR05kphRGalt5WOA7a1WTD7EIItSs01+Kfyws4Pvc6
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's not an error or noteworthy condition if the
"ibm,dynamic-reconfiguration-memory" node isn't present.

Drop the needless message.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/mm/drmem.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/arch/powerpc/mm/drmem.c b/arch/powerpc/mm/drmem.c
index c110ab8fa8a3..8dd7b340d51f 100644
--- a/arch/powerpc/mm/drmem.c
+++ b/arch/powerpc/mm/drmem.c
@@ -491,10 +491,8 @@ static int __init drmem_init(void)
 	const __be32 *prop;
 
 	dn = of_find_node_by_path("/ibm,dynamic-reconfiguration-memory");
-	if (!dn) {
-		pr_info("No dynamic reconfiguration memory found\n");
+	if (!dn)
 		return 0;
-	}
 
 	if (init_drmem_lmb_size(dn)) {
 		of_node_put(dn);

---
base-commit: be2fc65d66e0406cc9d39d40becaecdf4ee765f3
change-id: 20240603-silence-drmem_init-da4577e80b4c

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

