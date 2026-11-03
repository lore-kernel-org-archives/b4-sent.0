From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Subject: [PATCH v8 00/14] can: peak_usb: fixes and input validation
 hardening
Date: Tue, 03 Nov 2026 13:30:16 +0100
Message-Id: <20261103-canfd_check_channel_idx-v8-0-4e8b2c0a8806@peak-system.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43R30rDMBQG8FcZubaSvz2NV76HSDlJTlycdqOpZ
 WP03U0nQsFWdvnBl98XkivL1CfK7Gl3ZT2NKadjV0LzsGN+j90bVSmUzCSXteAcKo9dDK3fkz+
 0c6OjjzaFc4U6AAoURBBYOX3qKabzTX55/cn5y72TH2ZubuxTHo795TY9irn3u9Jsroyi4hVH5
 VwjoyZun0+Ehypf8kCfj7Fn89Qol5jdxmTBIjgAaaUFK1YxtcAk38ZUwUAHAd6gsZZWMX0npgv
 mogvUiNg4dKuYuRMzBcNaOmVcU0Pkq1i9xOQ2VhdMWACupRLGrL8ZLDD1z81g/gCvUUWMCn38g
 03T9A09DaTFowIAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793709023; l=14727;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=k+NR5ImJTVRqXMGym3u6ahofP6YI014Hth+JnpAgcdM=;
 b=YTJQNiZBxwR3ac+lFRKVewfK2hACVcC29DEkJ1ulhpbzoHLP2s+rjSq2zSsu82zgGK6Kqd10D
 jcKvlm6Pn+PDXoaITLeumJbH8uxZ33/emUoXDHsXF1ykkmYv4iHTmgO
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series contains bug fixes and input validation improvements for
the PEAK-System USB CAN drivers.

Patch 1 fixes CAN error frame generation, where CAN_ERR_CNT overwrote
previously set CAN error flags.

Patch 2 adds bounds checks to the PCAN-USB RX parser, so that
truncated or malformed records are rejected instead of being read
beyond the received data.

Patch 3 replaces the open-coded bitmask operations on the device state
flags with bitops, which makes their updates atomic. Patches 4 and 7
rely on it.

Patch 4 validates the channel numbers received from PCAN-USB FD
devices, rejects records for channels that are not set up, and stops
RX on all channels before they are released, on disconnect as well as
on probe failure.

Patch 5 fixes the RX parsing of self-received RTR frames with SRR set,
which left the RX cursor one byte behind.

Patches 6 and 7 fix related issues found while reviewing the above:
the same channel slot check in the PCAN-USB Pro driver, and the netdevs
being registered before their channels are initialized.

Patches 8 and 9 add the missing validation of the data received from
PCAN-USB Pro devices: the data length of the CAN frames, and the record
count of the messages, which could make the decoders read past the
received data.

Patch 10 stops dumping stale RX buffer bytes on decode errors, dumps an
undecodable URB only once, and rate limits the decode error messages.

Patches 11 and 12 fix uninitialized data that could be returned to
userspace as the CAN channel ID of the PCAN-USB and of the PCAN-USB
Pro. Patches 13 and 14 stop sending uninitialized stack and heap bytes
to the devices, in the PCAN-USB commands and in the restart commands of
all the adapters.

---
Changes in v8:
- Drop v7 patches 2 ("can: peak_usb: add missing includes", by Marc)
  and 3 ("can: peak_usb: sort ctrlmode_supported flags"), which are
  cleanups, so that this series only carries fixes. None of the fixes
  depends on them. I'll send them to linux-can-next once net-next
  reopens, unless Marc prefers to apply his patch directly. The
  remaining patches are renumbered: v7 patches 4 to 13 are now 2 to 11.
- Patch 3 (was 5): kept in this series, since patches 4 and 7 rely on
  the atomic state flag updates.
- Patch 7 (was 9): commit message only: name the multi-channel
  adapters that share the interface resources (PCAN-USB Pro FD and
  PCAN-USB X6) instead of the single-channel PCAN-USB FD, and say that
  the command buffer released on failure belongs to all the CAN FD
  adapters.
- Patch 10 (was 12): drop the trailing colon of the PCAN-USB Pro "got
  unsupported rec in usb msg" message, since this message and the dump
  of the URB are rate limited separately, and say so in the commit
  message.
  Found by Sashiko AI review on v7:
  https://lore.kernel.org/r/179349933002.3127.4498885660427450789@kernel.org
- New patch 12: pass the dev_num argument of the PCAN-USB Pro GETDEVID
  record, which pcan_msg_add_rec() read with va_arg() without the
  caller passing it, and which could be returned as the CAN channel ID.
  Found by Sashiko AI review on v7:
  https://lore.kernel.org/r/179349933109.3127.16204326690893554658@kernel.org
- New patch 13: don't send uninitialized stack bytes to PCAN-USB
  devices when setting the bitrate or the CAN channel ID. Pre-existing
  issue found by Sashiko AI review on v7, same report as above.
- New patch 14: allocate the buffer of the asynchronous restart
  commands with kzalloc(), since none of the adapters fills the whole
  part of it that is sent to the device. Pre-existing issue, found
  while checking the other adapters for the issue fixed by patch 13.
- Not changed, after review of v7:
  - patch 4 (was 6): on probe failure, peak_usb_stop_rx() clears
    CONNECTED before the failing channel is unregistered, so that its
    ndo_stop() neither sends bus off nor turns off the calibration
    messages. This path is only reached when sending bus off to this
    channel has just failed, so these commands would most likely fail
    as well, and patch 7 removes this call;
  - asynchronous restart URBs not killed before free_candev():
    pre-existing, left for the separate series announced in v6;
  - pcan_usb_wait_rsp() checks neither the length nor the function of
    the response: pre-existing, left for a later hardening series.
- Tested on PCAN-USB Pro, PCAN-USB Pro FD, PCAN-USB FD and PCAN-USB on
  the same bus, with the driver of this series built against v7.0,
  checked with usbmon: probe; bitrate changes (250k/500k) and CAN
  channel ID writes on PCAN-USB, which also re-enumerates the device;
  CAN channel ID read and write with ethtool -e/-E on both PCAN-USB Pro
  channels; about 40 bus-off/auto-restart cycles on all six channels;
  hot unplug and re-plug of each adapter during TX/RX traffic with its
  interfaces up; module removal with all the interfaces up. The new
  error paths of the decoders were not exercised.

- Link to v7: https://lore.kernel.org/r/20261030-canfd_check_channel_idx-v7-0-fc4a3faf3acf@peak-system.fr

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
Stefan Günther (1):
      can: peak_usb: fix missing CAN_ERR_FLAG when reporting error counters

Stéphane Grosjean (13):
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
      can: peak_usb: pass the dev_num argument of PCAN-USB Pro GETDEVID
      can: peak_usb: don't send uninitialized stack bytes to PCAN-USB devices
      can: peak_usb: don't send uninitialized heap bytes in restart commands

 drivers/net/can/usb/peak_usb/pcan_usb.c      |  67 +++++++++++------
 drivers/net/can/usb/peak_usb/pcan_usb_core.c | 107 +++++++++++++++++++--------
 drivers/net/can/usb/peak_usb/pcan_usb_core.h |  10 ++-
 drivers/net/can/usb/peak_usb/pcan_usb_fd.c   |  91 +++++++++++++++--------
 drivers/net/can/usb/peak_usb/pcan_usb_pro.c  |  85 ++++++++++++++-------
 5 files changed, 248 insertions(+), 112 deletions(-)
---
base-commit: a7bfaba4823e3c165bb2004c74eff7c096672bc7
change-id: 20261007-canfd_check_channel_idx-a4d7a1a1ee7d

Best regards,
-- 
Stéphane Grosjean <s.grosjean@peak-system.fr>

