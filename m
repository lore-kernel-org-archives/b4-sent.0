From: Yang Li <yang.li@amlogic.com>
Subject: [PATCH BlueZ bluez v2 0/2] bass: Support for Encrypted Broadcast
 Source
Date: Thu, 12 Jun 2025 13:31:00 +0800
Message-Id: <20250612-bass_for_encrypted_broadcast_source-v2-0-9128a437b595@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABRmSmgC/5WNWwqDMBBFt1LmuynGakz71X0UkTwmGlAjE5Vac
 e8N7qCf5144Z4eI5DHC87ID4eqjD2OC/HoB06mxReZtYsizvMwE50yrGBsXqMHR0DbNaBtNQVm
 j4tzEsJBB5oQseOUsYnWHZJoInf+clTfofsEv1GnufJwDbWd75ef5V2bljDPx0FLzUhRSmpca+
 tB6czNhgPo4jh8I43wV3wAAAA==
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749706270; l=733;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=2xaDBbW3p/NzxFMw5RbplFMMUhcZCtv2lWoQPaPTm3Q=;
 b=V+XJYm64c1F1XqC7ASdiFawab3nrp/zbYuh2WhsF9O60camRyQiciel4s7MQyIIVXIWxnbWS1
 rjBPO/yDRM4Aqb8YnEF03INZ5VS7q/TZ0oTPQSwpZsbLvty1i+0EHVw
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v2:
- Submit shared/bass.c separately.
- Add necessary comments.
- Link to v1: https://patch.msgid.link/20250611-bass_for_encrypted_broadcast_source-v1-1-69b8b156488c@amlogic.com

---
Yang Li (2):
      bass: support for encrypted broadcast source
      shared/bass: Move cb->handle earlier in the flow

 profiles/audio/bass.c | 32 ++++++++++++++++++++++++++++++++
 src/shared/bass.c     | 29 ++++++++++++++---------------
 2 files changed, 46 insertions(+), 15 deletions(-)
---
base-commit: 95b72bbf1fe42216d02a5ebb99bd18e9b69b6064
change-id: 20250611-bass_for_encrypted_broadcast_source-f68417fdee73

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

