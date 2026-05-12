From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Subject: [PATCH 0/2] Khadas VIM4 PWM status LED support
Date: Tue, 12 May 2026 19:47:27 +0200
Message-Id: <20260512-add-kvim4-sysled-v1-0-7178719a43e7@aliel.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBCF4auUWTvQhKRoryJdxGTUQZNqJi2V0
 rsb2uX/4H0rCGUmgb5ZIdPMwmOqoU4N+KdLD0IOtUG3umut0uhCwNfM0aD85E0Bz94re7Ha2E5
 BvX0y3XnZyetwdKbvVOVyjHBzQujHGLn0TaKl4K4bbWDYtj9QbGYBkwAAAA==
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1413;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=GdO8sMea8p5bxncxQmac1W2vVytj8wlQkstRRnaIfAw=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQxZz+l2bwpmb9nEdfroq6MT7tJSbjdYdzIs/NZ3OnCU26
 17jLKGzHaUsDGJcDLJiiiz9cy1PvLt89MzXPeopMHNYmUCGMHBxCsBEggMYGc5/zeMyzspUTWFZ
 Gl72LNu1ZZZKoHS9Wu2KmImXrJZ6JDL84VtbeO3ww98eX1LWeBjbsdTxJPh/6XSTCuKV9X3h7/S
 bCQA=
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

Patch 2 enables the pwm_ao_cd controller on the VIM4 and adds a
pwm-leds node with a heartbeat trigger. The xtal-clk node is also
moved to restore alphabetical ordering among root node children.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
Ronald Claveau (2):
      arm64: dts: amlogic: t7: Fix pwm_ao_c pinmux definitions
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

