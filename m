From: Bishwa Bhusan Saha <contact@bishwasaha.com>
Subject: [PATCH v2 0/5] HID: add battery driver for the UNCTRL RAGE
 Wireless Mouse
Date: Tue, 13 Oct 2026 02:43:55 +0530
Message-Id: <20261013-b4-unctrl-m1-battery-v2-0-bd6752021753@bishwasaha.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNTQ6CMBBGr0Jm7Zi2oE1ceQ/DYloHWyM/aQtKC
 He34AFcvuT73lsgcvAc4VIsEHjy0fddBnUowDrqHoz+nhmUUGcpZImmwrGzKbywlWgoJQ4zVtQ
 YaqS2ggnydQjc+M+uvdU/jqN5sk2ba1s4H1Mf5r07yW33JzFJFLlzEkqURkutr8ZH96ZIjo62b
 6Fe1/ULid5JQc8AAAA=
X-Change-ID: 20261013-b4-unctrl-m1-battery-4afbaf17c0ea
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Bishwa Bhusan Saha <contact@bishwasaha.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791839640; l=1677;
 i=contact@bishwasaha.com; s=20261012; h=from:subject:message-id;
 bh=nJPy7UDjWDIiUcSUvFAmlraZpWAPqkdIxP1kCUdLka8=;
 b=crBZF87C5xtacr5g3Ez3+6yXk5QBDpuM92eqTsSq9hP/ukcARoPm0N0FKvs3/Z0xNBScr/pSu
 n/m3SIEtlL0CpdJPCxnkZEbYZR+FW4F40WU9Cwu5JxN++h+9y8DazZk
X-Developer-Key: i=contact@bishwasaha.com; a=ed25519;
 pk=bW8B6BzX1VU4IIcYagrb5nNRxBho+rTXaQZ8fLx8CoU=
X-Endpoint-Received: by B4 Relay for contact@bishwasaha.com/20261012 with auth_id=1168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds battery reporting for the UNCTRL RAGE Wireless Mouse.
Parts of the driver are inspired by the Kysona HID driver
(drivers/hid/hid-kysona.c).

It was tested on an UNCTRL RAGE Wireless Mouse.

Signed-off-by: Bishwa Bhusan Saha <contact@bishwasaha.com>
---
Changes in v2:
- restructure the battery handover to fix the races found in review
- register the replacement supply before the previous owner is torn down,
  so a failed registration cannot leave the mouse batteryless
- deliver the probe-time query reply with hid_device_io_start()
- schedule the polling on the freezable workqueue, no CPU wake during
  suspend
- Link to v1: https://patch.msgid.link/20261013-b4-unctrl-m1-battery-v1-0-4a50203b7177@bishwasaha.com

To: Jiri Kosina <jikos@kernel.org>
To: Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Bishwa Bhusan Saha (5):
      HID: add IDs for UNCTRL RAGE Mouse
      HID: UNCTRL: add basic battery reporting for UNCTRL RAGE Mouse
      HID: UNCTRL: add periodic battery reporting using a workqueue
      HID: UNCTRL: keep a single battery when a mouse has multiple connections
      HID: UNCTRL: only report to userspace on battery changes

 drivers/hid/Kconfig         |   8 +
 drivers/hid/Makefile        |   1 +
 drivers/hid/hid-ids.h       |   2 +
 drivers/hid/hid-unctrl-m1.c | 436 ++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 447 insertions(+)
---
base-commit: 145c2b2e9a5c0f794fb4009bcb072ab19f8ccfcd
change-id: 20261013-b4-unctrl-m1-battery-4afbaf17c0ea

Best regards,
--  
Bishwa Bhusan Saha <contact@bishwasaha.com>

