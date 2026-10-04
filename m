From: Amit Sunil Dhamne <amitsd@google.com>
Subject: [PATCH 0/2] usb: typec: tcpm: Make tSenderResponse timer
 configurable
Date: Sun, 04 Oct 2026 02:58:27 +0000
Message-Id: <20261004-tcpm-sender-response-time-v1-0-3f8b43084acc@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANPAwWoC/x3MQQqDMBBG4avIrDuQRrTaq5QuNP7aWRjDTJCCe
 HeDy2/x3kEGFRi9q4MUu5hsseD5qCj8hriAZSom73zret9zDmllQ5ygrLC0RQNnWcFN6OAx1PP
 4clT6pJjlf78/3/O8AAMMS3lrAAAA
X-Change-ID: 20260929-tcpm-sender-response-time-5c8e2ea3fb70
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, RD Babiera <rdbabiera@google.com>, 
 Kyle Tso <kyletso@google.com>, Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791082733; l=1243;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=KzjthnmCLYw64a/ikn+1bUYSwFtrdm5q2IQ3Uug6p3U=;
 b=eDgZfQEI2dz/Oxx5eLj3uKc8L/d9Qia/wBN6f4/T564Ajq/GB+dD5xDZ2hc+RNR8Hy3ypRK4Z
 27FNvV6Sf2EBu890+MLkOnXz3RRTCUY7SA1g2Ip8Rv9jboTlx/A5kmJ
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

TCPM currently uses a fixed, relaxed tSenderResponse value of 60 ms
(PD_T_SENDER_RESPONSE) for all typec ports. This series adds an
optional "sender-response-time-ms" connector property so that platforms
can specify a different value. Ports that don't specify the property
continue to use 60 ms, so the existing behavior is unchanged.

Dependencies:
Patch 2 ("usb: typec: tcpm: Allow configuring tSenderResponse via
fwnode") depends on patch 1 ("dt-bindings: connector: Add time property
for tSenderResponse"), as patch 1 documents the property that patch 2
parses.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
Amit Sunil Dhamne (2):
      dt-bindings: connector: Add time property for tSenderResponse
      usb: typec: tcpm: Allow configuring tSenderResponse via fwnode

 .../bindings/connector/usb-connector.yaml          |  9 ++++++
 .../devicetree/bindings/usb/maxim,max33359.yaml    |  1 +
 drivers/usb/typec/tcpm/tcpm.c                      | 35 ++++++++++++++--------
 3 files changed, 32 insertions(+), 13 deletions(-)
---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260929-tcpm-sender-response-time-5c8e2ea3fb70

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

