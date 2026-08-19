From: Mark Amirkan <markdamirkan@gmail.com>
Date: Wed, 19 Aug 2026 03:23:26 +0000
Subject: [PATCH] scsi: target: bound VPD identifier formatting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260819-pscsi-vpd-ident-bounds-v1-1-ba28dcb0af08@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywqDMBCF4VeRWXfABG/tqxQXTTLR6SKGjEoh+
 O6muvw4nD+DUGISeFUZEu0svIQC9ajAzp8wEbIrBl3rrh7UgFGsMO7RlYHCimbZghM0rfdG6Wf
 fNg7KOSby/LvC7/G2bOZLdv3X4DhO3Eq2gnoAAAA=
X-Change-ID: 20260818-pscsi-vpd-ident-bounds-b5ffb129754d
To: martin.petersen@oracle.com
Cc: linux-kernel@vger.kernel.org, linux-scsi@vger.kernel.org, 
 target-devel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787109813; l=2920;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=L8mPB4bIaFikTHrgHz6nuvvi6qLxDbVD6mrN0KpPLA4=;
 b=bObFYuDHrVvOgAblWgKkkU/381Mm3pmZ7jVJDJ9bBFZmkiuiofrvAeRmvxQqDdZq1Bikcjixd
 DXKSY7SDwPWA3WfsCqAmBHbhhr9k0dO0Vs3A9tPrHGJxHxo1QInwXgh
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

transport_set_vpd_ident() formats device-provided VPD page 0x83
identifiers into the 254-byte t10_vpd::device_identifier array without
checking whether the result fits.

A binary identifier emits one type character followed by two hexadecimal
characters per input byte.  A 148-byte identifier therefore emits 297
characters, eventually writing beyond the 296-byte t10_vpd allocation.

Reject binary identifiers longer than 126 bytes and apply the equivalent
destination bound to ASCII and UTF-8 identifiers.  Explicitly terminate
accepted identifiers.  Rejecting instead of truncating avoids creating a
false device identity.

The write was reproduced with generic KASAN on arm64 Linux 7.2-rc7 using
a complete 168-byte VPD response.  With the same input, the fixed kernel
retains the valid NAA descriptor, skips the 148-byte vendor-specific
descriptor, enables the pSCSI backstore, and produces no KASAN report.
Seven boundary tests pass.

The demonstrated path requires a device-provided response and privileged
pSCSI configuration.  No claim is made about exploitability or
unprivileged reachability.

The tested source reproducer is available privately on request.

Fixes: c66ac9db8d4a ("[SCSI] target: Add LIO target core v4.0.0-rc6")
Cc: stable@vger.kernel.org
Assisted-by: Codex:gpt-5.6
Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
---
 drivers/target/target_core_transport.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/target/target_core_transport.c b/drivers/target/target_core_transport.c
index dcfe9459..26a0bb66 100644
--- a/drivers/target/target_core_transport.c
+++ b/drivers/target/target_core_transport.c
@@ -1335,6 +1335,14 @@ transport_set_vpd_ident(struct t10_vpd *vpd, unsigned char *page_83)
 	vpd->device_identifier_code_set = (page_83[0] & 0x0f);
 	switch (vpd->device_identifier_code_set) {
 	case 0x01: /* Binary */
+		/*
+		 * Reserve one character for the type and one for the NUL;
+		 * each binary byte expands to two hex characters.
+		 */
+		if (page_83[3] >
+		    (sizeof(vpd->device_identifier) - 2) / 2)
+			return -EINVAL;
+
 		vpd->device_identifier[j++] =
 				hex_str[vpd->device_identifier_type];
 		while (i < (4 + page_83[3])) {
@@ -1344,11 +1352,16 @@ transport_set_vpd_ident(struct t10_vpd *vpd, unsigned char *page_83)
 				hex_str[page_83[i] & 0x0f];
 			i++;
 		}
+		vpd->device_identifier[j] = '\0';
 		break;
 	case 0x02: /* ASCII */
 	case 0x03: /* UTF-8 */
+		if (page_83[3] >= sizeof(vpd->device_identifier))
+			return -EINVAL;
+
 		while (i < (4 + page_83[3]))
 			vpd->device_identifier[j++] = page_83[i++];
+		vpd->device_identifier[j] = '\0';
 		break;
 	default:
 		break;

---
base-commit: 3a0dd7ba4f44cdc116d83712f61e7c1a95be3588
change-id: 20260818-pscsi-vpd-ident-bounds-b5ffb129754d

Best regards,
--  
Mark Amirkan <markdamirkan@gmail.com>

