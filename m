From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Subject: [PATCH v2 0/2] Add bus clock for t7-thermal sensor
Date: Wed, 23 Sep 2026 16:37:49 +0200
Message-Id: <20260923-fix-t7-thermal-clock-v2-0-bff7a09eb487@aliel.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NwQ6CMBBEf4Xs2TXtWgE5+R+GQy1b2VjBtIRoC
 P9uJfHm8U1m3iyQOAonaIoFIs+SZBwy0K4A19vhxihdZiBFpToRoZcXThVOPceHDejC6O6oj9q
 qqzeVKRny9Bk59zbtpc3cS5rG+N5eZv1Nf8LDf+GsUWHVGWfKmryu6WyDcNj7CO26rh8EHeEqt
 wAAAA==
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
 linux-kernel@vger.kernel.org, Ronald Claveau <linux-kernel-dev@aliel.fr>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1800;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=Y3h9ArEWxXcDcNW3RYT0QJFPRTqLKdurS6G4EidafJU=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9bmJyEctuu2dqfnFzqvZN2sWn44N1h4mSj/3ZNv9Dhfz
 dv0Uk2ro5SFQYyLQVZMkaV/ruWJd5ePnvm6Rz0FZg4rE8gQBi5OAZjIrXyG/5XHvwmcyOXX4Gc5
 dOlmx//kLje14NkXpO7lZny0Vcldc5DhfzDr4xmlD82+6HTqvVhV7lTdsYjfaf/9NYvK18nuE2l
 w5gMA
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
Changes in v2:
- PATCH 1: Fix commit message. Thanks to Krzysztof review.
- PATCH 2: Return an error when no clock provided. Thanks to sashiko's review.
- Link to v1: https://lore.kernel.org/r/20260923-fix-t7-thermal-clock-v1-0-7d4c4682f182@aliel.fr

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

