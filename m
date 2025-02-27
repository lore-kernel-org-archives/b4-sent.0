From: Maud Spierings <maudspierings@gocontroll.com>
Date: Thu, 27 Feb 2025 13:57:51 +0100
Subject: [PATCH 1/3] hwmon: (ntc_thermistor) Fix module name in the Kconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-ntc_thermistor_fixes-v1-1-70fa73200b52@gocontroll.com>
References: <20250227-ntc_thermistor_fixes-v1-0-70fa73200b52@gocontroll.com>
In-Reply-To: <20250227-ntc_thermistor_fixes-v1-0-70fa73200b52@gocontroll.com>
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Joseph McNally <jmcna06@gmail.com>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740661074; l=743;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=CLTYjs2EJuZ8AOQpyWvAI5IZIGOf4Vy3v9F7+NSObQI=;
 b=jIE6CDMcjNgjAACih30JjMeRi7CzIfb/aOj4o3bAKwrLEDf6KQWIuGs0pUyA/lIMyvkTH/Eat
 x4bPYgzLzDzA9N19Dhe1ccbg5GPLT/T8oBM6Z9VYsENJKZhQd/Wi0c0
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The module name is incorrectly stated with a hyphen while it is an
underscore.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 drivers/hwmon/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/hwmon/Kconfig b/drivers/hwmon/Kconfig
index f114d0c55d7831fc5d914d19a6e543cb2dbb5659..56494ab85b83b1c10a7dbf3085abea2900e9aaa1 100644
--- a/drivers/hwmon/Kconfig
+++ b/drivers/hwmon/Kconfig
@@ -1625,7 +1625,7 @@ config SENSORS_NTC_THERMISTOR
 	  B57891S0103 from EPCOS.
 
 	  This driver can also be built as a module. If so, the module
-	  will be called ntc-thermistor.
+	  will be called ntc_thermistor.
 
 config SENSORS_NCT6683
 	tristate "Nuvoton NCT6683D"

-- 
2.48.1

