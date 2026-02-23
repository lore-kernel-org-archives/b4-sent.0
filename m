From: Amit Sunil Dhamne <amitsd@google.com>
Subject: [PATCH v2 0/2] Introduce Sink Cap Extended AMS
Date: Mon, 23 Feb 2026 20:05:36 +0000
Message-Id: <20260223-skedb-v2-0-60675765bc7e@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABCznGkC/zXMQQrDIBCF4auEWdeixgjtqvcoWUSdmKFtDFqkJ
 Xj3mNAu/8fjWyFhJExwbVaImClRmGvIUwN2GmaPjFxtkFxqLgVn6YHOsG5AYy5K2bYboX6XiCN
 9Dufe154ovUP8HmwW+/oXxE/IgnGmhW4VV1JbZ28+BP/Esw0v6EspG1Nk2v2bAAAA
X-Change-ID: 20260210-skedb-5aebb944c35f
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, Kyle Tso <kyletso@google.com>, 
 RD Babiera <rdbabiera@google.com>, Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771877137; l=1270;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=vGQeQO1YlbRwkKZNHV41+XdKwbW3ff4YznTfIuBhUik=;
 b=1C1YC5X/kdyac3vFIj+CpmhCvqTVNRN1152BDMfpHEuAlsUgPiGcj0ZN0S01BC4wXS0Zw3QX0
 jwY9y97k/gNA+TVdIHe+QlT68vRzDpjjBVhevRPfq1FIgRHs8pzhemf
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds support for Sink Cap Extended AMS. This is a
"required" AMS for PD 3.1 compliance for Sink or DRP ports and a
pre-requisite for Battery Caps and Battery Status AMSes.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
Changes in v2:
- Fixed comment for `struct sink_caps_ext_msg`, `struct pd_identifier` and
  `struct sink_caps_ext_data`. (Linux Test Robot)
- Added Reviewed-by tag for DT binding patch. (Rob Herring)
- Link to v1: https://lore.kernel.org/r/20260211-skedb-v1-0-616340426cdc@google.com

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
base-commit: 8bf22c33e7a172fbc72464f4cc484d23a6b412ba
change-id: 20260210-skedb-5aebb944c35f

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

