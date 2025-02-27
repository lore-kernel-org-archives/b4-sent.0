From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH 0/3] hwmon: (ntc_thermistor) typo fixes and incorrect table
 fix
Date: Thu, 27 Feb 2025 13:57:50 +0100
Message-Id: <20250227-ntc_thermistor_fixes-v1-0-70fa73200b52@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE5hwGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDIyNz3byS5PiSjNSi3Mzikvyi+LTMitRiXTMDE+NkCzMjS1OzRCWg1oK
 iVLAEUGd0bG0tAMKLl+lmAAAA
X-Change-ID: 20250227-ntc_thermistor_fixes-6043c862956a
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Joseph McNally <jmcna06@gmail.com>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740661074; l=882;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=fH4N0wG87WQDa0bhN9DzZrrecvbqHxRrAhkjPukdbA4=;
 b=dnRWEeSNNKaARGa6YQjxb6PbhJnpRMPY/d/CWj381ztZJmhOuOQ72cO44MAUmkPwFfptCwFCT
 dfiy+20BnjhDSy/LSMcwd4K8eb8dfkio4ndyeIVJdU4Epj1ODdMCRNx
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix some small mistakes in the Kconfig and bindings yaml, also fix the
incorrect sensor table for the ncpXXxh103 sensor.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
Maud Spierings (3):
      hwmon: (ntc_thermistor) Fix module name in the Kconfig
      dt-bindings: hwmon: ntc-thermistor: fix typo regarding the deprecation of the ntc, compatibles
      hwmon: (ntc_thermistor) Fix the ncpXXxh103 sensor table

 .../devicetree/bindings/hwmon/ntc-thermistor.yaml  |  2 +-
 drivers/hwmon/Kconfig                              |  2 +-
 drivers/hwmon/ntc_thermistor.c                     | 66 +++++++++++-----------
 3 files changed, 35 insertions(+), 35 deletions(-)
---
base-commit: be5c7bbb3a64baf884481a1ba0c2f8fb2f93f7c3
change-id: 20250227-ntc_thermistor_fixes-6043c862956a

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

