From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/2] hwmon: ltc4282: Small fixes and improvements
Date: Wed, 04 Mar 2026 10:17:46 +0000
Message-Id: <20260304-hwmon-ltc4282-minor-improvs-v1-0-344622924d3a@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqEMAwAwK9IzgZqrFX8iuxB3KgB20oqriD+3
 bLHucwNiVU4QV/coHxKkhgyqrKAaR3DwijfbCBDztTG4vrzMeB2TJY6Qi8hKorfNZ4JG0dV2zh
 n7NxCHnblWa7/Pnye5wWZ1jCbbQAAAA==
X-Change-ID: 20260304-hwmon-ltc4282-minor-improvs-5621756604f7
To: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772619475; l=750;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=GyiIZCoxRRp/uGhPOPVKST1Kfcf+hq2zesY60smmkkE=;
 b=+gwvYRVWbzYZsGFPtiJeT8liks7cQyjV4IyJpGBSofuwrko+cn3BtLL1KaIb1sRyLzpwYqIuH
 Y0DFpr9g2kACzmlbZZJhGSSjErsnsEx469802Ffa8aDKYe3g6X06ara
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Small series to remove scanned addresses in the docs (given there's no
detection being done in the driver). Also, in hwmon, we do want to be
able to probe devices even if there's no firmware properties
(description) available. Hence, make sure we do not fail if there's no
rsense property and define a sane enough default.

---
Nuno Sá (2):
      docs: hwmon: ltc4282: Fix scanned addresses
      hwmon: (ltc4282) Add default rsense value

 Documentation/hwmon/ltc4282.rst |  3 +--
 drivers/hwmon/ltc4282.c         | 15 ++++++++-------
 2 files changed, 9 insertions(+), 9 deletions(-)
---
base-commit: 78558965440b27814592ec82d8f3668395953b1b
change-id: 20260304-hwmon-ltc4282-minor-improvs-5621756604f7
--

Thanks!
- Nuno Sá

