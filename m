From: Martin Oberleiter <martin.oberleiter@netixx.it>
Subject: [PATCH 0/2] HID: steelseries: Add Rival 3 Wireless battery
 reporting
Date: Fri, 30 Oct 2026 07:37:23 +0100
Message-Id: <20261030-rival3-battery-v1-0-6b1feeaf1f52@netixx.it>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBA0auUWRvIJNBaryIu0mSqI6XKTAxKy
 d1NdfkW/2+gJEwKp24DocLKj7UBDx3EW1ivZDg1g7OuR+utES5h8WYKOZN8TEg4xIQjoTtCi55
 CM79/w/Plb31Nd4p5v0CtX8z5dMRyAAAA
X-Change-ID: 20261030-rival3-battery-ad17cd19e128
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Martin Oberleiter <martin.oberleiter@netixx.it>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793342246; l=1381;
 i=martin.oberleiter@netixx.it; s=20261029; h=from:subject:message-id;
 bh=w2YXVZYcFQtYvcPZlkSrEitR77JlEJPlKV28pnvKM1w=;
 b=r9SKXG0CoTMTJNm2t90BHjbWdY9eaJvXd7sy9opMAHC8ojVWVEuBYTGFyjBtDbjN5GLn9PrmU
 TmNPZa+jKb/AFLQcg4OLDEC5+J5InHrxjCth8frB9mF7woPUA/53odh
X-Developer-Key: i=martin.oberleiter@netixx.it; a=ed25519;
 pk=yZvkAuAsIiJ76LEGGTR3TI7+Xjw7lGN1dK6jcv72XZo=
X-Endpoint-Received: by B4 Relay for martin.oberleiter@netixx.it/20261029 with auth_id=1358
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SteelSeries Rival 3 Wireless mouse reports its battery level on
request through its 2.4 GHz receiver, using the protocol rivalcfg
implements. This series exposes it as a power supply.

Patch 1 makes HID_STEELSERIES select POWER_SUPPLY, which the Arctis
headset support already needs and which patch 2 relies on as well.

Patch 2 adds the battery reporting. Desktops currently show the mouse's
battery with a keyboard icon: upower picks the kind from the sibling
input devices and prefers the mouse's auxiliary keyboard interface. That
is a upower heuristic and will be reported there separately.

Tested on a Rival 3 Wireless (receiver 1038:1830) over a night with the
mouse switched off and on again.

The series was written with the help of an AI coding assistant (Claude
Code); details are in the changelog of patch 2.

---
Martin Oberleiter (2):
      HID: steelseries: Select POWER_SUPPLY
      HID: steelseries: Add Rival 3 Wireless battery reporting

 drivers/hid/Kconfig           |   5 +-
 drivers/hid/hid-ids.h         |   1 +
 drivers/hid/hid-steelseries.c | 277 +++++++++++++++++++++++++++++++++++++++++-
 3 files changed, 277 insertions(+), 6 deletions(-)
---
base-commit: 720806515cb6921ab05caaa6f470f7054b56385e
change-id: 20261030-rival3-battery-ad17cd19e128

Best regards,
--  
Martin Oberleiter <martin.oberleiter@netixx.it>

