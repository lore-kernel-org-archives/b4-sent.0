From: Joel Selvaraj <foss@joelselvaraj.com>
Subject: [PATCH 0/4] Update my email address
Date: Wed, 09 Sep 2026 01:11:58 -0700
Message-Id: <20260909-update-email-address-v1-0-94a240f9469e@joelselvaraj.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTtJwWioVzEuxvYHhiiSDhASw
 t2puvwW721kSAqjW7FRwqKmnyGjPBUUOhlasMZsqlx1dd7VPI9RJjDeoi+WGBPMGBAEj+Zy9iX
 ldExodP1t74+/bX72CNP3Rft+AOhrz7Z4AAAA
X-Change-ID: 20260908-update-email-address-eeaec9ef5391
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, Joel Selvaraj <foss@joelselvaraj.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788941524; l=985;
 i=foss@joelselvaraj.com; s=20260909; h=from:subject:message-id;
 bh=9dMkHMleRdbFXq/Tngq9Z7Icy4JxHXPrtaDymmuML0o=;
 b=jiHVWBP063DjZH2azjp48G9TpUTak2H2UEhlwqzRmb5KYIzCgfIHDAhlaCa9tVAYPf+XT+5Wk
 cQ54I+X6ziHBNNAf+ezwTiBNaAxrbOp5X0hxQUAS7kDfDUwFNviY1JQ
X-Developer-Key: i=foss@joelselvaraj.com; a=ed25519;
 pk=UUJ1v4UQJ/nljqj3NjsWt5H4mphWQ7etpQ4Z7JiR2yo=
X-Endpoint-Received: by B4 Relay for foss@joelselvaraj.com/20260909 with auth_id=1018
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

My jsfamily.in email address is no longer active, so update the kernel
tree to use my current address instead.

Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
---
Joel Selvaraj (4):
      mailmap: update Joel Selvaraj's email address
      MAINTAINERS: update Joel Selvaraj's email address
      dt-bindings: display: panel: ebbg,ft8719: update Joel Selvaraj's email address
      drm/panel: ebbg-ft8719: update Joel Selvaraj's email address

 .mailmap                                                         | 1 +
 Documentation/devicetree/bindings/display/panel/ebbg,ft8719.yaml | 2 +-
 MAINTAINERS                                                      | 2 +-
 drivers/gpu/drm/panel/panel-ebbg-ft8719.c                        | 4 ++--
 4 files changed, 5 insertions(+), 4 deletions(-)
---
base-commit: a9d7ced84989ec05be09b4b8428759ef60450a0f
change-id: 20260908-update-email-address-eeaec9ef5391

Best regards,
--  
Joel Selvaraj <foss@joelselvaraj.com>

