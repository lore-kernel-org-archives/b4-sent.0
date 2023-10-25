From: Richard Leitner <richard.leitner@linux.dev>
Date: Wed, 25 Oct 2023 10:34:11 +0000
Subject: [PATCH 1/4] MAINTAINERS: Add entry for ina238 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231025-ina237-v1-1-a0196119720c@linux.dev>
References: <20231025-ina237-v1-0-a0196119720c@linux.dev>
In-Reply-To: <20231025-ina237-v1-0-a0196119720c@linux.dev>
To: Guenter Roeck <linux@roeck-us.net>, Jean Delvare <jdelvare@suse.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1698230088; l=764;
 i=richard.leitner@linux.dev; s=20231025; h=from:subject:message-id;
 bh=To9+llqVwQfE3FZYma/wWqALeRFyp/9+Ac4qHFPwfQc=;
 b=GbcBOmbxKW/NaOZK/tWlRFetfHjOKl+VCAXOa2pUDIWUfcoEjx++tHSDimH9wHPkypn2z8yR908y
 oV7A1CFxDLcMhgE5pRVfnFfPrGx+xr9d6mKqdI52FLyq7kX1jBXV
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=ZYa5+0m9RFYtnNU6DLet7sHyPehnVHa0ucJlYiAu2NU=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20231025 with auth_id=90
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ina238 driver is available since 2021 but lacks a MAINTAINERS entry
file. Therefore add the missing entry now.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 MAINTAINERS | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 668d1e24452d..28f91c8a2e1c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -10267,6 +10267,12 @@ F:	Documentation/hwmon/ina2xx.rst
 F:	drivers/hwmon/ina2xx.c
 F:	include/linux/platform_data/ina2xx.h
 
+INA238 HARDWARE MONITOR DRIVER
+M:	Guenter Roeck <linux@roeck-us.net>
+L:	linux-hwmon@vger.kernel.org
+S:	Maintained
+F:	drivers/hwmon/ina238.c
+
 INDEX OF FURTHER KERNEL DOCUMENTATION
 M:	Carlos Bilbao <carlos.bilbao@amd.com>
 S:	Maintained

-- 
2.40.1

