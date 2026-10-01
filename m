From: Amit Sunil Dhamne <amitsd@google.com>
Subject: [PATCH 0/3] usb: typec: report a current limit for non-PD Rp-def
 sources
Date: Thu, 01 Oct 2026 22:51:12 +0000
Message-Id: <20261001-max77759-icl-typec-v1-0-99ada1f65ced@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAODjvmoC/x3MTQqAIBBA4avErBtIo9SuEi1KxxroD40oorsnL
 b/Few9ECkwRmuyBQCdH3tYEkWdgp34dCdklgyxkXRihcekvpVRlkO2Mx72TRe38YLwunRISUrg
 H8nz907Z73w94IQwyZAAAAA==
X-Change-ID: 20260918-max77759-icl-typec-8dfb9f83d712
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790895080; l=1851;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=YrfD6f4Lo82zURUGW6cJqr7xJNdH6s6PlN+VnuALevU=;
 b=yXhA0wxE+WnbapdtWpIVV+HwjH2Rn8Z15JsA6cQFWRZXwr33/yEtJI06ux2bl3YHrNanqHmq9
 oCNCN0Ew9/yCv+0259VaG4lUJevSYjmLqC2cT0jdphCwpFkDtuNfUbt
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As per Sec. 4.6.2.1 of the Type-C cable & connector spec when the
source advertises Rp-default, the current limit is set as per the
USB 2.0/USB 3.2 specification, BC1.2 specification as applicable or the
PD negotiation.

Reset value for the Input Current Limit register for the MAX77759
charger is 500 mA. Prior to the max77759_charger driver, the battery
would always charge at that limit since it wasn't re-programmed. Since
the driver was introduced, for any non-PD source advertising Rp-default,
the charger turns off as tcpm reports the current limit to be 0. The
max77759_charger driver reads POWER_SUPPLY_PROP_CURRENT_MAX from the
"tcpm-source" power supply that tcpm_set_current_limit() updates, and
programs its input current limit from it. The limit is 0 because the
tcpm doesn't have visibility on the USB data speed or BC1.2 detection.
As a workaround for the Rp-default case, let the Type-C stack report a
USB 2.0 current limit of 500 mA so that the behavior is at parity with
what was before. This is until we implement a conduit for USB core to
communicate with the Type-C stack.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
Amit Sunil Dhamne (3):
      usb: typec: tcpm: only call get_current_limit() for cc=Rp-def
      usb: typec: tcpci: implement get_current_limit
      usb: typec: tcpci_maxim: implement get_current_limit

 drivers/usb/typec/tcpm/tcpci.c            | 14 ++++++++++++++
 drivers/usb/typec/tcpm/tcpci_maxim_core.c | 15 +++++++++++++++
 drivers/usb/typec/tcpm/tcpm.c             |  7 +++----
 include/linux/usb/tcpci.h                 |  6 ++++++
 4 files changed, 38 insertions(+), 4 deletions(-)
---
base-commit: 551c722f40809618230001baccf219193e22fc5a
change-id: 20260918-max77759-icl-typec-8dfb9f83d712

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

