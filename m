From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 04 Apr 2024 14:43:36 -0500
Subject: [PATCH] selftests/powerpc/papr-vpd: Fix missing variable
 initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240404-papr-vpd-test-uninit-lc-v1-1-04cc22d7f799@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIAOcCD2YC/x3MTQqAIBBA4avErBvwpwy6SrQInWogTNQiCO+et
 PwW772QKDIlGJsXIt2c+PQVsm3A7ovfCNlVgxKqE53QGJYQ8Q4OM6WMl2fPGQ+LWhhLxrpemgF
 qHSKt/PznaS7lA/abMUBpAAAA
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 "Naveen N. Rao" <naveen.n.rao@linux.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712259816; l=1184;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=a/o3lqjGPFohwmOc1NqwCzXppmJphtefEpMvQ+pHiZg=;
 b=CB1egXPxeJFbMCiCCEwDWAUrD1ZHMqzxvct9cHVm4rS7gOYh7P/htxqic1JpeBzzIBv/C0ise
 NX4OZvLPaqnBNBDGivFi5O4HNk5J51DKsL+MoE+xCrkryOoFgvu43FS
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The "close handle without consuming VPD" testcase has inconsistent
results because it fails to initialize the location code object it
passes to ioctl() to create a VPD handle. Initialize the location code
to the empty string as intended.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
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

