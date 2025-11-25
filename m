From: Cryolitia PukNgae <cryolitia.pukngae@linux.dev>
Date: Tue, 25 Nov 2025 16:14:38 +0800
Subject: [PATCH] ACPICA: Avoid walking the Namespace if StartNode is NULL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251125-acpica-v1-1-99e63b1b25f8@linux.dev>
X-B4-Tracking: v=1; b=H4sIAG1lJWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQyNT3cTkgszkRN3UtFTTRNO0ZAPDFEsloOKCotS0zAqwQdGxtbUAeGp
 fDFgAAAA=
X-Change-ID: 20251125-acpica-efe5a5fc01d9
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Robert Moore <robert.moore@intel.com>, Len Brown <lenb@kernel.org>
Cc: linux-acpi@vger.kernel.org, acpica-devel@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Mingcong Bai <jeffbai@aosc.io>, 
 Kexy Biscuit <kexybiscuit@aosc.io>, Wentao Guan <guanwentao@uniontech.com>, 
 zhanjun@uniontech.com, niecheng1@uniontech.com, 
 Cryolitia PukNgae <cryolitia@deepin.org>, 
 Cryolitia PukNgae <cryolitia.pukngae@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764058497; l=1953;
 i=cryolitia.pukngae@linux.dev; s=20250730; h=from:subject:message-id;
 bh=QnNb3Rg0Cnjh7njPROJmsVbynAuz0L77GmBmAM6S4Ac=;
 b=AGRGG95C86u4Pf5GvMzwCi3bhEDAW7nug8pzVPLRdDT4UBucJbj2650Vod+CnDbW5JUPtZxYM
 HXHJUU9sHujAy0o59jKmCQZiSyaL+lAv5VDnj+wN8ozPEwRr7CMdsJ2
X-Developer-Key: i=cryolitia.pukngae@linux.dev; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia.pukngae@linux.dev/20250730 with auth_id=540
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ACPICA commit 1c1b57b9eba4554cb132ee658dd942c0210ed20d

Since commit 0c9992315e73 ("ACPICA: Avoid walking the ACPI Namespace
if it is not there") fixed the situation that both StartNode and
AcpiGbl_RootNode is NULL. The Linux kernel mainline now still crashed
on Honor Magicbook 14 Pro[1]. Due to the access to the member of
ParentNode in AcpiNsGetNextNode, the NULL pointer dereference will
always happen, no matter whether the StartNode equals to the
ACPI_ROOT_OBJECT or not. So we move the check of StartNode being NULL
out of the if block.

Unfortunately, all the attempt to contact with Honor has failed, they
refused to provide any technical support for Linux. The bad DSDT
table's dump could be found on GitHub[2].

DMI: HONOR FMB-P/FMB-P-PCB, BIOS 1.13 05/08/2025

1. https://gist.github.com/Cryolitia/a860ffc97437dcd2cd988371d5b73ed7
2. https://github.com/denis-bb/honor-fmb-p-dsdt

Signed-off-by: Cryolitia PukNgae <cryolitia@deepin.org>
Link: https://github.com/acpica/acpica/pull/1061
Signed-off-by: Cryolitia PukNgae <cryolitia.pukngae@linux.dev>
---
 drivers/acpi/acpica/nswalk.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/acpi/acpica/nswalk.c b/drivers/acpi/acpica/nswalk.c
index a2ac06a26e92..5670ff5a43cd 100644
--- a/drivers/acpi/acpica/nswalk.c
+++ b/drivers/acpi/acpica/nswalk.c
@@ -169,9 +169,12 @@ acpi_ns_walk_namespace(acpi_object_type type,
 
 	if (start_node == ACPI_ROOT_OBJECT) {
 		start_node = acpi_gbl_root_node;
-		if (!start_node) {
-			return_ACPI_STATUS(AE_NO_NAMESPACE);
-		}
+	}
+
+	/* Avoid walking the namespace if the StartNode is NULL */
+
+	if (!start_node) {
+		return_ACPI_STATUS(AE_NO_NAMESPACE);
 	}
 
 	/* Null child means "get first node" */

---
base-commit: ac3fd01e4c1efce8f2c054cdeb2ddd2fc0fb150d
change-id: 20251125-acpica-efe5a5fc01d9

Best regards,
-- 
Cryolitia PukNgae <cryolitia.pukngae@linux.dev>

