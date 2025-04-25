From: Kurt Borja <kuurtb@gmail.com>
Subject: [PATCH 0/2] platform/x86: alienware-wmi-wmax: Fix unitialized
 variables in awcc_hwmon_fans_init()
Date: Fri, 25 Apr 2025 12:45:05 -0300
Message-Id: <20250425-temp-id-fix-v1-0-372d71f732bf@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAGuC2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEyNT3ZLU3AKgmG5aZoWuYaJRanKKuUGqsaWhElBHQVEqUBhsWnRsbS0
 AyTz+110AAAA=
X-Change-ID: 20250425-temp-id-fix-1a2ecd70e391
To: =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Hans de Goede <hdegoede@redhat.com>, Armin Wolf <W_Armin@gmx.de>
Cc: platform-driver-x86@vger.kernel.org, Dell.Client.Kernel@dell.com, 
 linux-kernel@vger.kernel.org, Kurt Borja <kuurtb@gmail.com>, 
 kernel test robot <lkp@intel.com>, Dan Carpenter <dan.carpenter@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=564; i=kuurtb@gmail.com;
 h=from:subject:message-id; bh=pDgkUVe28oVTN5MSvErUnjN2xGQ1drBuKrCY7rObOoM=;
 b=owGbwMvMwCUmluBs8WX+lTTG02pJDBnc6wQUP6yZWv3Ef6PHuuCqd9GXp4kvti0SsF4cL5t+d
 vUyK/3WjlIWBjEuBlkxRZb2hEXfHkXlvfU7EHofZg4rE8gQBi5OAZiIRwLDfz+vXE6Opt/pB3Tt
 vCWluxV4qpY8WbpiQoPZj/MtARPun2X4X8BYu36mXpiiy4cJpx61Tjjwzbr+wIfa/a5z8sP/T5N
 s4wcA
X-Developer-Key: i=kuurtb@gmail.com; a=openpgp;
 fpr=54D3BE170AEF777983C3C63B57E3B6585920A69A
X-Endpoint-Received: by B4 Relay for kuurtb@gmail.com/default with auth_id=387
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Ilpo,

These are based on the for-next branch. Thanks!

Signed-off-by: Kurt Borja <kuurtb@gmail.com>
---
Kurt Borja (2):
      platform/x86: alienware-wmi-wmax: Fix uninitialized bitmap in awcc_hwmon_fans_init()
      platform/x86: alienware-wmi-wmax: Fix awcc_hwmon_fans_init() label logic

 drivers/platform/x86/dell/alienware-wmi-wmax.c | 17 ++++++++---------
 1 file changed, 8 insertions(+), 9 deletions(-)
---
base-commit: 981527828c301644bc4014faa9c523e8a5e32a32
change-id: 20250425-temp-id-fix-1a2ecd70e391

Best regards,
-- 
 ~ Kurt

