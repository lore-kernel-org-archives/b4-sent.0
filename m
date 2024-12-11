From: Amit Sunil Dhamne <amitsd@google.com>
Subject: [PATCH v2 0/3] Add support for responding to Get_Revision request
Date: Tue, 10 Dec 2024 19:07:06 -0800
Message-Id: <20241210-get_rev_upstream-v2-0-d0094e52d48f@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANoBWWcC/32NTQ7CIBCFr9LMWsyAlmpX3sM0DbYDJbGlASSah
 ruLPYBv9728nw0CeUsB2moDT8kG65YC4lDBMKnFELNjYRAozlxgzQzFvgT71xqiJzUz+ZBYJE+
 oNJTa6knb9z557wpPNkTnP/tD4j/3z1jiDNkVeX0hasam1jfjnHnScXAzdDnnL/C4TpKxAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733886444; l=1318;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=CEwUdYH0nCr9FSjB3Vc7SkwELpFgK6Eq00uXcIMkpiM=;
 b=NZyEywntSJaRNYEZgJ8E1nGOMQ+NnCFvACWapkVOKgSHnikaWWYbndwYepCoL4hFEpOZ6EbpJ
 X+zZYEYLd6mCY2VY+ChM5709KSmPLyIzVgxByByztlHn5EoHhA/6+a+
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
Changes in v2:
- Added maxItems constraint to "pd-revision" property
- Link to v1: https://lore.kernel.org/r/20241205-get_rev_upstream-v1-0-90158ee7d75f@google.com

---
Amit Sunil Dhamne (3):
      dt-bindings: connector: Add pd-revision property
      usb: typec: tcpm: Add support for parsing pd-revision DT property
      usb: typec: tcpm: Add new AMS for Get_Revision response

 .../bindings/connector/usb-connector.yaml          |  7 ++
 .../devicetree/bindings/usb/maxim,max33359.yaml    |  1 +
 drivers/usb/typec/tcpm/tcpm.c                      | 87 +++++++++++++++++++++-
 include/linux/usb/pd.h                             | 22 +++++-
 4 files changed, 112 insertions(+), 5 deletions(-)
---
base-commit: 40384c840ea1944d7c5a392e8975ed088ecf0b37
change-id: 20241205-get_rev_upstream-6b60000630af

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

