From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH 0/2] Input: synaptics-rmi4 - support capacitive keys
Date: Mon, 07 Jul 2025 21:54:24 +0200
Message-Id: <20250707-rmi4_f1a-v1-0-838d83c72e7f@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPAlbGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDcwNz3aLcTJP4NMNEXXOjtJS05LSkVEMzEyWg8oKi1LTMCrBR0bG1tQA
 yrW3yWgAAAA==
X-Change-ID: 20250707-rmi4_f1a-72fdfcfbe164
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751918097; l=863;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=oF91pBiPsZSokRv+yeOUOLKFw0wkKXlMGWEA4NgRpRo=;
 b=OFzkxImMWeQxuZDTo4mVWBh591E3DHDwdQJKBMJSwQAaSxdLc3bYjfvJ3sgQHx4wZOpuVNfpX
 U9e730KsGKEBH9pGWTE6B7nTAhTEDWcuqVeIo2JIDhsc4nDrug+MTTX
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for touch keys found in some Synaptics touch controller
configurations.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
André Apitzsch (2):
      dt-bindings: input: syna,rmi4: Document F1A function
      Input: synaptics-rmi4 - add support for F1A

 .../devicetree/bindings/input/syna,rmi4.yaml       |  20 +++
 drivers/input/rmi4/Kconfig                         |   7 +
 drivers/input/rmi4/Makefile                        |   1 +
 drivers/input/rmi4/rmi_bus.c                       |   3 +
 drivers/input/rmi4/rmi_driver.h                    |   1 +
 drivers/input/rmi4/rmi_f1a.c                       | 145 +++++++++++++++++++++
 6 files changed, 177 insertions(+)
---
base-commit: 26ffb3d6f02cd0935fb9fa3db897767beee1cb2a
change-id: 20250707-rmi4_f1a-72fdfcfbe164

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

