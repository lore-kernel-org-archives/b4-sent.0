From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 04 Apr 2024 17:02:09 -0500
Subject: [PATCH v2] selftests/powerpc/papr-vpd: Fix missing variable
 initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240404-papr-vpd-test-uninit-lc-v2-1-37bff46c65a5@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIAGAjD2YC/3WNwQqDMBAFf0Vy7koSU8We+h/Fg93EuqAxJDFYx
 H9vKvTY4wy8eTsLxpMJ7FbszJtEgRabQV4KhmNvXwZIZ2aSS8UVr8D1zkNyGqIJEVZLliJMCBW
 v0dSor6JuWF47bwbazvKjyzxSiIt/n0dJfO2vqf42kwABXCFKqZuhadv7RHbdSnrOJS4z647j+
 ACbLa0PwgAAAA==
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 "Naveen N. Rao" <naveen.n.rao@linux.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>, 
 Geetika Moolchandani <geetika@linux.ibm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712268137; l=1473;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=bYiOiaClrXV1SOzlLA/y5qVSPUcyHE9ZqM034MU/ORQ=;
 b=PZ2pQwgASuBN6LNMB7MTOSfo6bFZNALzbSHPPZImCqh1/KrQYGyYdq/674lEj60WEJ3bP6Pe4
 6OfduhqsyTwDBGXI4HtY0W2Y03/rHUD94c9xJJW2MOetH+d/wtE5icB
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The "close handle without consuming VPD" testcase has inconsistent
results because it fails to initialize the location code object it
passes to ioctl() to create a VPD handle. Initialize the location code
to the empty string as intended.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
Reported-by: Geetika Moolchandani <geetika@linux.ibm.com>
Fixes: 9118c5d32bdd ("powerpc/selftests: Add test for papr-vpd")
---
Changes in v2:
- Add Fixes: and Reported-by: tags.
- Link to v1: https://lore.kernel.org/r/20240404-papr-vpd-test-uninit-lc-v1-1-04cc22d7f799@linux.ibm.com
---
 tools/testing/selftests/powerpc/papr_vpd/papr_vpd.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/tools/testing/selftests/powerpc/papr_vpd/papr_vpd.c b/tools/testing/selftests/powerpc/papr_vpd/papr_vpd.c
index 505294da1b9f..d6f99eb9be65 100644
--- a/tools/testing/selftests/powerpc/papr_vpd/papr_vpd.c
+++ b/tools/testing/selftests/powerpc/papr_vpd/papr_vpd.c
@@ -154,7 +154,7 @@ static int dev_papr_vpd_null_handle(void)
 static int papr_vpd_close_handle_without_reading(void)
 {
 	const int devfd = open(DEVPATH, O_RDONLY);
-	struct papr_location_code lc;
+	struct papr_location_code lc = { .str = "", };
 	int fd;
 
 	SKIP_IF_MSG(devfd < 0 && errno == ENOENT,

---
base-commit: bfe51886ca544956eb4ff924d1937ac01d0ca9c8
change-id: 20240403-papr-vpd-test-uninit-lc-306ce6cd5167

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

