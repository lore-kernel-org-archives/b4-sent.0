From: Ernesto Salvetti <ernesto.salvetti@tambosi.tn.it>
Date: Sat, 31 Oct 2026 13:16:15 +0100
Subject: [PATCH 1/3] Bluetooth: hci_core: Don't use extended advertising
 with broken ext scan
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-barrot-le-fixes-v1-v1-1-30e2089882bf@tambosi.tn.it>
References: <20261031-barrot-le-fixes-v1-v1-0-30e2089882bf@tambosi.tn.it>
In-Reply-To: <20261031-barrot-le-fixes-v1-v1-0-30e2089882bf@tambosi.tn.it>
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ernesto Salvetti <ernesto.salvetti@tambosi.tn.it>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793448994; l=3587;
 i=ernesto.salvetti@tambosi.tn.it; s=20261031; h=from:subject:message-id;
 bh=S7EzWsPZZdSgugiaMBXQ3KzQZLGqMEw7XwNS27NrlD4=;
 b=al2oVKRlVrqvqfhDXOnL7HuOnmehyNkRhbKOm5rwBPFElOx9z5fp0hrlwCaXL1gva2cjAvvyR
 AbR64GHNe3VB8JnEV8/lDJzhBn3orJfcrImxRcaFc+r778m5dLpg1TJ
X-Developer-Key: i=ernesto.salvetti@tambosi.tn.it; a=ed25519;
 pk=OLNiuyRbYD4dcNYoAvM99nt/1KZTKeM316r91BCQDUs=
X-Endpoint-Received: by B4 Relay for ernesto.salvetti@tambosi.tn.it/20261031 with auth_id=1370
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When HCI_QUIRK_BROKEN_EXT_SCAN is set the stack falls back to the legacy
LE Set Scan Parameters/Enable commands, but it keeps using extended
advertising if the controller reports the LE Extended Advertising
feature. Already during init it then sends LE Read Number of Supported
Advertising Sets, which is an extended advertising command.

Core Spec 5.3, Vol 4, Part E, 3.1.1 does not allow mixing the two
command sets: once the Host has issued an extended advertising command,
the Controller shall reject the legacy advertising, scanning and
initiating commands with Command Disallowed until the next reset.

A controller that enforces this, such as the Barrot one in the UGREEN
Bluetooth 5.4 dongle (33fa:0010), then can't scan at all once the quirk
is set:

  < HCI Command: LE Read Number of Su.. (0x08|0x003b) plen 0
  > HCI Event: Command Complete (0x0e) plen 5
        LE Read Number of Supported Advertising Sets (0x08|0x003b) ncmd 1
          Status: Success (0x00)
          Num supported adv sets: 4
  ...
  < HCI Command: LE Set Scan Parameters (0x08|0x000b) plen 7
  > HCI Event: Command Complete (0x0e) plen 4
        LE Set Scan Parameters (0x08|0x000b) ncmd 1
          Status: Command Disallowed (0x0c)

  Bluetooth: hci0: Opcode 0x200b failed: -16

Treat the controller as not capable of extended advertising whenever
extended scanning is marked broken, so that only legacy commands are
used.

Fixes: 392fca352c7a ("Bluetooth: Add quirk to disable extended scanning")
Assisted-by: LLM
Signed-off-by: Ernesto Salvetti <ernesto.salvetti@tambosi.tn.it>
---
 include/net/bluetooth/hci.h      |  4 +++-
 include/net/bluetooth/hci_core.h | 11 +++++++++--
 2 files changed, 12 insertions(+), 3 deletions(-)

diff --git a/include/net/bluetooth/hci.h b/include/net/bluetooth/hci.h
index 1c992e87534d..74b96941ad11 100644
--- a/include/net/bluetooth/hci.h
+++ b/include/net/bluetooth/hci.h
@@ -274,7 +274,9 @@ enum {
 	/*
 	 * When this quirk is set, the HCI_OP_LE_SET_EXT_SCAN_ENABLE command is
 	 * disabled. This is required for some Broadcom controllers which
-	 * erroneously claim to support extended scanning.
+	 * erroneously claim to support extended scanning. Extended
+	 * advertising is disabled as well, since legacy and extended
+	 * commands can't be mixed.
 	 *
 	 * This quirk can be set before hci_register_dev is called or
 	 * during the hdev->setup vendor callback.
diff --git a/include/net/bluetooth/hci_core.h b/include/net/bluetooth/hci_core.h
index 9d5d3ab4a075..d622cab32ca9 100644
--- a/include/net/bluetooth/hci_core.h
+++ b/include/net/bluetooth/hci_core.h
@@ -2095,8 +2095,15 @@ void hci_conn_del_sysfs(struct hci_conn *conn);
 /* Use ext create connection if command is supported */
 #define use_ext_conn(dev) (((dev)->commands[37] & 0x80) && \
 	!hci_test_quirk((dev), HCI_QUIRK_BROKEN_EXT_CREATE_CONN))
-/* Extended advertising support */
-#define ext_adv_capable(dev) (((dev)->le_features[1] & HCI_LE_EXT_ADV))
+/* Extended advertising support
+ *
+ * Controllers shall reject legacy advertising, scanning and initiating
+ * commands with Command Disallowed once an extended advertising command
+ * has been issued (Core Spec 5.3, Vol 4, Part E, 3.1.1), so extended
+ * advertising can't be used when extended scanning is broken.
+ */
+#define ext_adv_capable(dev) (((dev)->le_features[1] & HCI_LE_EXT_ADV) && \
+			      !hci_test_quirk((dev), HCI_QUIRK_BROKEN_EXT_SCAN))
 
 /* Maximum advertising length */
 #define max_adv_len(dev) \

-- 
2.53.0.697.g625c4fb2daa

