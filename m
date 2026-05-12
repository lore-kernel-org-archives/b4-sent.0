From: Carl Lee <carl.lee@amd.com>
Date: Tue, 12 May 2026 17:55:11 +0800
Subject: [PATCH] nfc: nxp-nci: Add ISO15693 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-nfc-nxp-nci-add-iso15693-support-v1-1-3394e5b9dba9@amd.com>
X-B4-Tracking: v=1; b=H4sIAP74AmoC/x3NPQ7CMAxA4atUnrHUBNUFroIY8uOAFyeKAVWqe
 ncixm95bwfjLmxwm3bo/BWTqgPuNEF6BX0ySh4GP3uaF+dRS0LdGmoSDDmjWHULXc9on9ZqfyP
 FEiOtFNZLhpFpnYts/8X9cRw/CqmvuHIAAAA=
X-Change-ID: 20260512-nfc-nxp-nci-add-iso15693-support-6bfbb676a78d
To: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, krzk@kernel.org, 
 carl.lee@amd.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778579715; l=1156;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=kGkeRYAHg70oAWwZuY//sniWB2ZJGuNwncL9XW7pfMA=;
 b=CPTRDl+CdKUptz9w2XaHxxn82KTCf/Rpa8uVCdSG2GyjZdV42HXxjHh9dghUbuSNCFxb35baf
 iax1syxQuw4DN0wGir8gLb+1svpuiEzkEW5o02/DPepj2WAdHDJIZZI
X-Developer-Key: i=carl.lee@amd.com; a=ed25519;
 pk=pyq7QaQvoxMg806KVkRwpCbiah+7ncWr4MBpK1AEyjA=
X-Endpoint-Received: by B4 Relay for carl.lee@amd.com/20260203 with auth_id=623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

NXP NCI controllers such as PN7150 support ISO15693 Type 5
tags, but the driver does not currently advertise this protocol.

Add NFC_PROTO_ISO15693_MASK so that ISO15693 tags can be
detected through the Linux NFC stack.

Signed-off-by: Carl Lee <carl.lee@amd.com>
---
This patch advertises ISO15693 Type 5 protocol support for
the nxp-nci driver so that Type 5 tags can be detected.

Tested with PN7150 controller.
---
 drivers/nfc/nxp-nci/core.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/nfc/nxp-nci/core.c b/drivers/nfc/nxp-nci/core.c
index 66b198663387..448e5a4e7338 100644
--- a/drivers/nfc/nxp-nci/core.c
+++ b/drivers/nfc/nxp-nci/core.c
@@ -25,6 +25,7 @@
 			       NFC_PROTO_FELICA_MASK | \
 			       NFC_PROTO_ISO14443_MASK | \
 			       NFC_PROTO_ISO14443_B_MASK | \
+			       NFC_PROTO_ISO15693_MASK | \
 			       NFC_PROTO_NFC_DEP_MASK)
 
 #define NXP_NCI_RF_PLL_UNLOCKED_NTF nci_opcode_pack(NCI_GID_RF_MGMT, 0x21)

---
base-commit: 7109a2155340cc7b21f27e832ece6df03592f2e8
change-id: 20260512-nfc-nxp-nci-add-iso15693-support-6bfbb676a78d

Best regards,
-- 
Carl Lee <carl.lee@amd.com>

