From: Amit Sunil Dhamne <amitsd@google.com>
Subject: [PATCH 0/3] Add support for responding to Get_Revision request
Date: Thu, 05 Dec 2024 23:46:07 -0800
Message-Id: <20241205-get_rev_upstream-v1-0-90158ee7d75f@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL+rUmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDIwNT3fTUknigwvjSguKSotTEXF2zJDMDIDAzNkhMUwJqKyhKTcusABs
 ZHVtbCwAxUc9OYgAAAA==
X-Change-ID: 20241205-get_rev_upstream-6b60000630af
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>
Cc: Kyle Tso <kyletso@google.com>, RD Babiera <rdbabiera@google.com>, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733471217; l=1144;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=rIuOPSZ3vHFGNWi/6Cw75i5UpoJ+Y1ASP/eaOjNNLBM=;
 b=YKIez4YBYfYYsJa+1AFtSUFmhxjiYGDNbHUnDHgje5A92QwKJb1MDUDHicgLm/fG50ZXNaFKO
 hWZgAPclbrjA6EW8y4PTa5t4ewhu1cFc7i5+UUVEribllXSFCzKP63M
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently TCPM doesn't support responding to Get_Revision request
message. However, as per Message Applicability in USB PD Spec 3.1 v1.8
("6.13.2 Applicability of Data Messages") "Revision" is a Normative
(compulsory) message and needs to be supported. As part of this patchset
add support for responding to Get_Revision requests as part of
Revision_Information AMS.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
Amit Sunil Dhamne (3):
      dt-bindings: connector: Add pd-revision property
      usb: typec: tcpm: Add support for parsing pd-revision DT property
      usb: typec: tcpm: Add new AMS for Get_Revision response

 .../bindings/connector/usb-connector.yaml          |  6 ++
 .../devicetree/bindings/usb/maxim,max33359.yaml    |  1 +
 drivers/usb/typec/tcpm/tcpm.c                      | 87 +++++++++++++++++++++-
 include/linux/usb/pd.h                             | 22 +++++-
 4 files changed, 111 insertions(+), 5 deletions(-)
---
base-commit: 40384c840ea1944d7c5a392e8975ed088ecf0b37
change-id: 20241205-get_rev_upstream-6b60000630af

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

