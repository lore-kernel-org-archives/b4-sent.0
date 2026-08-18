From: George Maraveyas <george.0xfff@gmail.com>
Date: Tue, 18 Aug 2026 04:55:21 +0200
Subject: [PATCH RFC 2/2] Bluetooth: mt7925: recover subsystem-reset timeout
 through USB re-enumeration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260818-mt7925-rfc-v1-2-284d856ac572@gmail.com>
References: <20260818-mt7925-rfc-v1-0-284d856ac572@gmail.com>
In-Reply-To: <20260818-mt7925-rfc-v1-0-284d856ac572@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-bluetooth@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 George Maraveyas <george.0xfff@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787022047; l=5329;
 i=george.0xfff@gmail.com; s=20260818; h=from:subject:message-id;
 bh=tw21DpwflFbWWZ7xCtmAWfoLs4aafF589lcKdxB+wGk=;
 b=Ix8UDLUTd3fPtF4Fj9V9Qd5tWoAqB0bL7oV7Wy8yEsyle2hgNl34XqyvZ4pF2vAGU+VqagctJ
 6n8FspmR5/4CqOkdPqZG3dZEfv488nXnL9APzijyoGt5lNuJYL0VPI/
X-Developer-Key: i=george.0xfff@gmail.com; a=ed25519;
 pk=Jz8kMnumjUlo1GJvJ5kdfkF3ZP8DjPbYaYQR5J8IHMI=
X-Endpoint-Received: by B4 Relay for george.0xfff@gmail.com/20260818 with auth_id=960
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MT7925 Bluetooth controller on an ASUS ROG Strix B850-I Gaming WiFi
can remain unusable after a warm reboot even though its USB function
initially enumerates normally.

The Bluetooth USB function on the test system is:

  idVendor=13d3, idProduct=3602
  Manufacturer: MediaTek Inc.
  Product: Wireless_Device

The problem was reproduced with ASUS motherboard BIOS versions 1644 and
1681.  Updating from BIOS 1644 to 1681 did not change the failure.

The Bluetooth firmware reported during testing was:

  HW/SW Version: 0x00000000
  Build Time: 20260605184935

A typical Windows 11-to-Linux failure is:

  1. The MT7925 USB function enumerates as 13d3:3602.
  2. Bluetooth setup begins.
  3. The WMT function-control command times out with -ETIMEDOUT (-110).
  4. The existing MediaTek reset work runs.
  5. btmtk_usb_subsys_reset() also times out.
  6. Resetting the existing usb_device does not recover the controller.

The relevant log contains:

  Bluetooth: hci0: Execution of wmt command timed out
  Bluetooth: hci0: Failed to send wmt func ctrl (-110)
  Bluetooth: hci0: MT7925 WMT func ctrl timed out (dev_id=0x7925), scheduling device reset
  Bluetooth: hci0: Failed to read uhw reg(-110)

The WMT timeout handling and scheduling of the MediaTek reset already
exist before this change.  This patch begins later, inside
btusb_mtk_reset(), after btmtk_usb_subsys_reset() has returned.

The existing path calls btmtk_usb_subsys_reset() and then queues
usb_queue_reset_device().  On the affected MT7925 the subsystem reset
returns -ETIMEDOUT, and resetting the existing usb_device does not recover
the controller.

After btmtk_usb_subsys_reset() returns, check for an MT7925 device and an
-ETIMEDOUT result.  When both conditions are present, request
re-enumeration through usb_queue_reenumerate_device(), added by Patch 1.

If the re-enumeration request is queued successfully, clear
BTMTK_HW_RESET_ACTIVE and return the original subsystem-reset error.  If
the request cannot be queued, report the error and continue into the
existing usb_queue_reset_device() path.

Other MediaTek devices and MT7925 reset results other than -ETIMEDOUT
continue to use the existing recovery path unchanged.

The re-enumeration request gives the MT7925 another chance to go through
normal USB enumeration via the helper in Patch 1, which does this.  This
patch calls that helper when the MT7925 subsystem reset has timed out.

Chia-Lin Kao's preceding _PRR patch is required for the port recovery
used on this machine.  Re-enumeration does not itself request a port
power-cycle or an ACPI _PRR reset.  If the re-enumerated device continues
to fail during enumeration, the existing hub retry path can reach its
port power-cycle, where the _PRR prerequisite supplies the ACPI reset.

The _PRR prerequisite does not fix this failure by itself because the
first USB enumeration has already succeeded before the WMT timeout and
subsequent subsystem-reset timeout occur.

A representative successful recovery was:

  Bluetooth: hci0: MT7925 subsystem reset timed out, requesting USB re-enumeration
  usb 1-11: USB disconnect, device number 4
  usb 1-11: device descriptor read/64, error -110
  usb 1-11: device descriptor read/64, error -110
  usb usb1-port11: attempt power cycle
  usb 1-11: New USB device found, idVendor=13d3, idProduct=3602

Three Windows 11-to-Linux warm restart tests recovered successfully with
this series.  The observed average interval from the initial WMT timeout
to successful Bluetooth setup was about 70.9 seconds.

Bluetooth remains unavailable during most of this interval, so recovery
should not be expected immediately after usb_queue_reenumerate_device()
is called.

Signed-off-by: George Maraveyas <george.0xfff@gmail.com>
---
 drivers/bluetooth/btmtk.c |  4 ++++
 drivers/bluetooth/btusb.c | 16 ++++++++++++++++
 2 files changed, 20 insertions(+)

diff --git a/drivers/bluetooth/btmtk.c b/drivers/bluetooth/btmtk.c
index 66b346761..e8f02f1e3 100644
--- a/drivers/bluetooth/btmtk.c
+++ b/drivers/bluetooth/btmtk.c
@@ -1413,6 +1413,10 @@ int btmtk_usb_setup(struct hci_dev *hdev)
 		err = btmtk_usb_hci_wmt_sync(hdev, &wmt_params);
 		if (err < 0) {
 			bt_dev_err(hdev, "Failed to send wmt func ctrl (%d)", err);
+
+			if (dev_id == 0x7925 && err == -ETIMEDOUT)
+				btmtk_reset_sync(hdev);
+
 			return err;
 		}
 
diff --git a/drivers/bluetooth/btusb.c b/drivers/bluetooth/btusb.c
index 2bae85b00..5b56c26de 100644
--- a/drivers/bluetooth/btusb.c
+++ b/drivers/bluetooth/btusb.c
@@ -2943,6 +2943,22 @@ static int btusb_mtk_reset(struct hci_dev *hdev, void *rst_data)
 
 	err = btmtk_usb_subsys_reset(hdev, btmtk_data->dev_id);
 
+	if (btmtk_data->dev_id == 0x7925 && err == -ETIMEDOUT) {
+		int reenum_err;
+
+		bt_dev_warn(hdev,
+			    "MT7925 subsystem reset timed out, requesting USB re-enumeration");
+
+		reenum_err = usb_queue_reenumerate_device(data->intf);
+		if (!reenum_err) {
+			clear_bit(BTMTK_HW_RESET_ACTIVE, &btmtk_data->flags);
+			return err;
+		}
+
+		bt_dev_err(hdev, "Failed to queue USB re-enumeration (%d)",
+			   reenum_err);
+	}
+
 	usb_queue_reset_device(data->intf);
 	clear_bit(BTMTK_HW_RESET_ACTIVE, &btmtk_data->flags);
 

-- 
2.53.0

