From: Alexei Solcanu <alexei.solcanu@pm.me>
Subject: [PATCH v2 0/2] hwmon: (gpd-fan) Fix the second fan on duo boards,
 split Win 5 fans
Date: Sat, 26 Sep 2026 16:11:19 -0400
Message-Id: <20260926-gpd-fan-duo-auto-v2-0-0a2ea41ee3b5@pm.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NwQ6DIBAFf8XsudsAplp78j8aDyCr0kQhIKSN8
 d+L9t7jJPPmbRDIGwrwKDbwlEwwdskgLgX0k1xGQqMzg2CiYo244eg0DnJBHS3KuFq811xTQ4x
 Vuoc8c54G8z6Tz+7HIaoX9evROYzJhNX6z/mZ+OH9ySeOHEWjVFUzVZYlb918nQm6fd+/g6xiK
 r4AAAA=
X-Change-ID: 20260925-gpd-fan-duo-auto-871de9e006dc
To: Guenter Roeck <linux@roeck-us.net>, 
 Cryolitia PukNgae <cryolitia@uniontech.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, Antheas Kapenekakis <lkml@antheas.dev>, 
 Alexei Solcanu <alexei.solcanu@pm.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790453516; l=1175;
 i=alexei.solcanu@pm.me; s=20260925; h=from:subject:message-id;
 bh=U2vXcoyjbuEDV1rN+WkLDvhuZNVs8UnNjX/eoGFhfT8=;
 b=4aUxpQwyWgzTqwd4eqmjPV5XEXt9JCitYLUqqz1SAZzYTHKuuDLGftdMCe97DUrL2SlsnqvRY
 2RmvIBAaOgTCTlgJru7O2AkB5KMMgoZWkAmKFZRF4r3Nncd+bbziO/w
X-Developer-Key: i=alexei.solcanu@pm.me; a=ed25519;
 pk=iK6ervbccknflfirBb6E4x7TaOyCpnoGd33gzfiNEeo=
X-Endpoint-Received: by B4 Relay for alexei.solcanu@pm.me/20260925 with auth_id=1064
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 1 fixes pwm1_enable=2 leaving the second fan at its last manual
duty cycle on boards using gpd_duo_drvdata. It is unchanged from v1 and
is still needed on the GPD Duo, and on kernels where the Win 5 uses the
Duo settings.

Patch 2 gives the GPD Win 5 its own board data, with one fan and pwm
channel per fan. The Win 5 had one channel because it was added using
the Duo's settings, which treat both fans as one.

Tested on a GPD Win 5 (G1618-05). Not tested on the GPD Duo.

---
Changes in v2:
- Add patch 2: register both fans on the GPD Win 5 (Guenter)
- Link to v1: https://patch.msgid.link/20260925-gpd-fan-duo-auto-v1-1-29bb670b3331@pm.me

---
Alexei Solcanu (2):
      hwmon: (gpd-fan) Reset both fans to automatic on duo boards
      hwmon: (gpd-fan) Register both fans on the GPD Win 5

 Documentation/hwmon/gpd-fan.rst |  14 ++--
 drivers/hwmon/gpd-fan.c         | 147 +++++++++++++++++++++++++++-------------
 2 files changed, 108 insertions(+), 53 deletions(-)
---
base-commit: 3cbb5f15e464583e59c8501a7085ec12b53e23ac
change-id: 20260925-gpd-fan-duo-auto-871de9e006dc

Best regards,
--  
Alexei Solcanu <alexei.solcanu@pm.me>

