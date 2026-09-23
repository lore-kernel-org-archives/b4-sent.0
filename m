From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Subject: [PATCH 0/2] Add bus clock for t7-thermal sensor
Date: Wed, 23 Sep 2026 13:51:01 +0200
Message-Id: <20260923-fix-t7-thermal-clock-v1-0-7d4c4682f182@aliel.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvxJ7bkGlkvpKdDDbcsksNCKI/p50H
 JiZBxJFpgRd8UCkixPvIYMsC7DOhIWQp8yghGpEqxTOfOOp8XQUN+PR+t2uKGtpxDhXumoIcnp
 Eyt6/7Yf3/QBuLdd2ZgAAAA==
X-Change-ID: 20260922-fix-t7-thermal-clock-151a0bf4746e
To: Guillaume La Roque <glaroque@baylibre.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>
Cc: Conor Dooley <conor.dooley@microchip.com>, linux-pm@vger.kernel.org, 
 linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1539;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=mNVNZhOFGrZFEhWuUYugPaoxFl6qri6EXLAgumV6vFE=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9bmvWUcTfONOQ+JLFLVT/w7Z84cqUi9afNTTVhWX1p8s
 9flSqtDRykLgxgXg6yYIkv/XMsT7y4fPfN1j3oKzBxWJpAhDFycAjCRtVkM/yu4g61POIqx7ja/
 4fWg3maegO/iK2s3VS2XWB1nPUdnaybDX4Euvuq/806cm/jlLltPcmHG1HZzu8JeQw63i2FdhbP
 m8gIA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The t7 thermal sensor requires a bus clock, gating register access to
the sensor, in addition to the functional clock that is already
described and shared between sensors on other Amlogic SoCs.

This series first extends the devicetree binding to describe this
second clock, making it mandatory only for the t7-thermal compatible
so other SoCs are unaffected, then updates the driver to use the
clk_bulk API instead of a single struct clk, so it can transparently
handle however many clocks a given compatible declares.

`dt_binding_check DT_SCHEMA_FILES=amlogic,thermal.yaml` is ok

  CHKDT   ./Documentation/devicetree/bindings
warning: python package 'yamllint' not installed, skipping
  STYLE   ./Documentation/devicetree/bindings
  DTEX    Documentation/devicetree/bindings/thermal/amlogic,thermal.example.dts
  DTC [C] Documentation/devicetree/bindings/thermal/amlogic,thermal.example.dtb

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
Ronald Claveau (2):
      dt-bindings: thermal: amlogic: describe bus clock for t7-thermal
      thermal/drivers/amlogic: switch to clk_bulk API to support multiple clocks

 .../bindings/thermal/amlogic,thermal.yaml          | 29 ++++++++++++++++++++--
 drivers/thermal/amlogic_thermal.c                  | 14 ++++++-----
 2 files changed, 35 insertions(+), 8 deletions(-)
---
base-commit: a8c591ed6b672915e0be57843f943a2a723aff40
change-id: 20260922-fix-t7-thermal-clock-151a0bf4746e

Best regards,
-- 
Ronald Claveau <linux-kernel-dev@aliel.fr>

