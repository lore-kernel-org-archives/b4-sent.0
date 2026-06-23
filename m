From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Subject: [PATCH 0/3] Support onsemi's FD5121 multiphase digital controller
Date: Mon, 22 Jun 2026 22:55:36 -0700
Message-Id: <20260622-support-fd5121-from-onsemi-v1-0-b31767689c65@onsemi.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANgfOmoC/x3MOwrDMAwA0KsEzRXYgpgmVwkd8pFaDbGN1JZCy
 N1jOr7lHeBsyg5jd4DxV11Lboi3DtbXnJ+MujUDBUohEaF/ai32Rtn6SBHFyo4lO++KSeZBhvv
 SLxKgBdVY9PfPp8d5XqV2fBNsAAAA
To: Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782194144; l=1270;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=XxHC+WBSkAS51ORVmSx/YM7z+DWofPW1mqwUDLPdqdM=;
 b=O+5KQ40A0TgaP9oDBztyUxV5bx3S4eld/u7bTs2DIoewQ62OMXYw1Teqm/wZU2hGyUq1sWYER
 WIeYGdvs3CHCJgve+f30LSywGE3AVupaO6zFCZc4ze9WtXQ13Cfl/KO
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FD5121 is a dual rail, multi-phase controller designed to
power CPU, ASIC or SoC with fully configurable rails.

This driver adds support for FD5121, FD5123 and FD5125. These
controllers configurability through PMBus 1.4.1. 

Added documents for these controllers.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
---
Selvamani Rajagopal (3):
      Documentation/hwmon: Add onsemi's FD5121 controllers' documentation
      dt-bindings: hwmon: pmbus: Support for onsemi's FD5121
      hwmon: (pmbus/fd5121): Add support FD5121, FD5123 and FD5125

 .../bindings/hwmon/pmbus/onnn,fd5121.yaml          |   41 +
 Documentation/hwmon/fd5121.rst                     |   93 ++
 Documentation/hwmon/index.rst                      |    1 +
 MAINTAINERS                                        |    8 +
 drivers/hwmon/pmbus/Kconfig                        |    9 +
 drivers/hwmon/pmbus/Makefile                       |    1 +
 drivers/hwmon/pmbus/fd5121.c                       | 1004 ++++++++++++++++++++
 7 files changed, 1157 insertions(+)
---
base-commit: 1a3746ccbb0a97bed3c06ccde6b880013b1dddc1
change-id: 20260622-support-fd5121-from-onsemi-6fa9f98b5bf0

Best regards,
-- 
Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

