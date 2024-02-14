From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH BlueZ 0/4] Handful of build fixes and cleanups
Date: Wed, 14 Feb 2024 22:01:23 +0000
Message-Id: <20240214-hook-fixup-v1-0-0e158ffea140@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADM4zWUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDI0MT3Yz8/GzdtMyK0gLdNCMzYwOTJHNDYzMzJaCGgqJUoATYsOjY2lo
 AbAeMNlwAAAA=
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707948093; l=1229;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=6+21W/GlIOBI4iHR5i89+VKDs8ZAU79zcgZrIeB3E4Q=;
 b=bDFps1/ja+C/TdgQwvt3iNfcen6zyDUBzmVyHvJmiKCtYVuuots0cKTHtmYaRpmlXlsXU5iqE
 ciFA4gsckrwBIHKKuwbyoz6siWKKv2iVKELxFKcLP6D5KYBN44yovdf
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello list,

The very first patch in this series fixes a regression I've introduced
recently - sorry about that.

Namely: two separate patch series introduced an `install-data-hook` and
I didn't properly test with both combined. The former is unconditionally
set while the latter is not.

So if obex is enabled, we fail to create the config files :facepalm:

The second patch is a log pre-existing issue - we install dbus/systemd
service files, for obexd even when building with --disable-obex

The last two are trivial cleanups, so feel free to drop them if they
don't strike your interest.

---
Emil Velikov (4):
      build: fold separate install-data-hooks
      build: install obexd (dbus,systemd} services as needed
      build: drop %.rules make rule
      build: simplify coverage handling

 Makefile.am                               | 27 ++++++++++++---------------
 Makefile.obexd                            |  9 ++-------
 tools/{hid2hci.rules => 97-hid2hci.rules} |  0
 3 files changed, 14 insertions(+), 22 deletions(-)
---
base-commit: b55d98e5cc97e4ff8c3980b84f46c84f3b1c1ee3
change-id: 20240214-hook-fixup-f26304b71366

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

