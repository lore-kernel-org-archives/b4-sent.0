From: Thomas de Gruijter <thomasdegruijter@pm.me>
Date: Fri, 20 Nov 2026 02:13:35 +0100
Subject: [PATCH 1/2] Bluetooth: MSFT: Record the filter state on Command
 Disallowed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-msft-filter-monitors-v1-1-8192f0c0791a@pm.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795137220; l=2913;
 i=thomasdegruijter@pm.me; s=20261120; h=from:subject:message-id;
 bh=9ByWVPjebUuGU8CBazRss6+Y7uMCgB12uO2GOB5lyKY=;
 b=SaGwUzLcYPLhMnCYJhcGZI5lJrJA+bj3w+9SatYoAnFos3dMPTQBh08wm55rcNE22qoTIRxYk
 bPFEkCggtuNBmTG/W248irq5PjIE2M5+k1SH5vF1b2vG2rPfExldA1i
X-Developer-Key: i=thomasdegruijter@pm.me; a=ed25519;
 pk=YtEZHHXdsASGVJkddpdFLAnfVg0G/gza+FXgPGUJZlg=
X-Endpoint-Received: by B4 Relay for thomasdegruijter@pm.me/20261120 with auth_id=1578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

msft_le_set_advertisement_filter_enable_cb() treats status 0x0C (Command
Disallowed) as success: a controller returns it when the advertisement
filter is already in the requested state, and some controllers start
with the filter enabled.

Since commit 493ea69970e2 ("Bluetooth: Convert MSFT filter HCI cmd to
hci_sync") the callback is passed the return value of
__hci_cmd_sync_status() instead of the HCI status. That function reports
Command Disallowed as -EBUSY, so the 0x0C branch is never taken and
msft->filter_enabled keeps its old value whenever the filter was already
in the requested state. msft_set_filter_enable() also always returns 0,
hiding real errors from its callers.

Pass the error code to the callback, treat -EBUSY as the filter already
being in the requested state, and return real errors from
msft_set_filter_enable(). Nothing reads msft->filter_enabled yet, but
the next patch relies on it to decide when to change the filter state.

The problem was found, with the help of an AI coding assistant
(Claude Code with Claude Opus 5.5).

Fixes: 493ea69970e2 ("Bluetooth: Convert MSFT filter HCI cmd to hci_sync")
Signed-off-by: Thomas de Gruijter <thomasdegruijter@pm.me>
---
 net/bluetooth/msft.c | 11 ++++++-----
 1 file changed, 6 insertions(+), 5 deletions(-)

diff --git a/net/bluetooth/msft.c b/net/bluetooth/msft.c
index 7a06c2b8974b..f372df9a9831 100644
--- a/net/bluetooth/msft.c
+++ b/net/bluetooth/msft.c
@@ -1142,26 +1142,27 @@ __u64 msft_get_features(struct hci_dev *hdev)
 
 static void msft_le_set_advertisement_filter_enable_cb(struct hci_dev *hdev,
 						       void *user_data,
-						       u8 status)
+						       int err)
 {
 	struct msft_cp_le_set_advertisement_filter_enable *cp = user_data;
 	struct msft_data *msft = hdev->msft_data;
 
-	/* Error 0x0C would be returned if the filter enabled status is
+	/* Error 0x0C (Command Disallowed), which __hci_cmd_sync_status()
+	 * reports as -EBUSY, would be returned if the filter enabled status is
 	 * already set to whatever we were trying to set.
 	 * Although the default state should be disabled, some controller set
 	 * the initial value to enabled. Because there is no way to know the
 	 * actual initial value before sending this command, here we also treat
 	 * error 0x0C as success.
 	 */
-	if (status != 0x00 && status != 0x0C)
+	if (err && err != -EBUSY)
 		return;
 
 	hci_dev_lock(hdev);
 
 	msft->filter_enabled = cp->enable;
 
-	if (status == 0x0C)
+	if (err == -EBUSY)
 		bt_dev_warn(hdev, "MSFT filter_enable is already %s",
 			    cp->enable ? "on" : "off");
 
@@ -1212,7 +1213,7 @@ int msft_set_filter_enable(struct hci_dev *hdev, bool enable)
 
 	msft_le_set_advertisement_filter_enable_cb(hdev, &cp, err);
 
-	return 0;
+	return err == -EBUSY ? 0 : err;
 }
 
 bool msft_curve_validity(struct hci_dev *hdev)

-- 
2.56.0

