From: Yang Li <yang.li@amlogic.com>
Date: Thu, 07 Aug 2025 15:56:03 +0800
Subject: [PATCH] Bluetooth: hci_sync: Prevent unintended PA sync when SID
 is 0xFF
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250807-sid_invalid-v1-1-94b3902a49e3@amlogic.com>
X-B4-Tracking: v=1; b=H4sIABJclGgC/x3MQQqAIBBA0avIrBNsIJOuEhGmYw2EhYIE4d2Tl
 m/x/wuZElOGSbyQqHDmKzb0nQB32LiTZN8MqHBQRo0ys185Fnuyl+jMplHbgBSgFXeiwM9/m5d
 aP661q7FdAAAA
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754553364; l=2518;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=CtzsG6OQjFbI3wHcVoNvKNs7wHlNBWzJw+zuy9bA75s=;
 b=ETEyq1rB1JGnX2oJgwsj6kgqPnLa65UEjLLIkyn2hV7modUsnow39Wh8EqiU4f2YaEViwC/HV
 6qM4SraBE3vARqgqVRrjGO9n13Ti6NdV6+nXLRN8wRtvZwpCW/Zm6Wk
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After LE Extended Scan times out, conn->sid remains 0xFF,
so the PA sync creation process should be aborted.

Btmon snippet from PA sync with SID=0xFF:

< HCI Command: LE Set Extended.. (0x08|0x0042) plen 6  #74726 [hci0] 863.107927
        Extended scan: Enabled (0x01)
        Filter duplicates: Enabled (0x01)
        Duration: 0 msec (0x0000)
        Period: 0.00 sec (0x0000)
> HCI Event: Command Complete (0x0e) plen 4            #74727 [hci0] 863.109389
      LE Set Extended Scan Enable (0x08|0x0042) ncmd 1
        Status: Success (0x00)
< HCI Command: LE Periodic Ad.. (0x08|0x0044) plen 14  #74728 [hci0] 865.141168
        Options: 0x0000
        Use advertising SID, Advertiser Address Type and address
        Reporting initially enabled
        SID: 0xff
        Adv address type: Random (0x01)
        Adv address: 0D:D7:2C:E7:42:46 (Non-Resolvable)
        Skip: 0x0000
        Sync timeout: 20000 msec (0x07d0)
        Sync CTE type: 0x0000
> HCI Event: Command Status (0x0f) plen 4              #74729 [hci0] 865.143223
      LE Periodic Advertising Create Sync (0x08|0x0044) ncmd 1
        Status: Success (0x00)

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 net/bluetooth/hci_sync.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/net/bluetooth/hci_sync.c b/net/bluetooth/hci_sync.c
index 387c128f2ba0..540794a4495f 100644
--- a/net/bluetooth/hci_sync.c
+++ b/net/bluetooth/hci_sync.c
@@ -7045,10 +7045,13 @@ static int hci_le_pa_create_sync(struct hci_dev *hdev, void *data)
 	/* SID has not been set listen for HCI_EV_LE_EXT_ADV_REPORT to update
 	 * it.
 	 */
-	if (conn->sid == HCI_SID_INVALID)
-		__hci_cmd_sync_status_sk(hdev, HCI_OP_NOP, 0, NULL,
+	if (conn->sid == HCI_SID_INVALID) {
+		err = __hci_cmd_sync_status_sk(hdev, HCI_OP_NOP, 0, NULL,
 					 HCI_EV_LE_EXT_ADV_REPORT,
 					 conn->conn_timeout, NULL);
+		if (err == -ETIMEDOUT)
+			goto done;
+	}
 
 	memset(&cp, 0, sizeof(cp));
 	cp.options = qos->bcast.options;
@@ -7078,6 +7081,7 @@ static int hci_le_pa_create_sync(struct hci_dev *hdev, void *data)
 		__hci_cmd_sync_status(hdev, HCI_OP_LE_PA_CREATE_SYNC_CANCEL,
 				      0, NULL, HCI_CMD_TIMEOUT);
 
+done:
 	hci_dev_clear_flag(hdev, HCI_PA_SYNC);
 
 	/* Update passive scan since HCI_PA_SYNC flag has been cleared */

---
base-commit: df18778595f9423542f38784749feca5471f9de7
change-id: 20250807-sid_invalid-2c8b626af2ef

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

