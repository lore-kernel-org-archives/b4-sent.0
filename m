From: Amit Sunil Dhamne <amitsd@google.com>
Subject: [PATCH v2 0/2] Fixes for maxim tcpc contaminant detection logic
Date: Fri, 15 Aug 2025 11:31:50 -0700
Message-Id: <20250815-fix-upstream-contaminant-v2-0-6c8d6c3adafb@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABZ9n2gC/3WNwQ6CMBBEf4Xs2TW7VbFw8j8Mh6au0ERa0laiI
 fy7lXj1+CYzbxZIEp0kaKsFoswuueALqF0FdjC+F3S3wqBInUiTwrt74XNKOYoZ0Qafzei88Rm
 5bphEnWtlDZT5FKV0N/W1Kzy4lEN8b08zf9OflI//pTMjoSa2okk3dOBLH0L/kL0NI3Trun4Ap
 7q6N8EAAAA=
X-Change-ID: 20250802-fix-upstream-contaminant-16910e2762ca
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, RD Babiera <rdbabiera@google.com>, 
 Kyle Tso <kyletso@google.com>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755282735; l=964;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=9z3lCu74Prxu4L02rJ9U7O515gDUwPsAhghQTM6Eae4=;
 b=Bfs56Qain5NfOqRZiiIJtu4ekQ+VVRIl0m0t7N1+x6vcxbjSKyqEoK6EXWZ5uJr/H1IreLjqr
 Vr02/CkUb2pBZVM5X2fjzY3k2Z+FUCc7/nGe7h/nKAx0okOQQqr3wu8
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add fixes to the CC contaminant/connection detection logic to improve
reliability and stability of the maxim tcpc driver. This patchset has
been tested on a PD Tester.

---
Changes in v2:
- Fix improperly formatted patch for stable inclusion. Tagged every
  patch in patchset for stable.
- Link to v1: https://lore.kernel.org/r/20250814-fix-upstream-contaminant-v1-0-801ce8089031@google.com

---
Amit Sunil Dhamne (2):
      usb: typec: maxim_contaminant: disable low power mode when reading comparator values
      usb: typec: maxim_contaminant: re-enable cc toggle if cc is open and port is clean

 drivers/usb/typec/tcpm/maxim_contaminant.c | 58 ++++++++++++++++++++++++++++++
 drivers/usb/typec/tcpm/tcpci_maxim.h       |  1 +
 2 files changed, 59 insertions(+)
---
base-commit: 89be9a83ccf1f88522317ce02f854f30d6115c41
change-id: 20250802-fix-upstream-contaminant-16910e2762ca

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

