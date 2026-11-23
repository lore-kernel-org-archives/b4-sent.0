From: Radu Sabau <radu.sabau@analog.com>
Subject: [PATCH 0/7] iio: imu: adis: Use a kfifo buffer for the devices
 with a FIFO
Date: Mon, 23 Nov 2026 15:25:24 +0200
Message-Id: <20261123-adis-fifo-v1-0-f6ad9e493e19@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMQ+BGsC/yXMQQ5AMBBA0avIrDXRFkldRSxapowF0kEkjbsrl
 i/5+REYAyFDk0UIeBLTuiTIPIN+ssuIgoZkUIWqpVRa2IFYePKrUMYaVxrttasg9VtAT9f3arv
 ffLgZ+/0dwH0/ZDATHm0AAAA=
X-Change-ID: 20261123-adis-fifo-29a9b493f3b5
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Ramona Gradinariu <ramona.bolboaca13@gmail.com>, 
 Radu Sabau <radu.sabau@analog.com>
Cc: linux-iio@vger.kernel.org, linux@analog.com, 
 linux-kernel@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795440327; l=4260;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=oKCpDg1HZTgPCiyY2NCccMqSlWCKSdLi45bhzaZepAo=;
 b=YKFQ8nUlf2/y9HWQd8KehMXf94OXNUgdoFmVFs48ax/9kIG9ENA2XBp/TzwULNIZhDKXi+GvR
 Rm8/BzjVpYtDtBcpasUlQBupOSdRqj9/alZ4d1rDwV8M07RHQrRZp5W
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series follows the ADIS16607 driver, which was applied without its
buffered capture so that the adislib part could be done first, as
suggested in the review of that series.

The devices with a hardware FIFO (has_fifo, the ADIS1657x variants of the
adis16475 driver so far) capture through the triggered buffer. Their FIFO
interrupt is requested with iio_trigger_generic_data_rdy_poll() as the
threaded handler, which calls iio_trigger_poll() from the IRQ thread, even
though that helper is meant for hard interrupt context, and the capture then
depends on whatever trigger is selected.

Patch 1 is a fix on its own and does not depend on the rest. The ADIS1657x
variants of the adis16475 driver wait less after a reset than their
datasheets give, so the product ID mismatch warning is printed and the
registers written at probe are lost, including the FIFO configuration. It
was found while testing this series, and comes first so that it can be
applied separately.

Patch 2 adds a helper to adislib that sets up a kfifo buffer and requests
the FIFO interrupt as a oneshot threaded IRQ running a handler supplied by
the driver. The interrupt is requested disabled and the driver enables and
disables it from its buffer setup functions. A second helper registers the
trigger of the same name as before, for the devices that already had one.

Patches 3 and 4 convert the adis16475 FIFO variants. Patch 3 passes the
device and the timestamp to the sample helpers instead of the poll
function, so they do not depend on being called from a trigger handler,
and patch 4 does the conversion. The trigger/current_trigger attribute of
these devices is kept as it was, so there is no change in the interface,
but the buffer does not use the trigger any more: writing it is accepted
and has no effect, and a buffer can now also be enabled without selecting
one. This is the same approach hid-sensor-trigger takes for the same
reason.

Patch 5 removes the FIFO handling from the data ready trigger, which no
device uses any more.

Patches 6 and 7 add the buffered capture to the adis16607 on top of the
helper, and the reporting of loss of external sync, which was left out of
the base series as it is reported from the FIFO interrupt handler.

Notable points for reviewers:

 - The FIFO interrupt is level triggered and oneshot, so the line stays
   masked until the handler has drained the FIFO, and it is enabled only
   while the buffer is, from the buffer setup functions. disable_irq() is
   called without the adis lock, as the handler takes it and
   disable_irq() waits for it.

 - The adis16607 does not register a trigger: it never had that
   interface, so there is nothing to keep compatible. The helper that
   registers one is only called by the adis16475.

 - On the adis16607 the device cannot mask DEV_NOK by itself: unrouting it
   leaves the pin on its weak pull-up, which reads as asserted. The
   interrupt is therefore masked on the host.

 - The series was tested on a Raspberry Pi 4 with an ADIS16607 and an
   ADIS16577-2 wired over SPI.

Link to the ADIS16607 series: https://lore.kernel.org/r/20261118-adis16607-v7-0-707609737691@analog.com

---
Radu Sabau (7):
      iio: imu: adis16475: Use the reset timeouts of the ADIS1657x
      iio: imu: adis: Add a kfifo buffer setup helper for FIFO devices
      iio: imu: adis16475: Pass the device and timestamp to the sample helpers
      iio: imu: adis16475: Use a kfifo buffer for the devices with a FIFO
      iio: imu: adis: Drop the FIFO handling from the data ready trigger
      iio: imu: adis16607: Add FIFO-based buffered capture
      iio: imu: adis16607: Report loss of external sync

 drivers/iio/imu/Kconfig        |   3 +
 drivers/iio/imu/adis16475.c    |  87 +++++----
 drivers/iio/imu/adis16607.c    | 399 +++++++++++++++++++++++++++++++++++++++--
 drivers/iio/imu/adis_buffer.c  |  45 +++++
 drivers/iio/imu/adis_trigger.c |  73 ++++++--
 include/linux/iio/imu/adis.h   |  32 ++++
 6 files changed, 584 insertions(+), 55 deletions(-)
---
base-commit: f2cbef9101b9fc979a324bb1242b8b802a2484b6
change-id: 20261123-adis-fifo-29a9b493f3b5

Best regards,
--  
Radu Sabau <radu.sabau@analog.com>

