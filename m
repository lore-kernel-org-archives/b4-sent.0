From: Bishwa Bhusan Saha <contact@bishwasaha.com>
Subject: [PATCH 0/5] HID: add battery driver for the UNCTRL RAGE Wireless
 Mouse
Date: Tue, 13 Oct 2026 01:45:22 +0530
Message-Id: <20261013-b4-unctrl-m1-battery-v1-0-4a50203b7177@bishwasaha.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAyA4VcZORto5tjAVxEPaZe6DK2SdqKMv
 fuqHr/D/6+QxVQynJoVTF6a9ZEq6NBAmDhdBXWshta1PTk6ou9wSaHYDe+EnksR+2DH0XOkITh
 hqOnTJOr7tz1f/s6LnyWU7wu2bQch9LbKeAAAAA==
X-Change-ID: 20261013-b4-unctrl-m1-battery-4afbaf17c0ea
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Bishwa Bhusan Saha <contact@bishwasaha.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791836132; l=1047;
 i=contact@bishwasaha.com; s=20261012; h=from:subject:message-id;
 bh=ZQd8UAjXxdtjHCZDOWEnDScNlUHYQJBvBegfhdRjMc0=;
 b=b/JBuK54J2z3qKaxtebHMhp51n8aSRuTwwDPzszk9cMJZ8BFDRguCWR1fp5RtOzjDrO4ebk+D
 HXh7V3mDxmqC29iisNP3uELJSzBaD//wzOV2nJAwWhq6NEaSEZFLMI2
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
Bishwa Bhusan Saha (5):
      HID: add IDs for UNCTRL RAGE Mouse
      HID: UNCTRL: add basic battery reporting for UNCTRL RAGE Mouse
      HID: UNCTRL: add periodic battery reporting using a workqueue
      HID: UNCTRL: keep a single battery when a mouse has multiple connections
      HID: UNCTRL: only report to userspace on battery changes

 drivers/hid/Kconfig         |   8 +
 drivers/hid/Makefile        |   1 +
 drivers/hid/hid-ids.h       |   2 +
 drivers/hid/hid-unctrl-m1.c | 426 ++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 437 insertions(+)
---
base-commit: 145c2b2e9a5c0f794fb4009bcb072ab19f8ccfcd
change-id: 20261013-b4-unctrl-m1-battery-4afbaf17c0ea

Best regards,
--  
Bishwa Bhusan Saha <contact@bishwasaha.com>

