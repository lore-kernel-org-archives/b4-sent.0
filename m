From: Yang Li <yang.li@amlogic.com>
Date: Mon, 28 Jul 2025 17:08:44 +0800
Subject: [PATCH] Bluetooth: hci_sync: Avoid adding default advertising on
 startup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250728-default_adv-v1-1-a1164ff502a7@amlogic.com>
X-B4-Tracking: v=1; b=H4sIABs+h2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDcyML3ZTUtMTSnJL4xJQy3WRTUxPzxBTjpOQUIyWgjoKi1LTMCrBp0bG
 1tQDCYAdmXQAAAA==
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753693725; l=1557;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=+a7zu6df7P6AdI4x7RiSKdHUqD0wbm828ppOC8TJSaI=;
 b=3UX/dEiKfIm3KVtx2p0CoOiWQL25So1OuJjvoy/lEZDif1Ww60eWJtqHWw9ayCrEuH8iV8jRV
 /X/OX2px1S7ChY3zt/VYeNXg5TY9mrMNLvEJI2rntOkkG8hhZ8qIfBh
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

list_empty(&hdev->adv_instances) is always true during startup,
so an advertising instance is added by default.

Call trace:
  dump_backtrace+0x94/0xec
  show_stack+0x18/0x24
  dump_stack_lvl+0x48/0x60
  dump_stack+0x18/0x24
  hci_setup_ext_adv_instance_sync+0x17c/0x328
  hci_powered_update_adv_sync+0xb4/0x12c
  hci_powered_update_sync+0x54/0x70
  hci_power_on_sync+0xe4/0x278
  hci_set_powered_sync+0x28/0x34
  set_powered_sync+0x40/0x58
  hci_cmd_sync_work+0x94/0x100
  process_one_work+0x168/0x444
  worker_thread+0x378/0x3f4
  kthread+0x108/0x10c
  ret_from_fork+0x10/0x20

Fixes: https://github.com/bluez/bluez/issues/1442

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 net/bluetooth/hci_sync.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/bluetooth/hci_sync.c b/net/bluetooth/hci_sync.c
index 2b4f21fbf9c1..7397b6b50ccb 100644
--- a/net/bluetooth/hci_sync.c
+++ b/net/bluetooth/hci_sync.c
@@ -3344,7 +3344,7 @@ static int hci_powered_update_adv_sync(struct hci_dev *hdev)
 	 * advertising data. This also applies to the case
 	 * where BR/EDR was toggled during the AUTO_OFF phase.
 	 */
-	if (hci_dev_test_flag(hdev, HCI_ADVERTISING) ||
+	if (hci_dev_test_flag(hdev, HCI_ADVERTISING) &&
 	    list_empty(&hdev->adv_instances)) {
 		if (ext_adv_capable(hdev)) {
 			err = hci_setup_ext_adv_instance_sync(hdev, 0x00);

---
base-commit: d1b3de23042b0aac0145fdf071d6ac81ec3727b4
change-id: 20250728-default_adv-c5547ad3bcd2

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

