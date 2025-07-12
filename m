From: Ye He <ye.he@amlogic.com>
Date: Sat, 12 Jul 2025 17:23:42 +0800
Subject: [PATCH bluez] src/adapter: Fix RemoveDevice timeout when device
 already disconnected
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250712-adapter-rm-device-v1-1-808603331f92@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAJ0pcmgC/x2MwQrCQAwFf6XkbKAJrIK/UjzE7qsGbC1ZLWLpv
 3fpcWBmVioIR6Frs1Jg8eLvqYKcGuqfNj3AniuTtpraiyhbtvmD4Bg5V78Hi5ohnZNoEqrdHBj
 8dzw7ur+++NNt23bErRXXagAAAA==
X-Change-ID: 20250712-adapter-rm-device-12aae5651251
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752312224; l=1576;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=DARVIHJtGfNwayJXs1VwNVtAfrL1/3+G/NK64yrR1eo=;
 b=8cOsQ+c0aVHpyDp/4ySaNDXnI3/7X/KIIz5KvpSSAK2v2HywmteDz2wZTy9WDEux9qNs9Kin6
 +MFwjRIITV7BPpZqZGQ43ciEhg5X1wPVgLbZ42xQOvLb6zDJliO5o8A
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When attempting to use RemoveDevice to delete a BIS source device that
was synchronized by the BIS sink scan delegator, the kernel marks the
device as disconnected due to PA sync termination. However, BlueZ is not
notified of this disconnection and still proceeds to send MGMT Disconnect
command. The kernel responds with MGMT_STATUS_DISCONNECTED, which BlueZ
does not currently handle as a successful case. As a result, the RemoveDevice
call never completes and no D-Bus reply is returned.

Fixes: https://github.com/bluez/bluez/issues/1421

Signed-off-by: Ye He <ye.he@amlogic.com>
---
This patch fix org.bluez.Adapter1.RemoveDevice method call timeout
when device already disconnected.
---
 src/adapter.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/src/adapter.c b/src/adapter.c
index 79802300bedf4b25cb7c6bc3ea659c122a01efcb..5d68fa4c7dea251af4ff3b05a1ad66204c847c37 100644
--- a/src/adapter.c
+++ b/src/adapter.c
@@ -8619,7 +8619,8 @@ static void disconnect_complete(uint8_t status, uint16_t length,
 	const struct mgmt_rp_disconnect *rp = param;
 	struct btd_adapter *adapter = user_data;
 
-	if (status == MGMT_STATUS_NOT_CONNECTED) {
+	if (status == MGMT_STATUS_NOT_CONNECTED ||
+		status == MGMT_STATUS_DISCONNECTED) {
 		btd_warn(adapter->dev_id,
 				"Disconnecting failed: already disconnected");
 	} else if (status != MGMT_STATUS_SUCCESS) {

---
base-commit: 806dd732fcda584fa6c44322a74373d2b739c781
change-id: 20250712-adapter-rm-device-12aae5651251

Best regards,
-- 
Ye He <ye.he@amlogic.com>

