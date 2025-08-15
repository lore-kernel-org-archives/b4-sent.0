From: Amit Sunil Dhamne <amitsd@google.com>
Subject: [PATCH 0/2] Fixes for maxim tcpc contaminant detection logic
Date: Thu, 14 Aug 2025 19:34:08 -0700
Message-Id: <20250814-fix-upstream-contaminant-v1-0-801ce8089031@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKCcnmgC/x2MQQqDMBAAvyJ77kKyoLX9SulhiWvdQ1ZJUhGCf
 zd4HJiZClmSSoZ3VyHJrllXa+AfHYSF7SeoU2MgR70bHeGsB/63XJJwxLBa4ajGVtAPL++EngM
 FhpZvSZp7rz/f87wAiqpoo2oAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755225269; l=688;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=WOkfKQC4WAjGci8A3ZUdsKmLH/c07Chzph9ljFleBWE=;
 b=kK7Du+pE7rMDWYGp31Blr5Vm6EadjFMHsK2roZUl+5IhWaPHLdacfMjsxdTaXDrc3e6QNNdVk
 ttUrzC/U+sODYQQf5pGyOKXpoRmiTfezbp3Q1lDT5b9UBId5SD7jdUW
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add fixes to the CC contaminant/connection detection logic to improve
reliability and stability of the maxim tcpc driver.

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

