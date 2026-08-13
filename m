From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH v3 0/2] Ambarella CV75: 8250_dw UART
Date: Thu, 13 Aug 2026 18:35:11 +0800
Message-Id: <20260813-cv75-v3-c-v3-0-9352b3fd6026@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN+dfWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0Nj3eQyc1PdMiCtm2JpkWhpnmKQZplmqARUX1CUmpZZATYrOhbCLy5
 NykpNLgEZoFRbCwCOiWNObQAAAA==
X-Change-ID: 20260813-cv75-v3-c-d98a97d0f9f1
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 devicetree@vger.kernel.org, Long Zhao <longzhao@ambarella.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786617317; l=1249;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=HuHAAmFhsnViNBOyFb1R8/0wMc3TeeTHz8YWaouugC0=;
 b=VMOAORclmZq65HmUV7KltmK8GgBks9rZmr6JcV8hU7pvSSLiyrHr2bDnCg6RXEVcX3/lm+5mJ
 HUV217J71GkDqo8lmeXGXQ2E+HWxuMoFZJyQOmXm1Yk7VhWZ4mP5PV3
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is part C of a 3-part CV75 v3 split:

  A: bindings + RCT/CCU clocks + SoC/EVK DT + MAINTAINERS
  B: pinctrl + PL061 GPIO variant
  C: 8250_dw UART quirks  (this series)

Depends on series A:
https://lore.kernel.org/r/20260813-cv75-v3-a-v3-0-cfdd20b1b4dd@ambarella.com

Depends on series B:
https://lore.kernel.org/r/20260813-cv75-v3-b-v3-0-1d82e18da09b@ambarella.com

Link to v2:
https://lore.kernel.org/r/20260806-longzhao-upstream-cv75-v2-v2-0-6b09707c5fe9@ambarella.com

Summary:
- document ambarella,cv75-uart on snps,dw-apb-uart
- Ambarella quirks in 8250_dw

Changes since v2 (C scope):
- drop custom Ambarella UART driver; reuse 8250_dw (Linus)

Verified on CV75 with A+B+C.

Signed-off-by: Long Zhao <longzhao@ambarella.com>

---
Long Zhao (2):
      dt-bindings: serial: snps-dw-apb-uart: add ambarella,cv75-uart
      serial: 8250_dw: add Ambarella CV75 quirks

 .../bindings/serial/snps-dw-apb-uart.yaml          |  1 +
 drivers/tty/serial/8250/8250_dw.c                  | 30 ++++++++++++++++++++++
 2 files changed, 31 insertions(+)
---
base-commit: 378c935cabe003ef440c1c79302a1f8ed7913778
change-id: 20260813-cv75-v3-c-d98a97d0f9f1

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

