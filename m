From: George Maraveyas <george.0xfff@gmail.com>
Date: Sat, 22 Aug 2026 01:37:33 +0200
Subject: [PATCH RFC v2] Bluetooth: mt7925: trigger reset on WMT timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260822-mt7925-rfc-v2-1-c88e3bcf7eb8@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22QTW7DIBCFr2KxLhZgCBBVVaRKPUC3VRZjGCe0w
 U7AsVpFvnsJzbLLNz/vezM3kjEFzGTb3EjCJeQwjUWIp4a4I4wHpMEXTQQTG2a4oXHWViiaBkf
 R+07iwDruLSkL54RD+K5mH+T97ZXs/4r52n+im+82j7GEl2tBzY/ZiDlDRW2b50rSrNAY57rtt
 JJKMcopODzB2H7BtHMwTmNwcGrdFF/upj1kpEXEMJf0xjMucOhlJ/RgnVZeIZMCtLMcLShZmmB
 NDXgMeZ7ST/3Awmue/45dOGVUGOmN2oBTWuwOEUINQPbruv4Cg3ggnkoBAAA=
X-Change-ID: 20260818-mt7925-rfc-edd34ef031d9
In-Reply-To: <20260818-mt7925-rfc-v1-0-284d856ac572@gmail.com>
References: <20260818-mt7925-rfc-v1-0-284d856ac572@gmail.com>
To: Alan Stern <stern@rowland.harvard.edu>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Chia-Lin Kao <acelan.kao@canonical.com>, 
 George Maraveyas <george.0xfff@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787355496; l=6566;
 i=george.0xfff@gmail.com; s=20260818; h=from:subject:message-id;
 bh=eD0xVzdZ+MLHOp0LYT7FNSr4T7TwQldMA7EKYnGOfwE=;
 b=KzR8Sr3nxgfX34AVXTYV5vC9vEHxjKPdJwG4SnjP+eVVVNb4Lr3dDHZ9AHC9kLB0seaa6bQhE
 xikvwO/kzEFCglAqfeeihvlm/BkmqyUPUoFtKYgTO0XaWAzFqK7PRDp
X-Developer-Key: i=george.0xfff@gmail.com; a=ed25519;
 pk=Jz8kMnumjUlo1GJvJ5kdfkF3ZP8DjPbYaYQR5J8IHMI=
X-Endpoint-Received: by B4 Relay for george.0xfff@gmail.com/20260818 with auth_id=960
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MT7925 Bluetooth USB function can enumerate successfully after a warm
reboot while the WMT function-control command remains unresponsive.

When that command times out, btmtk_usb_setup() currently returns
-ETIMEDOUT without entering the existing MediaTek reset path. The existing
USB reset and recovery machinery is therefore never reached.

For MT7925, call btmtk_reset_sync() when the WMT function-control command
times out. This enters the existing reset path in btusb_mtk_reset(), which
performs the MediaTek subsystem reset and queues a USB device reset.

Runtime tracing on the affected hardware showed the resulting path through
usb_queue_reset_device(), usb_reset_device() and
usb_reset_and_verify_device(). When reset and verification could not
restore the device, the USB core escalated to a logical disconnect and
re-enumeration.

Recovery succeeded in three controlled Windows-to-Linux tests. Runtime
tracing showed the existing USB reset path escalating to logical disconnect
and re-enumeration. In two of those tests, tracing continued through the
subsequent enumeration failures and directly captured
usb_acpi_port_prr_reset(), after which the MT7925 re-enumerated and
Bluetooth recovered.

These tests were performed on top of Chia-Lin Kao's ACPI _PRR hub patch,
which remains a prerequisite for this patch.

A fourth Windows-to-Linux test was then performed with the diagnostic btusb
blacklist removed and btusb binding normally during boot. The WMT timeout
reproduced and Bluetooth recovered automatically without manual
intervention.

Signed-off-by: George Maraveyas <george.0xfff@gmail.com>
---
Dear Alan,

Thank you for taking the time to look into my patch and for pointing me
towards the existing reset path. I have now traced the failure on the
affected MT7925 hardware and tested the individual parts separately.

You were correct that a new USB re-enumeration helper is unnecessary.
Once the MT7925 failure is made to enter the existing reset path, I can
see:

  btmtk_reset_sync()
    -> btmtk_usb_subsys_reset()
    -> usb_queue_reset_device()
    -> usb_reset_device()
    -> usb_reset_and_verify_device()

When reset and verification cannot restore the device,
usb_reset_and_verify_device() eventually reaches:

  hub_port_logical_disconnect()

and normal hub re-enumeration follows. I have therefore dropped the
proposed USB helper from v1.

The problem I found is earlier in the Bluetooth path. When MT7925 WMT
FUNC_CTRL times out, btmtk_usb_setup() currently returns -ETIMEDOUT
without entering the existing MediaTek reset machinery. The revised patch
now consists only of the part of my original submission that makes this
timeout enter the existing reset path:

  if (dev_id == 0x7925 && err == -ETIMEDOUT)
          btmtk_reset_sync(hdev);

I tested this both with and without Chia-Lin Kao's _PRR hub patch. I want
to stress that this v2 is based on and dependent on Kao's patch; that
remains the configuration in which I have validated recovery.

Kao's patch alone does not recover this failure because the WMT timeout
never enters the reset path. With the WMT trigger but without Kao's patch,
the reset/disconnect/re-enumeration sequence started, but the device did
not recover in that test.

With Kao's patch plus the WMT trigger, I reproduced and recovered the
Windows-to-Linux failure in three controlled tests. Runtime tracing showed
the existing reset path escalating through usb_queue_reset_device(),
usb_reset_and_verify_device() and hub_port_logical_disconnect(). In two
of those runs, tracing continued through the subsequent enumeration
failures and directly captured:

  usb_acpi_port_prr_reset() <- hub_event.cold

The MT7925 subsequently re-enumerated and Bluetooth recovered.

I then removed the diagnostic btusb blacklist and repeated the test as a
normal Windows-to-Linux restart, allowing btusb to bind automatically.
The WMT command again timed out with -110 and the adapter recovered
without any manual module loading or other intervention.

One behavioural difference is recovery time. The original RFC, which
requested logical disconnect/re-enumeration directly after the MT7925
subsystem reset timed out, recovered Bluetooth in about 71 seconds on
average. Using the existing usb_queue_reset_device() path takes about
133 seconds to complete Bluetooth setup in the current tests, with
successful USB re-enumeration at about 114-115 seconds.

The traces account for most of that difference:
usb_reset_and_verify_device() spends roughly 65 seconds attempting reset
and verification before escalating to hub_port_logical_disconnect(). In
practice this was long enough that, during the first test of the reduced
patch, I almost concluded that recovery had failed and rebooted to start
the test again before the device eventually returned.

I do not think that recovery-time difference justifies retaining the new
USB API, but it seemed worth mentioning because it is a noticeable
behavioural difference between v1 and the reduced approach.

Changes in v2:
- Drop the proposed USB re-enumeration helper.
- Drop the direct MT7925 re-enumeration handling which depended on it.
- Reduce the series from two patches to one Bluetooth patch.
- Retain only the part of the original Bluetooth patch that enters the
  existing reset path on an MT7925 WMT -ETIMEDOUT.
- Keep Chia-Lin Kao's ACPI _PRR hub patch as a prerequisite.
- Add the new runtime trace and recovery results.
- Link to v1: https://patch.msgid.link/20260818-mt7925-rfc-v1-0-284d856ac572@gmail.com

Thanks again for the review.

Kind regards,
George
---
 drivers/bluetooth/btmtk.c | 4 ++++
 1 file changed, 4 insertions(+)

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
 

---
base-commit: 28d012efb4327f9c75d5e042a7c91e9a542efa98
change-id: 20260818-mt7925-rfc-edd34ef031d9
prerequisite-message-id: <20260706080117.3754550-1-acelan.kao@canonical.com>
prerequisite-patch-id: 47a2729fbc473534f8ba52052b00723c54a26c17

Best regards,
--  
George Maraveyas <george.0xfff@gmail.com>

