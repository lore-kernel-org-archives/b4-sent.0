From: Colin Huang <u8813345@gmail.com>
Subject: [PATCH linux dev-6.18 0/2] Add Delta Q54SN120A1 Q54SW120A7 chip
Date: Tue, 19 May 2026 15:45:56 +0800
Message-Id: <20260519-dev-6-18-add-delta-q54sn120a1-q54sw120a7-v1-0-9b5eb2c0752e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADUVDGoC/x2NQQ6CMBAAv9Ls2TW71SL4FcOh2kU3IVVbQRLC3
 629zVxmVsiSVDKczQpJZs36jEV4Z+D28PEuqKE4WLINOe4wyIwNcos+hCLjx+PbHXNkS54rfv9
 4QrI8dM7T9eAISu6VZNClri4wapwWU1t7bqHfth9/5w4BigAAAA==
X-Change-ID: 20260519-dev-6-18-add-delta-q54sn120a1-q54sw120a7-021f95a0b350
To: openbmc@lists.ozlabs.org, joel@jms.id.au, andrew@codeconstruct.com.au
Cc: Colin Huang <colin.huang2@amd.com>, Colin Huang <u8813345@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779176768; l=707;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=XMOB0cFD40jSUilaf/nyMrWOXkpV4oyN3ij3q2lnZRo=;
 b=cWxi+LbdxzMXtiYNslQYIT9Vh6BZO6xLvoRW7LGZEy4Dv+yvzlNlLmumVY1FPZ5WTtL9bEFFm
 NY0iM2+mEmCDeCz8mI5FmLvPWxEEtkBsAxHEtv4cOMP3uERvBYorHjL
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

adds support for the Delta Q54SN120A1 and Q54SW120A7
1/4-brick DC/DC power modules with PMBus capability.

Signed-off-by: Colin Huang <u8813345@gmail.com>
---
Colin Huang (2):
      dt-bindings: trivial-devices: Add Delta Q54SN120A1 and Q54SW120A7
      hwmon: (pmbus) Add Delta Q54SN120A1 Q54SW120A7 chip

 Documentation/devicetree/bindings/trivial-devices.yaml |  4 ++++
 drivers/hwmon/pmbus/q54sj108a2.c                       | 18 +++++++++++++++---
 2 files changed, 19 insertions(+), 3 deletions(-)
---
base-commit: 6e22b9e818d68d7b8ce6680aede0c80a9355929a
change-id: 20260519-dev-6-18-add-delta-q54sn120a1-q54sw120a7-021f95a0b350

Best regards,
-- 
Colin Huang <u8813345@gmail.com>

