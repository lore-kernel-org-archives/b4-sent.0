From: Miguel Garcia <miguelgarciaroman8@gmail.com>
Date: Fri, 02 Oct 2026 17:00:58 +0200
Subject: [PATCH v3] wifi: mwifiex: replace deprecated strcpy() with
 strscpy()
To: Brian Norris <briannorris@chromium.org>
Cc: Francesco Dolcini <francesco@dolcini.it>, 
 linux-wireless@vger.kernel.org, 
 Miguel Garcia <miguelgarciaroman8@gmail.com>
Message-ID: <179095325825.1998848.2691205243435840007.mwifiex-strscpy-v3@gmail.com>
X-Mailer: b4 0.13.0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790953258; l=3986;
 i=miguelgarciaroman8@gmail.com; s=default; h=from:subject:message-id;
 bh=IVwajOKSRUqDnlhmPDEYuZeAEQwdQ6oxaUangjNedkw=;
 b=wOxWhwS9HYD3T3A7PwS6u0CV8Mf95VIxWy/iX1Dg7i0bq5WwhyY+lxCbcR/Iu/CuubGSHfDc/
 1BhfiLIS35sCVU5HkeQ//qi/A+SLQGjaoOkOTdiZfQSjaXrKu4vF/pz
X-Developer-Key: i=miguelgarciaroman8@gmail.com; a=ed25519;
 pk=EtrxRdQ/icT1qmJwjNNAVoBUhKKWwrhU2m6QT/xu6bM=
X-Endpoint-Received: by B4 Relay for miguelgarciaroman8@gmail.com/default with auth_id=1101
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the six strcpy() calls in mwifiex_pcie_get_fw_name() with
strscpy(), using sizeof(adapter->fw_name) as the destination size.

All six firmware names, including their terminating NUL bytes, fit in
the 32-byte array, so the selected firmware names remain unchanged.
Also simplify the function comment.

Assisted-by: LLM
Signed-off-by: Miguel Garcia <miguelgarciaroman8@gmail.com>
---
v3:
- New standalone thread, with no In-Reply-To. v2 was a reply and
  Patchwork stored it as a comment rather than as a patch.
- Subject prefix is "wifi: mwifiex:". v1 omitted "wifi:" and v2 used
  "wifi: pcie:".
- adapter->fw_name is a 32-byte array. v1 described it as 64 bytes.
- Keep the comment accepted by Brian Norris. Do not add a sentence
  about strscpy(), realign the version/magic masks, or insert the
  blank lines v2 added between cases.
- No Reviewed-by tag is carried forward from v1.

v1: https://lore.kernel.org/linux-wireless/20250705133600.186441-1-miguelgarciaroman8@gmail.com/
v2: https://lore.kernel.org/linux-wireless/20250723151718.367623-1-miguelgarciaroman8@gmail.com/
Brian Norris: https://lore.kernel.org/linux-wireless/aG1lcWYjk9GARp1P@google.com/
Johannes Berg: https://lore.kernel.org/linux-wireless/294d5e91279556b59586f0812eee4ac809d7b011.camel@sipsolutions.net/

AI assistance: Grok (xAI, grok-4.7) prepared this v3 from the reviewed
thread, edited these six call sites, and ran checkpatch.pl --strict,
git diff --check, git apply --check, and the targeted pcie.o build.
Codex reviewed the diff and refined the commit message. No device was tested.


 drivers/net/wireless/marvell/mwifiex/pcie.c | 22 ++++++++++++---------
 1 file changed, 13 insertions(+), 9 deletions(-)

diff --git a/drivers/net/wireless/marvell/mwifiex/pcie.c b/drivers/net/wireless/marvell/mwifiex/pcie.c
index a9425e9a94f4..7ad193841c2e 100644
--- a/drivers/net/wireless/marvell/mwifiex/pcie.c
+++ b/drivers/net/wireless/marvell/mwifiex/pcie.c
@@ -3098,9 +3098,7 @@ static int mwifiex_pcie_request_irq(struct mwifiex_adapter *adapter)
 }
 
 /*
- * This function gets the firmware name for downloading by revision id
- *
- * Read revision id register to get revision id
+ * Get firmware name for download by revision ID
  */
 static void mwifiex_pcie_get_fw_name(struct mwifiex_adapter *adapter)
 {
@@ -3110,7 +3108,8 @@ static void mwifiex_pcie_get_fw_name(struct mwifiex_adapter *adapter)
 
 	switch (card->dev->device) {
 	case PCIE_DEVICE_ID_MARVELL_88W8766P:
-		strcpy(adapter->fw_name, PCIE8766_DEFAULT_FW_NAME);
+		strscpy(adapter->fw_name, PCIE8766_DEFAULT_FW_NAME,
+			sizeof(adapter->fw_name));
 		break;
 	case PCIE_DEVICE_ID_MARVELL_88W8897:
 		mwifiex_write_reg(adapter, 0x0c58, 0x80c00000);
@@ -3118,13 +3117,16 @@ static void mwifiex_pcie_get_fw_name(struct mwifiex_adapter *adapter)
 		revision_id &= 0xff00;
 		switch (revision_id) {
 		case PCIE8897_A0:
-			strcpy(adapter->fw_name, PCIE8897_A0_FW_NAME);
+			strscpy(adapter->fw_name, PCIE8897_A0_FW_NAME,
+				sizeof(adapter->fw_name));
 			break;
 		case PCIE8897_B0:
-			strcpy(adapter->fw_name, PCIE8897_B0_FW_NAME);
+			strscpy(adapter->fw_name, PCIE8897_B0_FW_NAME,
+				sizeof(adapter->fw_name));
 			break;
 		default:
-			strcpy(adapter->fw_name, PCIE8897_DEFAULT_FW_NAME);
+			strscpy(adapter->fw_name, PCIE8897_DEFAULT_FW_NAME,
+				sizeof(adapter->fw_name));
 
 			break;
 		}
@@ -3139,9 +3141,11 @@ static void mwifiex_pcie_get_fw_name(struct mwifiex_adapter *adapter)
 		if (revision_id == PCIE8997_A1 &&
 		    magic == CHIP_MAGIC_VALUE &&
 		    version == CHIP_VER_PCIEUART)
-			strcpy(adapter->fw_name, PCIEUART8997_FW_NAME_V4);
+			strscpy(adapter->fw_name, PCIEUART8997_FW_NAME_V4,
+				sizeof(adapter->fw_name));
 		else
-			strcpy(adapter->fw_name, PCIEUSB8997_FW_NAME_V4);
+			strscpy(adapter->fw_name, PCIEUSB8997_FW_NAME_V4,
+				sizeof(adapter->fw_name));
 		break;
 	default:
 		break;
-- 
2.43.0


