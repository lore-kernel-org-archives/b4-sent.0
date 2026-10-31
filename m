From: Ernesto Salvetti <ernesto.salvetti@tambosi.tn.it>
Date: Sat, 31 Oct 2026 13:16:16 +0100
Subject: [PATCH 2/3] Bluetooth: hci_event: Don't drop LE link on busy
 remote features read
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-barrot-le-fixes-v1-v1-2-30e2089882bf@tambosi.tn.it>
References: <20261031-barrot-le-fixes-v1-v1-0-30e2089882bf@tambosi.tn.it>
In-Reply-To: <20261031-barrot-le-fixes-v1-v1-0-30e2089882bf@tambosi.tn.it>
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ernesto Salvetti <ernesto.salvetti@tambosi.tn.it>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793448994; l=2905;
 i=ernesto.salvetti@tambosi.tn.it; s=20261031; h=from:subject:message-id;
 bh=6FdY8h7nVU+wFr+FiHP6cSyVDh7scpK0ylbnj6iZsko=;
 b=tUJGdwui4lzAnNP7rki57kfX9oOJP+yIJAevYn7KjYyzMYMJDQdduIdo6Kp6evFa3q13RXsqa
 sHxzsBFuYU7Ds/MvGo1PJukA93IVvNObJJDDMQD6z5x9rsR5nbQQrPV
X-Developer-Key: i=ernesto.salvetti@tambosi.tn.it; a=ed25519;
 pk=OLNiuyRbYD4dcNYoAvM99nt/1KZTKeM316r91BCQDUs=
X-Endpoint-Received: by B4 Relay for ernesto.salvetti@tambosi.tn.it/20261031 with auth_id=1370
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Right after an outgoing LE connection is established, the Barrot
controller in the UGREEN Bluetooth 5.4 dongle (33fa:0010) rejects
LE Read Remote Used Features with Controller Busy. The error is passed
to hci_connect_cfm(), the pairing attempt fails and the link is torn
down right away, so no LE device can be paired or connected:

  > HCI Event: LE Meta Event (0x3e) plen 19
        LE Connection Complete (0x01)
          Status: Success (0x00)
          Handle: 65
          Role: Central (0x00)
  < HCI Command: LE Read Remote Used Features (0x08|0x0016) plen 2
          Handle: 65
  > HCI Event: Command Status (0x0f) plen 4
        LE Read Remote Used Features (0x08|0x0016) ncmd 1
          Status: Controller Busy (0x3a)
  @ MGMT Event: Command Complete (0x0001) plen 10
        Pair Device (0x0019) plen 7
          Status: Busy (0x0a)
  < HCI Command: Disconnect (0x01|0x0006) plen 3
          Reason: Remote User Terminated Connection (0x13)

The controller does not send an LE Read Remote Features Complete event
later on either.

The remote features are not needed to use the connection; the stack
already continues without them when a peripheral gets Unsupported
Remote Feature. Do the same for Controller Busy and move the connection
to the connected state.

With this an Xbox Wireless Controller pairs over LE Secure Connections
and works as HID device.

Assisted-by: LLM
Signed-off-by: Ernesto Salvetti <ernesto.salvetti@tambosi.tn.it>
---
 include/net/bluetooth/hci.h |  1 +
 net/bluetooth/hci_event.c   | 11 +++++++++++
 2 files changed, 12 insertions(+)

diff --git a/include/net/bluetooth/hci.h b/include/net/bluetooth/hci.h
index 74b96941ad11..7da40b84c198 100644
--- a/include/net/bluetooth/hci.h
+++ b/include/net/bluetooth/hci.h
@@ -726,6 +726,7 @@ enum {
 #define HCI_ERROR_UNSUPPORTED_REMOTE_FEATURE	0x1a
 #define HCI_ERROR_INVALID_LL_PARAMS	0x1e
 #define HCI_ERROR_UNSPECIFIED		0x1f
+#define HCI_ERROR_CONTROLLER_BUSY	0x3a
 #define HCI_ERROR_ADVERTISING_TIMEOUT	0x3c
 #define HCI_ERROR_CANCELLED_BY_HOST	0x44
 
diff --git a/net/bluetooth/hci_event.c b/net/bluetooth/hci_event.c
index d05934fef4d9..fcbd1807e2f3 100644
--- a/net/bluetooth/hci_event.c
+++ b/net/bluetooth/hci_event.c
@@ -3026,6 +3026,17 @@ static void hci_cs_le_read_remote_features(struct hci_dev *hdev, u8 status)
 			status = 0x00;
 		}
 
+		/* Some controllers reject the command with Controller Busy
+		 * right after the connection has been established. The
+		 * remote features are not required to use the connection,
+		 * so continue without them instead of dropping it.
+		 */
+		if (status == HCI_ERROR_CONTROLLER_BUSY) {
+			bt_dev_warn(hdev, "Remote features busy, continuing without them");
+			conn->state = BT_CONNECTED;
+			status = 0x00;
+		}
+
 		hci_connect_cfm(conn, status);
 	}
 

-- 
2.53.0.697.g625c4fb2daa

