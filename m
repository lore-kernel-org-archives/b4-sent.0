From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH v2 0/2] media: i2c: it6625: fix MCU reset and host control
 timing
Date: Wed, 07 Oct 2026 18:31:51 +0800
Message-Id: <20261007-upstream-it6625-reset-delay-v2-0-c5d6b2522bbe@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJcfxmoC/43NSw6CMBSF4a2QO/aSPqAER+zDMMBykZvII21FC
 enerazA4XcG/znAk2PycM0OcLSx52VOUJcM7NjND0Luk0EJZaQQBl+rD466CTkYo0p05ClgT89
 uR610XYrKloOoIRVWRwN/zvqtTR7Zh8Xt59kmf+t/3U2iRCrsXduqINPrhgPldpny8IY2xvgFg
 1C0QscAAAA=
X-Change-ID: 20261006-upstream-it6625-reset-delay-3239507c5f09
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791369112; l=1138;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=smebOwSVwlwQJeWZ+3B+c1LhBAaLuyJWFeH0+agWoSw=;
 b=n/mu7BNSuJnUteje4iiaMWwDjQpDsaUmpLted5+3I4AP1tNltLaPJx0rSaZtcxHdS2byzSbRO
 +gd9N/IrSVmDTQfCqVydxcHsDIthmczBZBna6SZfsEigpfAnX64ebr5
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IT6625/IT6626 are driven through an on-chip MCU. The driver does not
give the MCU enough time in two places: after releasing reset in probe,
and when waiting for the MCU to acknowledge a host control request.
Both can cause spurious failures.

Patch 1 waits 1s after reset release before the chip-ID read.
Patch 2 raises the host control request timeout from 25 ms to 250 ms.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Changes in v2:
- Patch 1: increase the post-reset wait from 700 ms to 1s.
- Patch 2: new, raise the host control request timeout to 250 ms.
- Link to v1: https://lore.kernel.org/r/20261006-upstream-it6625-reset-delay-v1-1-e4cb3c74e6d3@ite.com.tw

---
Hermes Wu (2):
      media: i2c: it6625: wait 1s after reset release
      media: i2c: it6625: allow 250 ms for host control requests to complete

 drivers/media/i2c/it6625.c | 23 +++++++++++++++++------
 1 file changed, 17 insertions(+), 6 deletions(-)
---
base-commit: 89a3d2a2237e017cdbefcb036db71ce74e67faf5
change-id: 20261006-upstream-it6625-reset-delay-3239507c5f09

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

