From: Thomas de Gruijter <thomasdegruijter@pm.me>
Subject: [PATCH 0/2] Bluetooth: MSFT: Only enable the advertisement filter
 with monitors
Date: Fri, 20 Nov 2026 02:13:34 +0100
Message-Id: <20261120-msft-filter-monitors-v1-0-8192f0c0791a@pm.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrDuQBPyhVykuGp3oSE1kJpaCe
 HfTdvkt3jtASZgU7tUBQm9WTrHA3ioY5mecCHksBmdcY60zuGrIGPiVSXBNkXMSRVNT67vgG9v
 WUNJNKPDnt330f+vuFxry9wXneQEdqSFXeAAAAA==
X-Change-ID: 20261120-msft-filter-monitors-05e7b8fb6175
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Brian Gix <brian.gix@intel.com>, Yun-Hao Chung <howardchung@google.com>, 
 Miao-chen Chou <mcchou@chromium.org>, Archie Pusaka <apusaka@chromium.org>
Cc: Luiz Augusto von Dentz <luiz.von.dentz@intel.com>, 
 linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Thomas de Gruijter <thomasdegruijter@pm.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795137220; l=2581;
 i=thomasdegruijter@pm.me; s=20261120; h=from:subject:message-id;
 bh=8/AuYm0ked8MCkDMwRkqznLi5F2SKWqBi78N6Aa7kMI=;
 b=AphLmhqzHZxMDtYf0VAg+/x/lgsXYSXgkcQBKjrS4dPXrmKocw1a04GmEI6I/mcRTS/3quUOP
 Jo9s4NXGOKmCxiILM75AwxlizDUzGHcgpgfsZh56HcVxTXsfugmB7bX
X-Developer-Key: i=thomasdegruijter@pm.me; a=ed25519;
 pk=YtEZHHXdsASGVJkddpdFLAnfVg0G/gza+FXgPGUJZlg=
X-Endpoint-Received: by B4 Relay for thomasdegruijter@pm.me/20261120 with auth_id=1578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On MediaTek MT7922 (USB 0e8d:0616, BT firmware build 20260724) LE
discovery and passive scanning find nothing, because msft_do_open()
enables the MSFT advertisement filter on every power on even when no
advertisement monitor is registered, and this controller then drops
every advertisement.

Patch 2 only enables the filter while at least one monitor is offloaded.
It is the first user of msft->filter_enabled, which does not follow the
controller when it reports the filter as already being in the requested
state, so patch 1 fixes that first.

How the problem was found
-------------------------
- btmon showed LE Set Extended Scan Parameters/Enable completing with
  status 0x00, followed by zero LE Extended Advertising Report events
  while three BLE beacons and ~20 other devices were in range.
- With hci0 powered off in BlueZ, the controller was reset and driven
  directly through the HCI user channel. Legacy and extended scanning
  both delivered reports (~870-980 in 10 s from 23 devices). Adding the
  kernel's init steps one at a time showed that only LE Set
  Advertisement Filter Enable(0x01) stops all reports (0, versus
  ~520-540 with LE Set Address Resolution Enable or the CIS host
  feature bit added instead).
- Disabling the filter on the running hci0 through a raw HCI socket made
  BlueZ LE discovery see 22 devices instead of 0.

Testing
-------
- Patch 2 was tested on the MT7922 described
  above: LE discovery works right after boot (22 devices instead of 0)
  and BLE power control of Lighthouse base stations works again.

Not tested
----------
- Patch 1.
- Any setup with advertisement monitors registered (adding or removing
  monitors, suspend/resume with monitors), any controller other than
  the MT7922, and the Command Disallowed path of patch 1, which needs a
  controller that starts with the filter enabled.

Tool assistance
---------------
The investigation and the creation test scripts were done using Claude Code.
I have reviewed the changes and the analysis and can answer questions about them.

---
Thomas de Gruijter (2):
      Bluetooth: MSFT: Record the filter state on Command Disallowed
      Bluetooth: MSFT: Only enable the advertisement filter with monitors

 net/bluetooth/msft.c | 57 ++++++++++++++++++++++++++++++++++++++++++++--------
 1 file changed, 49 insertions(+), 8 deletions(-)
---
base-commit: 1d79f61152c315e30e758116e525871732181a98
change-id: 20261120-msft-filter-monitors-05e7b8fb6175

Best regards,
--  
Thomas de Gruijter <thomasdegruijter@pm.me>

