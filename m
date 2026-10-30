From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Subject: [PATCH v7 00/13] can: peak_usb: fixes, cleanup and input
 validation hardening
Date: Fri, 30 Oct 2026 11:44:49 +0100
Message-Id: <20261030-canfd_check_channel_idx-v7-0-fc4a3faf3acf@peak-system.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43QTWrDMBAF4KsErasijSWP1VXvUYrRz6hRkzrBc
 k1C8N0rpxQMtSHLB2++B3NjmfpEmb3sbqynMeV06krApx3ze9t9EE+hZAYCaikEcm+7GFq/J39
 o50ZHxzaFC7cqoJVWEmFg5frcU0yXu/z2/pvzt/skP8zc3NinPJz66316lHPvb6XZXBklF1zYy
 rkGoiJhXs9kDzxf80Bfz7Fn89QIS8xsY1CwiA4RDBg0chWrFhiIbawqGKog0WurjaFVTD2IqYK
 56AI1MjbOulVMP4jpgtkaXKVdU2MUq1i9xGAbqwsmDaJQUEmt//9smqYfMywgYFYCAAA=
X-Change-ID: 20261007-canfd_check_channel_idx-a4d7a1a1ee7d
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>, 
 Dan Carpenter <error27@gmail.com>, Lukas Magel <lukas.magel@posteo.net>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tristan Madani <tristmd@gmail.com>, 
 =?utf-8?q?Stefan_G=C3=BCnther?= <stefangun@pm.me>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793357103; l=11157;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=IMnrkDKu2YvgV5lF0p49NojlezEAim1AdoGcjjsJPbs=;
 b=ftdyW4Z5rb4yEgNHPJHvTHR1UpF2N0GOBAjB4qFMBpwJwKM7XjzNzDrKZ+HFIhLV0GTaZbxg7
 UYgtl0aAryfBKczPFaI2GYqRzQcoyYeEovFawFtw1Tqm9dxu4iXdyeU
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series contains bug fixes, cleanups and input validation
improvements for the PEAK-System USB CAN drivers.

Patch 1 fixes CAN error frame generation, where CAN_ERR_CNT overwrote
previously set CAN error flags.

Patches 2, 3 and 5 are cleanups: make a public header self-contained,
sort the CAN_CTRLMODE_* flags in ctrlmode_supported, and replace
open-coded bitmask operations with bitops. Patch 5 also makes the
state flag updates atomic, which patch 6 relies on.

Patch 4 adds bounds checks to the PCAN-USB RX parser, so that
truncated or malformed records are rejected instead of being read
beyond the received data.

Patch 6 validates the channel numbers received from PCAN-USB FD
devices, rejects records for channels that are not set up, and stops
RX on all channels before they are released, on disconnect as well as
on probe failure.

Patch 7 fixes the RX parsing of self-received RTR frames with SRR set,
which left the RX cursor one byte behind.

Patches 8 and 9 fix related issues found while reviewing the above:
the same channel slot check in the PCAN-USB Pro driver, and the netdevs
being registered before their channels are initialized.

Patches 10 and 11 add the missing validation of the data received from
PCAN-USB Pro devices: the data length of the CAN frames, and the record
count of the messages, which could make the decoders read past the
received data.

Patch 12 stops dumping stale RX buffer bytes on decode errors, dumps an
undecodable URB only once, and rate limits the decode error messages.

Patch 13 fixes an uninitialized stack byte that could be returned to
userspace as the PCAN-USB CAN channel ID.

---
Changes in v7:
- Patch 3: also sort the flags added to ctrlmode_supported at runtime
  in pcan_usb_init().
  Found by Sashiko AI review on v6:
  https://lore.kernel.org/r/179281433115.3130.15136732593858786026@kernel.org
- Patch 6: on probe failure, also stop RX on the channel being probed,
  which may already be open at this point of the series, and not only on
  its previous siblings, as the comment of peak_usb_stop_rx() says. The
  remaining use-after-free on this path is pre-existing and fixed by
  patch 9.
  Found by Sashiko AI review on v6:
  https://lore.kernel.org/r/179281433224.3130.6010222623227756144@kernel.org
- Patch 9: don't log "can%d removed" for channels that were created but
  never registered, when probing fails. Commit message: the RX of the
  channels already registered is still stopped if registering a later
  one fails.
  Found by Sashiko AI review on v6:
  https://lore.kernel.org/r/179281433446.3130.6290059781976829176@kernel.org
- Patch 11: commit message only: describe what the old
  pcan_usb_pro_wait_rsp() code could actually do (accept a truncated
  response and return stale request bytes as the channel id), instead of
  walking past the command buffer, which the current callers prevent.
  Found by Sashiko AI review on v6:
  https://lore.kernel.org/r/179281433565.3130.14307625292135673040@kernel.org
- Patch 3: add the Assisted-by: tag.
- Not changed, after review of v6:
  - PCAN-USB restart timer not stopped before free_candev() (reported
    on patch 9): this is fixed by Tristan Madani's patch, which is
    independent of this series and applies on top of it:
    https://lore.kernel.org/r/20261025210256.629830-1-tristan@talencesecurity.com
  - patch 8: the pre-existing NULL usb_if dereference and use-after-free
    on the probe error path are fixed by patch 9; a record for an unset
    channel still stops the decoding of the URB, and can no longer
    happen once patch 9 is applied, while patch 12 rate limits the dump;
  - patches 6 and 9: bus-off not sent to a still attached device when
    CONNECTED is cleared before unregister_candev() (probe failure with
    an opened channel, unbind): pre-existing, left for the separate
    series announced in v6, together with the netdev_err() messages of
    the command helpers during probe.
- Tested on PCAN-USB Pro FD, PCAN-USB Pro and PCAN-USB plugged on the
  same hub, with the driver of this series built against v7.0: probe,
  hot unplug and re-plug of the PCAN-USB Pro FD and of the PCAN-USB
  with their interfaces up (one "removed" message per registered
  channel), module removal with all the interfaces up. The probe error
  path that skips the message for unregistered netdevs was not
  exercised.
- Link to v6: https://lore.kernel.org/r/20261022-canfd_check_channel_idx-v6-0-197704231551@peak-system.fr

Changes in v6:
- Patch 6: clear CONNECTED under RTNL in peak_usb_stop_rx(), so that it
  is serialized with peak_usb_ndo_open(): no RX URB can be anchored but
  not yet submitted when the RX anchors are poisoned, which made
  usb_poison_anchored_urbs() busy-wait.
  Found by Sashiko AI review on v5:
  https://sashiko.dev/#/patchset/20261020-canfd_check_channel_idx-v5-0-a62b35b867f0@peak-system.fr?part=6
- Patch 7: update rx_bytes together with rx_packets, once the SRR byte
  has been checked, so that a frame dropped because this byte is
  missing is not counted.
  Found by Sashiko AI review on v5:
  https://sashiko.dev/#/patchset/20261020-canfd_check_channel_idx-v5-0-a62b35b867f0@peak-system.fr?part=7
- Patch 4: add Cc: stable, since patch 7, which is tagged for stable,
  relies on the bounds check it adds.
  Found by Sashiko AI review on v3:
  https://lore.kernel.org/r/179262353124.3131.13235647451945152794@kernel.org
- New patches 10 and 11: validate the data length of PCAN-USB Pro CAN
  records, and don't read past the received message in the PCAN-USB Pro
  decoders. Pre-existing issues found by Sashiko AI review on v3 to v5:
  https://lore.kernel.org/r/179264019905.3131.17443314322038603114@kernel.org
- Patch 12 (was 10): also remove the dumps done by the PCAN-USB Pro and
  FD decoders, which dumped the same URB a second time without any rate
  limit, and rate limit the decode error messages. New subject.
  Found by Sashiko AI review on v3 to v5:
  https://lore.kernel.org/r/179264020123.3131.12155600294986434879@kernel.org
- New patch 13: don't return an uninitialized PCAN-USB CAN channel ID.
  Pre-existing issue found by Sashiko AI review on v5:
  https://lore.kernel.org/r/179264020017.3131.2617691177294766125@kernel.org
- Patches 6 to 13: add the Assisted-by: tag, as required by
  Documentation/process/coding-assistants.rst.
- Not changed, after review:
  - patch 8: a record for an unset channel still stops the decoding of
    the URB, as the other malformed records do, and as in patch 6. This
    can no longer happen once patch 9 is applied;
  - PCAN-USB with CC_LEN8_DLC (reported on v3): checked on hardware
    (firmware 8.6.1), the device puts DLC data bytes in the records with
    a DLC of 9 to 15, so advancing the RX cursor by the DLC is correct;
  - the other pre-existing issues reported on v5 (asynchronous restart
    URBs and PCAN-USB restart timer not drained on disconnect, bus-off
    not sent on unbind, driver-loaded state not cleared on probe
    failure) will be addressed in a separate series;
  - patch 9: the "can%d removed" message logged on probe failure, and
    the netdev_err() messages of the command helpers during probe, are
    left as they are: they are cosmetic, and will be dealt with in that
    separate series.
- Tested on PCAN-USB, PCAN-USB Pro and PCAN-USB Pro FD on the same bus:
  probe, ethtool -e, reception of Classical CAN data and RTR frames of
  all lengths, of len8_dlc frames, and of back-to-back bursts, module
  removal with all the interfaces up, hot unplug of the PCAN-USB Pro and
  of the PCAN-USB Pro FD during RX and TX traffic. The new error paths
  of patches 10 to 13 were not exercised, since they need a malformed
  device.
- Link to v5: https://lore.kernel.org/r/20261020-canfd_check_channel_idx-v5-0-a62b35b867f0@peak-system.fr

Changes in v5:
- Register the netdevs only once all the channels of the interface are
  initialized, since they share resources during the init of a sibling
  (patch 9).
- Link to v4: https://lore.kernel.org/r/20261020-canfd_check_channel_idx-v4-0-bfbde81f8bab@peak-system.fr

Changes in v4:
- Register the netdev only once the channel is initialized, instead of
  only reordering unregister_candev() and dev_free() on probe failure
  (patch 9).
- Link to v3: https://lore.kernel.org/r/20261020-canfd_check_channel_idx-v3-0-74d17c5a599e@peak-system.fr

Changes in v3:
- Fix out-of-bounds read of the error counters in PCAN-USB bus events.
- Harden channel handling in PCAN-USB FD: publish/read channel slots
  with smp_store_release()/READ_ONCE(), clear them on teardown, stop RX
  on all channels on disconnect and on the siblings on probe failure,
  and reject ndo_open() once disconnected.
- Fix RX cursor desync for self-received RTR frames with SRR.
- Replace open-coded bitmask operations with bitops.
- Add channel slot checks to PCAN-USB Pro.
- Unregister the netdev before dev_free() on probe failure.
- Only dump received bytes, rate limited, on decode error.
- Link to v2: https://patch.msgid.link/20261009-canfd_check_channel_idx-v2-0-f7b772929791@peak-system.fr

Changes in v2:
- Kill all pending RX URBs before unregistering sibling netdevs.
- Reject records targeting unavailable channels during device
  initialization in rare corner cases involving malformed device
  input.
- Link to v1: https://patch.msgid.link/20261008-canfd_check_channel_idx-v1-0-0a3bb82f4e09@peak-system.fr

---
Marc Kleine-Budde (1):
      can: peak_usb: add missing includes

Stefan Günther (1):
      can: peak_usb: fix missing CAN_ERR_FLAG when reporting error counters

Stéphane Grosjean (11):
      can: peak_usb: sort ctrlmode_supported flags
      can: peak_usb: harden PCAN-USB message validation
      can: peak_usb: replace open-coded bitmask operations with bitops
      can: peak_usb: harden channel handling in PCAN-USB FD
      can: peak_usb: fix RX cursor desync for self-received RTR frames with SRR
      can: peak_usb: reject records for unset channels in PCAN-USB Pro
      can: peak_usb: register the netdevs only once all channels are set up
      can: peak_usb: validate the data length of PCAN-USB Pro CAN records
      can: peak_usb: don't read past the message in PCAN-USB Pro decoders
      can: peak_usb: dump undecodable URBs once and rate limit decode errors
      can: peak_usb: don't return an uninitialized PCAN-USB CAN channel ID

 drivers/net/can/usb/peak_usb/pcan_usb.c      |  70 +++++++++------
 drivers/net/can/usb/peak_usb/pcan_usb_core.c | 105 +++++++++++++++++------
 drivers/net/can/usb/peak_usb/pcan_usb_core.h |  16 +++-
 drivers/net/can/usb/peak_usb/pcan_usb_fd.c   | 123 ++++++++++++++++++---------
 drivers/net/can/usb/peak_usb/pcan_usb_pro.c  |  86 +++++++++++++------
 5 files changed, 276 insertions(+), 124 deletions(-)
---
base-commit: a7bfaba4823e3c165bb2004c74eff7c096672bc7
change-id: 20261007-canfd_check_channel_idx-a4d7a1a1ee7d

Best regards,
-- 
Stéphane Grosjean <s.grosjean@peak-system.fr>

