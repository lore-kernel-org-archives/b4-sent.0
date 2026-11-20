From: Thomas de Gruijter <thomasdegruijter@pm.me>
Date: Fri, 20 Nov 2026 02:13:36 +0100
Subject: [PATCH 2/2] Bluetooth: MSFT: Only enable the advertisement filter
 with monitors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-msft-filter-monitors-v1-2-8192f0c0791a@pm.me>
References: <20261120-msft-filter-monitors-v1-0-8192f0c0791a@pm.me>
In-Reply-To: <20261120-msft-filter-monitors-v1-0-8192f0c0791a@pm.me>
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Brian Gix <brian.gix@intel.com>, Yun-Hao Chung <howardchung@google.com>, 
 Miao-chen Chou <mcchou@chromium.org>, Archie Pusaka <apusaka@chromium.org>
Cc: Luiz Augusto von Dentz <luiz.von.dentz@intel.com>, 
 linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Thomas de Gruijter <thomasdegruijter@pm.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795137220; l=5018;
 i=thomasdegruijter@pm.me; s=20261120; h=from:subject:message-id;
 bh=oT34K5Pir/uDlTpBt575+nbbGyIR7ZHnel9uDdmYiDw=;
 b=fsi+gUP+ht/139YcgqzEyVLogw8p4nnwczBQby4sAl8ujOmP77MtN21lncNbh0//pUWXNb45j
 SHpRBT+6vAgAAFjBIMZzTcKLfzU0zT4T2L58Y6Ul02dvtDNYftR49hm
X-Developer-Key: i=thomasdegruijter@pm.me; a=ed25519;
 pk=YtEZHHXdsASGVJkddpdFLAnfVg0G/gza+FXgPGUJZlg=
X-Endpoint-Received: by B4 Relay for thomasdegruijter@pm.me/20261120 with auth_id=1578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

msft_do_open() unconditionally enables the MSFT LE advertisement filter
on every power on, whether or not any advertisement monitor is
registered.

On MediaTek MT7922 (USB 0e8d:0616, firmware build 20260724) the
controller then drops every LE advertisement: LE Set Extended Scan
Enable succeeds, but no LE Extended Advertising Report is ever
delivered, so LE discovery and passive scanning find nothing. BR/EDR
inquiry is not affected. Sending LE Set Advertisement Filter Enable with
Enable set to 0x00 restores reporting immediately. The Microsoft HCI
extension specification defines the filter as disabled by default and
does not specify what a controller reports while the filter is enabled
without any monitor condition.

Only enable the filter while at least one monitor is offloaded to the
controller, and update it after a monitor is added or removed and after
the monitors are re-registered on power on and resume. Like the
monitors, the filter state does not survive a power off, so reset the
tracked state in msft_do_close() instead of sending a redundant disable
on power on. A command is only sent when the wanted state differs from
msft->filter_enabled, so this depends on the previous patch keeping
that state accurate when the controller reports the filter as already
being in the requested state.

Fixes: 394566bf1e37 ("Bluetooth: advmon offload MSFT handle filter enablement")
Signed-off-by: Thomas de Gruijter <thomasdegruijter@pm.me>
---
 net/bluetooth/msft.c | 46 +++++++++++++++++++++++++++++++++++++++++++---
 1 file changed, 43 insertions(+), 3 deletions(-)

diff --git a/net/bluetooth/msft.c b/net/bluetooth/msft.c
index f372df9a9831..db7b40ab5fc1 100644
--- a/net/bluetooth/msft.c
+++ b/net/bluetooth/msft.c
@@ -468,6 +468,30 @@ static int msft_remove_monitor_sync(struct hci_dev *hdev,
 	return err;
 }
 
+/* Keep the advertisement filter enabled only while at least one monitor is
+ * offloaded to the controller. With the filter enabled and no monitors, some
+ * controllers (e.g. MediaTek MT7922) drop every advertisement, which breaks
+ * LE discovery and passive scanning entirely.
+ *
+ * This function requires the caller holds hci_req_sync_lock
+ */
+static void msft_update_filter_enable(struct hci_dev *hdev)
+{
+	struct msft_data *msft = hdev->msft_data;
+	bool enable, update;
+
+	if (!msft)
+		return;
+
+	hci_dev_lock(hdev);
+	enable = !list_empty(&msft->handle_map);
+	update = enable != msft->filter_enabled;
+	hci_dev_unlock(hdev);
+
+	if (update)
+		msft_set_filter_enable(hdev, enable);
+}
+
 /* This function requires the caller holds hci_req_sync_lock */
 int msft_suspend_sync(struct hci_dev *hdev)
 {
@@ -493,6 +517,8 @@ int msft_suspend_sync(struct hci_dev *hdev)
 	/* All monitors have been removed */
 	msft->suspending = false;
 
+	msft_update_filter_enable(hdev);
+
 	return 0;
 }
 
@@ -633,6 +659,7 @@ int msft_resume_sync(struct hci_dev *hdev)
 	hci_dev_unlock(hdev);
 
 	reregister_monitor(hdev);
+	msft_update_filter_enable(hdev);
 
 	return 0;
 }
@@ -670,11 +697,11 @@ void msft_do_open(struct hci_dev *hdev)
 
 	if (msft_monitor_supported(hdev)) {
 		msft->resuming = true;
-		msft_set_filter_enable(hdev, true);
 		/* Monitors get removed on power off, so we need to explicitly
 		 * tell the controller to re-monitor.
 		 */
 		reregister_monitor(hdev);
+		msft_update_filter_enable(hdev);
 	}
 }
 
@@ -706,6 +733,11 @@ void msft_do_close(struct hci_dev *hdev)
 		kfree(handle_data);
 	}
 
+	/* The advertisement filter is back to its default, disabled state
+	 * after power off as well.
+	 */
+	msft->filter_enabled = false;
+
 	hci_dev_unlock(hdev);
 
 	mutex_lock(&msft->filter_lock);
@@ -1173,6 +1205,7 @@ static void msft_le_set_advertisement_filter_enable_cb(struct hci_dev *hdev,
 int msft_add_monitor_pattern(struct hci_dev *hdev, struct adv_monitor *monitor)
 {
 	struct msft_data *msft = hdev->msft_data;
+	int err;
 
 	if (!msft)
 		return -EOPNOTSUPP;
@@ -1180,13 +1213,17 @@ int msft_add_monitor_pattern(struct hci_dev *hdev, struct adv_monitor *monitor)
 	if (msft->resuming || msft->suspending)
 		return -EBUSY;
 
-	return msft_add_monitor_sync(hdev, monitor);
+	err = msft_add_monitor_sync(hdev, monitor);
+	msft_update_filter_enable(hdev);
+
+	return err;
 }
 
 /* This function requires the caller holds hci_req_sync_lock */
 int msft_remove_monitor(struct hci_dev *hdev, struct adv_monitor *monitor)
 {
 	struct msft_data *msft = hdev->msft_data;
+	int err;
 
 	if (!msft)
 		return -EOPNOTSUPP;
@@ -1194,7 +1231,10 @@ int msft_remove_monitor(struct hci_dev *hdev, struct adv_monitor *monitor)
 	if (msft->resuming || msft->suspending)
 		return -EBUSY;
 
-	return msft_remove_monitor_sync(hdev, monitor);
+	err = msft_remove_monitor_sync(hdev, monitor);
+	msft_update_filter_enable(hdev);
+
+	return err;
 }
 
 int msft_set_filter_enable(struct hci_dev *hdev, bool enable)

-- 
2.56.0

