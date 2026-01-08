From: Yang Li <yang.li@amlogic.com>
Date: Thu, 08 Jan 2026 14:03:43 +0800
Subject: [PATCH] Bluetooth: hci_sync: use HCI_CMD_TIMEOUT for PA sync
 commands
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260108-pa_sync_cmd_timeout-v1-1-cd35538a9e12@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAL5IX2kC/x3MQQqAIBBA0avErBNMyqKrRIjpWLPIQi2K6O5Jy
 7f4/4GIgTBCXzwQ8KRIm8+oygLMov2MjGw2CC4kr3jHdq3i7Y0yq1WJVtyOxJyrpZPt1FihIZd
 7QEfXfx3G9/0Ayt2KJ2UAAAA=
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767852223; l=1484;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=1O83adufpo4acrwmwduYN71Xx5kLK1t2Ua61MN8F4NE=;
 b=Cdlv16KMn8w2ybeFmj82eYRvMc/rq6vK4TcvG8hY0i4gE/k261AUGaJUWe+POH9g6agJFzfJh
 3TzIpqOOZ2LA0g9KViPi8yqnM/1iNsoMXR9V3V+rxEYH4G5pehtBZmb
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PA sync HCI commands incorrectly use conn->conn_timeout, which defaults
to 20s and is too long. If the PA Sync Established event is not
received, the command remains pending and causes userspace timeouts.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 net/bluetooth/hci_sync.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/net/bluetooth/hci_sync.c b/net/bluetooth/hci_sync.c
index f04a90bce4a9..58292b01f062 100644
--- a/net/bluetooth/hci_sync.c
+++ b/net/bluetooth/hci_sync.c
@@ -7159,7 +7159,7 @@ static int hci_le_pa_create_sync(struct hci_dev *hdev, void *data)
 	if (conn->sid == HCI_SID_INVALID) {
 		err = __hci_cmd_sync_status_sk(hdev, HCI_OP_NOP, 0, NULL,
 					       HCI_EV_LE_EXT_ADV_REPORT,
-					       conn->conn_timeout, NULL);
+					       HCI_CMD_TIMEOUT, NULL);
 		if (err == -ETIMEDOUT)
 			goto done;
 	}
@@ -7187,7 +7187,7 @@ static int hci_le_pa_create_sync(struct hci_dev *hdev, void *data)
 	err = __hci_cmd_sync_status_sk(hdev, HCI_OP_LE_PA_CREATE_SYNC,
 				       sizeof(cp), &cp,
 				       HCI_EV_LE_PA_SYNC_ESTABLISHED,
-				       conn->conn_timeout, NULL);
+				       HCI_CMD_TIMEOUT, NULL);
 	if (err == -ETIMEDOUT)
 		__hci_cmd_sync_status(hdev, HCI_OP_LE_PA_CREATE_SYNC_CANCEL,
 				      0, NULL, HCI_CMD_TIMEOUT);

---
base-commit: bdb9aba465a85122bcba01a6154e237b9843e25b
change-id: 20260108-pa_sync_cmd_timeout-ff46f67b5d2a

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

