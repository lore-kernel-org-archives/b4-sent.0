From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH 0/2] can: flexcan: add transceiver capabilities
Date: Tue, 11 Feb 2025 14:12:32 +0100
Message-Id: <20250211-flexcan-add-transceiver-caps-v1-0-c6abb7817b0f@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMBMq2cC/x3MwQqDMAwA0F+RnA3UIkr3K8NDSNMtIJ0kQwTx3
 y0e3+Wd4GIqDq/uBJNdXX+1Yeg74C/Vj6DmZoghjkMMCcsqB1NFyhn/RtVZdBdDps1x5lLSGAK
 nOEErNpOix9O/l+u6ATJiZQJuAAAA
X-Change-ID: 20241209-flexcan-add-transceiver-caps-7cff9400c926
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739279554; l=821;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=pHH/VEEhxtp933DBvxvTJBeVNZvU1cFfZn4f6xruDAg=;
 b=WlTqqLZLzBKjiYAoPHIMvVBaRbXtH8tZTHH4nAvNgXwPAyXvmeaavGtHuHWYTXerNY6+kR+Vs
 Q1/h0A2wtWOAYmXfjSNsvY9kjhfJfGlBgebQ1JWOEA9bwW7YMN7AltP
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the flexcan driver does not support adding PHYs. Add the
capability to ensure that the PHY is in operational state when the link
is set to an "up" state.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Dimitri Fedrau (2):
      dt-bindings: can: fsl,flexcan: add transceiver capabilities
      can: flexcan: add transceiver capabilities

 .../devicetree/bindings/net/can/fsl,flexcan.yaml   |  3 +++
 drivers/net/can/flexcan/flexcan-core.c             | 25 ++++++++++++++++------
 drivers/net/can/flexcan/flexcan.h                  |  1 +
 3 files changed, 23 insertions(+), 6 deletions(-)
---
base-commit: 25cc469d6d344f5772e9fb6a5cf9d82a690afe68
change-id: 20241209-flexcan-add-transceiver-caps-7cff9400c926

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

