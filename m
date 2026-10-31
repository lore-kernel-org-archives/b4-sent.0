From: Ernesto Salvetti <ernesto.salvetti@tambosi.tn.it>
Subject: [PATCH 0/3] Bluetooth: Fix LE on Barrot 33fa:0010 controllers
Date: Sat, 31 Oct 2026 13:16:14 +0100
Message-Id: <20261031-barrot-le-fixes-v1-v1-0-30e2089882bf@tambosi.tn.it>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQ6CMBBEf4Xs2Y20IIn+ivHQli2s0WJ2KzEh/
 LutHt/MvNlASZgULs0GQisrL6mAOTQQZpcmQh4Lg23tYNrOoHciS8YHYeQPKa4Gz6fB9jGOres
 7KOJL6NcV73r7s779nUKuT3XhnRJ6cSnMNVqEJ07Hp9NMAvv+BZfbsLuWAAAA
X-Change-ID: 20261031-barrot-le-fixes-v1-95624ffd0a43
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ernesto Salvetti <ernesto.salvetti@tambosi.tn.it>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793448994; l=3307;
 i=ernesto.salvetti@tambosi.tn.it; s=20261031; h=from:subject:message-id;
 bh=NkLdEkh7bgUMhoEF7i6a2/grihrcRLLsAyrSVjURO74=;
 b=wK3wUlz5FRjKma6NmX35el7rDepELpXhStFn1qiVneFSiKgL6kqYf5U7KioRaw0F5Ek6AqFNN
 KpV62SJyZhICUFPIA7EnpJxUFUMiq9LOfZ01Oc3xSIY9RphQlLZlmqY
X-Developer-Key: i=ernesto.salvetti@tambosi.tn.it; a=ed25519;
 pk=OLNiuyRbYD4dcNYoAvM99nt/1KZTKeM316r91BCQDUs=
X-Endpoint-Received: by B4 Relay for ernesto.salvetti@tambosi.tn.it/20261031 with auth_id=1370
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The UGREEN Bluetooth 5.4 USB dongle (33fa:0010, Barrot chip, bound to
btusb via BTUSB_BARROT) works for BR/EDR, but LE is unusable: as soon as
a scan is started the controller hangs on LE Set Extended Scan
Parameters and btusb resets it in a loop. Once that is avoided, two more
problems show up before an LE device can be used. This series fixes
them one at a time:

1/3 Setting HCI_QUIRK_BROKEN_EXT_SCAN alone is not enough on a
    controller that enforces the spec rule that legacy and extended
    LE commands must not be mixed: the stack still uses extended
    advertising (LE Read Number of Supported Advertising Sets is sent
    during init), after which the legacy scan commands are rejected
    with Command Disallowed. Don't use extended advertising when
    extended scanning is marked broken. This also affects the other
    users of the quirk (hci_bcm4377, Actions ATS2851 and Realtek
    0bda:a728 in btusb), which will fall back to legacy advertising;
    I could not test those.

2/3 The controller answers LE Read Remote Used Features with
    Controller Busy right after connecting, and the stack drops the
    link. Continue without the remote features instead.

3/3 Set HCI_QUIRK_BROKEN_EXT_SCAN and HCI_QUIRK_BROKEN_EXT_CREATE_CONN
    for BTUSB_BARROT devices.

Testing: on bluetooth-next each patch builds (clang, W=1) without new
warnings. The runtime tests were done on v7.2.11 (PikaOS kernel) with
the series backported; patch 2 needed a context adjustment there, since
hci_cs_le_read_remote_features() in v7.2.11 lacks the
HCI_ERROR_UNSUPPORTED_REMOTE_FEATURE handling. With a 33fa:0010
(bcdDevice 88.91) and an Xbox Wireless Controller, checked with btmon:

 - without patch 1: Command Disallowed on every LE Set Scan Parameters
 - with the full series: scanning works, LE Secure Connections pairing
   from scratch succeeds, reconnecting with the stored LTK works, and
   the controller shows up as HID gamepad (hid-microsoft).

Before that I used an earlier btusb-only workaround with the same
effect for an afternoon of gaming without problems.

33fa:0012 shares the BTUSB_BARROT flag but I don't have one to test.

Tool use: the investigation and the patches were done with the help of
an AI coding assistant (Claude, Anthropic) in an interactive session.
It analysed the btmon/dmesg logs, read the relevant core code, proposed
and wrote the changes and the changelogs, and ran checkpatch. I ran all
hardware tests, reviewed the changes and take responsibility for them.
The patches carry an Assisted-by tag accordingly.

---
Ernesto Salvetti (3):
      Bluetooth: hci_core: Don't use extended advertising with broken ext scan
      Bluetooth: hci_event: Don't drop LE link on busy remote features read
      Bluetooth: btusb: Disable broken LE extended scan on Barrot controllers

 drivers/bluetooth/btusb_main.c   |  6 ++++++
 include/net/bluetooth/hci.h      |  5 ++++-
 include/net/bluetooth/hci_core.h | 11 +++++++++--
 net/bluetooth/hci_event.c        | 11 +++++++++++
 4 files changed, 30 insertions(+), 3 deletions(-)
---
base-commit: 42b8c2d729268a65a2d98064e8dc59ff53646b14
change-id: 20261031-barrot-le-fixes-v1-95624ffd0a43

Best regards,
--  
Ernesto Salvetti <ernesto.salvetti@tambosi.tn.it>

