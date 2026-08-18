From: George Maraveyas <george.0xfff@gmail.com>
Subject: [PATCH RFC 0/2] USB/Bluetooth: recover MT7925 after warm reboot
Date: Tue, 18 Aug 2026 04:55:19 +0200
Message-Id: <20260818-mt7925-rfc-v1-0-284d856ac572@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/y2NQW7DIBBFr2LNuliAoRgriipF6gG6rbIYw9DQx
 rgBJ4oU5e4lbpZ/5v/3blAoRyowNDfIdIklzqkG8dKAO2D6IhZ9zSC5fOW96Nm0GCs1y8Ex8r5
 TFHgnvIU6+M0U4nWFfcLH+w72/8dyHr/JLQ/Ms5bpdK6q5dmdqBRcVUOzWU2GVxsXwrSd0Uprz
 gRDR0dM7Q/Obw7TnKLDY+vmafuAjliI1TDFZWhk77mQFEbVSROsM9pr4kqicVaQRa3qE20P+/v
 9DzEpGtUCAQAA
X-Change-ID: 20260818-mt7925-rfc-edd34ef031d9
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787022047; l=5036;
 i=george.0xfff@gmail.com; s=20260818; h=from:subject:message-id;
 bh=9x4AZrWZcZ63FIkowGQwQQitbL74pCyLw6EgRIg7ru0=;
 b=UNa7XJ9EUgbQOFONkmEpkedo0rlgGQGvYZlI0IxpxOiMEYaus9gkcIqjLusIDEg7wgUkYj8ol
 X1mNgNEEzAyAFcb04Noe+JMvpWkWdxMDAsaQBjy7rSwbL6vTQwTIfXF
X-Developer-Key: i=george.0xfff@gmail.com; a=ed25519;
 pk=Jz8kMnumjUlo1GJvJ5kdfkF3ZP8DjPbYaYQR5J8IHMI=
X-Endpoint-Received: by B4 Relay for george.0xfff@gmail.com/20260818 with auth_id=960
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While dual booting Windows 11 and Linux on an ASUS ROG Strix B850-I
Gaming WiFi, I found that the MediaTek MT7925 Bluetooth controller could
remain unusable after a warm reboot even though its USB function had
enumerated successfully.

This investigation originally began on Ubuntu 26.04 LTS, where the
failure was already present on the stock kernel, and remained
reproducible after the work was moved to linux-next for upstream testing.

The Bluetooth USB function on this system is 13d3:3602.  The problem was
reproduced with ASUS motherboard BIOS versions 1644 and 1681.  Updating
the BIOS did not change the failure.

A typical failure occurs after restarting directly from Windows 11 into
Linux without removing power.  The MT7925 USB function enumerates, btusb
begins setting up the controller, and the WMT function-control command
eventually times out with -ETIMEDOUT (-110).  The existing MediaTek reset
path then runs, but the subsequent MT7925 subsystem reset also times out
and resetting the existing usb_device does not recover the controller.

Powering the machine off and starting again was not a reliable workaround
in later testing, especially after booting Windows and then Linux.
Linux-to-Linux warm reboots after a failure were also inconsistent: on
some boots Bluetooth recovered, while on others the failed controller
state persisted.

When that state persisted across a reboot, the MT7925 could fail earlier
while USB core was reading its descriptors.  USB core then handled the
failure through its normal enumeration retry path and could eventually
reach the existing port power-cycle.

The series was tested on top of Chia-Lin Kao's:

  [PATCH v2] USB: hub: call ACPI _PRR reset during port power-cycle on
  enumeration failure

Kao's patch adds the ACPI _PRR reset to that existing mid-retry
power-cycle.  It is required for the port recovery used on this machine,
but it does not fix the original warm-reboot failure by itself.  On the
first Linux boot after Windows, USB enumeration has already succeeded
before the WMT command times out, so USB core does not enter the
enumeration retry path where the power-cycle and _PRR reset occur.

Patch 1 adds usb_queue_reenumerate_device().  It allows a driver to ask
USB core to remove the current usb_device and enumerate the
still-connected physical device again through the normal hub path.  It
does not itself request a port power-cycle or an ACPI _PRR reset.

Patch 2 changes one part of the existing MT7925 reset path.  After
btmtk_usb_subsys_reset() returns, an MT7925 -ETIMEDOUT result causes the
driver to request re-enumeration through the helper from Patch 1.  If
that request cannot be queued, the existing usb_queue_reset_device()
path remains as the fallback.  Other MediaTek devices and other reset
results retain their existing behaviour.

On the test system the re-enumerated MT7925 continued to fail descriptor
reads.  The normal hub retry logic therefore eventually reached its
existing port power-cycle, where Kao's prerequisite supplied the ACPI
_PRR reset.  Enumeration then succeeded and Bluetooth setup completed.

Three controlled Windows 11-to-Linux warm restart tests recovered
successfully with the series.  The observed average interval from the
initial WMT timeout to successful Bluetooth setup was about 70.9 seconds.

Bluetooth remained unavailable during most of that interval, so someone
testing the series should not expect the controller to return
immediately after re-enumeration is requested.

Since completing those controlled tests, I have continued to use the
patched kernel as my daily Linux system.  On this machine it has been the
only reliable way I have found to switch between Windows and Linux
without repeated reboot or power-cycle attempts to recover Bluetooth.

The test kernel was based on next-20260812 and reported:

  7.2.0-rc7-next-20260812-mt7925-rfc-v1

I am sending this as an RFC because Patch 1 adds a USB-core interface.  I
would particularly appreciate feedback on whether returning an
already-enumerated device to the normal hub enumeration path through
hub_port_logical_disconnect() is the appropriate interface for this
recovery.

Signed-off-by: George Maraveyas <george.0xfff@gmail.com>
---
George Maraveyas (2):
      USB: core: add helper to queue device re-enumeration
      Bluetooth: mt7925: recover subsystem-reset timeout through USB re-enumeration

 drivers/bluetooth/btmtk.c |  4 ++++
 drivers/bluetooth/btusb.c | 16 ++++++++++++++
 drivers/usb/core/hub.c    | 54 +++++++++++++++++++++++++++++++++++++++++++++++
 include/linux/usb.h       |  1 +
 4 files changed, 75 insertions(+)
---
base-commit: 28d012efb4327f9c75d5e042a7c91e9a542efa98
change-id: 20260818-mt7925-rfc-edd34ef031d9
prerequisite-message-id: <20260706080117.3754550-1-acelan.kao@canonical.com>
prerequisite-patch-id: 47a2729fbc473534f8ba52052b00723c54a26c17

Best regards,
--  
George Maraveyas <george.0xfff@gmail.com>

