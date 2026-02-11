From: Amit Sunil Dhamne <amitsd@google.com>
Subject: [PATCH 0/2] Introduce Sink Cap Extended AMS
Date: Wed, 11 Feb 2026 23:25:34 +0000
Message-Id: <20260211-skedb-v1-0-616340426cdc@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO4PjWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDI0MD3eLs1JQkXdPE1KQkSxOTZGPTNCWg2oKi1LTMCrA50bG1tQCWUjG
 yVwAAAA==
X-Change-ID: 20260210-skedb-5aebb944c35f
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, Kyle Tso <kyletso@google.com>, 
 RD Babiera <rdbabiera@google.com>, Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770852352; l=974;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=izf2zG/94tc+KXQg6oNDoNUfu9pNiByjq4kRidr7zVM=;
 b=cRix6fAND3LqFyrOtrWPLIwMSOgmCQFRlycA6KzFaQG/mFd3ZQEaUt4FfZmV/Xzd2vZDbQhdm
 W3IOZ2Gg/xgCjFP2jU6jH2zXiZELyT2tcPBjDNRsrvh4w8U54UDlgdx
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds support for Sink Cap Extended AMS. This is a
"required" AMS for PD 3.1 compliance for Sink or DRP ports and a
pre-requisite for Battery Caps and Battery Status AMSes.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
Amit Sunil Dhamne (2):
      dt-bindings: connector: Add sink properties to comply with PD 3.1 spec
      usb: typec: tcpm: add support for Sink Cap Extended msg response

 .../bindings/connector/usb-connector.yaml          |  34 +++
 .../devicetree/bindings/usb/maxim,max33359.yaml    |   4 +
 drivers/usb/typec/tcpm/tcpm.c                      | 253 ++++++++++++++++++++-
 include/dt-bindings/usb/pd.h                       |  18 ++
 include/linux/usb/pd.h                             |  82 ++++++-
 5 files changed, 388 insertions(+), 3 deletions(-)
---
base-commit: 8dfce8991b95d8625d0a1d2896e42f93b9d7f68d
change-id: 20260210-skedb-5aebb944c35f

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

