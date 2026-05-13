From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Subject: [PATCH v2 0/3] Khadas VIM4 PWM status LED support
Date: Wed, 13 May 2026 12:43:52 +0200
Message-Id: <20260513-add-kvim4-sysled-v2-0-3ec9779e8875@aliel.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WOyw6CMBBFf4XM2jG0lufK/zAsahlkIg9tawMh/
 LsIa5dnknPuLODIMjkoowUsBXY8DhvIUwSm1cODkOuNQcYyjRMhUdc1PgP3Ct3sOqoxN0YkRSJ
 VkgrYtJelhqc9easOtvT+bGV/HOGuHaEZ+559GQ00edzrSir4CS07P9p5fymI3fi/HgTGmIksz
 0Sh1YWyq+6YunNjoVrX9QvcaMf24AAAAA==
X-Change-ID: 20260512-add-kvim4-sysled-8cc159524561
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1706;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=EftnxsZQyEGBjcaWoej2Qgq8pVFT9h/4EhbAduCDQPA=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQxZL6E+Dmm8zlZKebY8/e8GTM21JA3vlTlZPRlXWWr5v5
 +tCFLM7SlkYxLgYZMUUWfrnWp54d/noma971FNg5rAygQxh4OIUgIm8MmJkOMXlvmlW2mKd7Z0v
 f8wz3P5e/LXY3C+rtn60nrN99pLjD9YzMvQuX+H+e2K514Oo+ley2y7ysJjHqkrFHdIt3ztJ4MO
 FA4wA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the PWM-driven status LED on the Khadas
VIM4 board (Amlogic T7).

The VIM4 exposes a heartbeat LED wired to the PWM_AO_C output, routed
through pin group pwm_ao_c_d. Before wiring it up in the board DTS,
the SoC pinmux definitions had to be corrected: the original
pwm_ao_c node was conflating two distinct pin groups (pwm_ao_c_d and
pwm_ao_c_e) into a single ambiguous entry.

Patch 1 fixes the pwm_ao_c pinmux entries in the T7 DTSI by splitting
them into two properly named nodes. Neither alternate is in use yet,
so there is no functional impact on existing boards.

Patch 2 moves the xtal-clk node to restore alphabetical ordering among
root node children.

Patch 3 enables the pwm_ao_cd controller on the VIM4 and adds a
pwm-leds node with a heartbeat trigger.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
Changes in v2:
- PATCH 2-3: Create a new patch specific to the reordering action.
             According to Neil's review.
- Link to v1: https://lore.kernel.org/r/20260512-add-kvim4-sysled-v1-0-7178719a43e7@aliel.fr

---
Ronald Claveau (3):
      arm64: dts: amlogic: t7: Fix pwm_ao_c pinmux definitions
      arm64: dts: amlogic: t7: khadas-vim4: reorder root node
      arm64: dts: amlogic: t7: khadas-vim4: add PWM-driven status LED

 .../dts/amlogic/amlogic-t7-a311d2-khadas-vim4.dts  | 30 +++++++++++++++++-----
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi        | 12 +++++++--
 2 files changed, 33 insertions(+), 9 deletions(-)
---
base-commit: 31f32e8cdf59291e467250dfc57d1a8c718f63d2
change-id: 20260512-add-kvim4-sysled-8cc159524561

Best regards,
-- 
Ronald Claveau <linux-kernel-dev@aliel.fr>

