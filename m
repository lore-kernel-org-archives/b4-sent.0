From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Subject: [PATCH v2 0/2] Add Reset GPIO to imx258
Date: Sat, 29 Aug 2026 16:06:32 +0300
Message-Id: <20260829-imx258-add-reset-gpio-patch-v2-0-bfd27891e225@mainlining.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ6DIBCF4asY1p0GoSp21Xs0LgiMOEkFAsbYG
 O9eatJtl/9bfG9nGRNhZvdqZwlXyhR8CXGpmJm0dwhkSzPBRcuVaIDmTTQKtLWQMOMCLlKAqBc
 zgblJZa1sxt4YVoSYcKTt1J9D6YnyEtL7PFvr7/pz1V93raGGVsq+E1bojvPHrMm/yJN315AcG
 47j+AD0X9lxywAAAA==
X-Change-ID: 20260825-imx258-add-reset-gpio-patch-c438dd35f9cc
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: git@luigi311.com, pavel@ucw.cz, tomm.merciai@gmail.com, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Muzaffer Kadir <muzafferkadir@mainlining.org>, 
 =?utf-8?q?Ond=C5=99ej_Jirman?= <megi@xff.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788008809; l=1088;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=pn5KGflifh7k3NcNdmit0vyAmA8cfWgPj83zaSLLpq0=;
 b=Qitmu8ApwZ3hUILh+CiqgQ/xGkk1ZWjMDQw2js1q0jjmynZqg0foEkzw5HLDqW0hpobWdqSzc
 L9vKIvia2Q3ClsEb/OUOD96aLdh7Xxmx3ve+XHXmxj4P3VoMENd+vHT
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I have a device that is not upstreamed yet (General Mobile Shamrock)
whose camera needs reset gpio to probe, it is documented in
dt-bindings but not implemented for some reason.
With adding it rear camera on the device probes correctly.

Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
Changes in v2:
- Moved error handling in power on to gotos as Sakari Ailus requested
- Use fsleep instead of usleep_range as Sakari Ailus requested
- Separated delay after enable and reset gpio patches as Sakari
  Ailus requested
- Link to v1: https://lore.kernel.org/r/20260828-imx258-add-reset-gpio-patch-v1-1-633972d2a700@mainlining.org

---
Muzaffer Kadir (2):
      media: i2c: imx258: Add wait after enabling
      media: i2c: imx258: Add reset-gpio support

 drivers/media/i2c/imx258.c | 25 ++++++++++++++++++++++++-
 1 file changed, 24 insertions(+), 1 deletion(-)
---
base-commit: db2ddb87143519e20a95aa36c60b36107b736a58
change-id: 20260825-imx258-add-reset-gpio-patch-c438dd35f9cc

Best regards,
-- 
Muzaffer Kadir <muzafferkadir@mainlining.org>

