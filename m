From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Subject: [PATCH v2 0/2] HID: iio: gyro: hid-sensor-gyro-3d: probe cleanup
Date: Fri, 24 Jul 2026 22:57:19 +0530
Message-Id: <20260724-24-july-hid-gyro-dev-log-clenaup-v2-0-01671b07b181@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHegY2oC/5WOTQ6DIBSEr2JY9zWI+NdV79G4QHxFDIoBJTXGu
 xftCZrM5ksm38xOPDqNnjySnTgM2ms7RWC3hMheTApBd5EJo6ygJeMQM6xmg153oDZnocMAxiq
 QBiexzsCrKs84srwuchI1s8O3/lwTr+bHfm0HlMvpPRu99ot12/UhpGfvj7mQAgUq64y1ZZlSL
 p5qFNrcpR1JcxzHF3IMN8XiAAAA
X-Change-ID: 20260724-24-july-hid-gyro-dev-log-clenaup-488534e25965
To: Jiri Kosina <jikos@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-input@vger.kernel.org, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784914055; l=995;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=Q8O0HRili88+kqRUmMRAKNjA4ogSwlUgyxWECroV3PI=;
 b=DON69jzEGDk/yDKaqYyepQG5hJe7y2h7PKCHt12aNSUSR0XjCWxinKxfZMuaqtduqVVw3UmAy
 RO2GvLyf2lYD1RG25+fAjUWr4fU7ENjBwyqJmHhD4Yi6wYNJaQlUGri
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

This series cleans up probe error handling in the hid-sensor-gyro-3d
driver by removing redundant dev_err() calls and replacing remaining
dev_err() with dev_err_probe() to simplify error handling.

Testing:
 - Compiled with W=1 for each patch in series

---
Changes in v2:
- EDITME: describe what is new in this series revision.
- EDITME: use bulletpoints and terse descriptions.
- Link to v1: https://patch.msgid.link/20260724-24-july-hid-gyro-dev-log-clenaup-v1-0-0c932b77104a@gmail.com

---
Sanjay Chitroda (2):
      iio: gyro: hid-sensor-gyro-3d: Remove redundant dev_err()
      iio: gyro: hid-sensor-gyro-3d: Use dev_err_probe()

 drivers/iio/gyro/hid-sensor-gyro-3d.c | 35 ++++++++++++-----------------------
 1 file changed, 12 insertions(+), 23 deletions(-)
---
base-commit: 36c12dbda81c284d72f3c64689461647497b643b
change-id: 20260724-24-july-hid-gyro-dev-log-clenaup-488534e25965

Best regards,
--  
Sanjay Chitroda <sanjayembeddedse@gmail.com>

