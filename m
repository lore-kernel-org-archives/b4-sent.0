From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH 0/2] serial: add Ambarella CV75 8250_dw quirks
Date: Fri, 09 Oct 2026 18:59:57 +0800
Message-Id: <20261009-cv75-uart-v1-0-38c098efaa99@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAC3JyGoC/yXMQQqAIBBA0avErBPUzKirRAuzqaZFhWYE4d2zW
 j74/Bs8OkIPTXaDw5M8bWuCyDOws1knZDQkg+RSC84rZs+qZMG4gyllNJd1r20hIPW7w5Gu79V
 2v33oF7THO4AYH1MDUtVtAAAA
X-Change-ID: 20261007-cv75-uart-44a6029b6c31
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, linux-serial@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>, Long Zhao <zl020895@163.com>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791543601; l=1588;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=neVZVTGq666oWAg78l5pu/vXnnOetgC6TABJJdn6H6U=;
 b=UDsqMyCeNg+ceA9+UGB3+s8T/RKumgGDR1bj2HJxvAUybi0k6HA0umzSTH8mMAFDByMHfPa4s
 y5Nd+VU1TdeCOOSBzhqSo2BYIg4XLI/HBf+5s69cAhW8AyfTIukmAvB
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Split from the combined CV75 bring-up series. The 8250_dw driver does
not depend on ARCH_AMBARELLA. The binding uses the ambarella vendor
prefix, which is added by the SoC series and is not in mainline yet;
dt_binding_check needs that prefix.

These patches match the UART patches in the combined v9.

Link: https://patch.msgid.link/20261001-cv75-v5-v9-0-486cc289a4b8@ambarella.com

To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
To: Jiri Slaby <jirislaby@kernel.org>
To: linux-serial@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: Ilpo Järvinen <ilpo.jarvinen@linux.intel.com>
Cc: Rob Herring <robh@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>
Cc: Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Cc: Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: Long Zhao <longzhao@ambarella.com>
Cc: Long Zhao <zl020895@163.com>
Cc: linux-kernel@vger.kernel.org

Assisted-by: LLM
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
Long Zhao (2):
      dt-bindings: serial: snps-dw-apb-uart: add ambarella,cv75-uart
      serial: 8250_dw: add Ambarella CV75 quirks

 .../bindings/serial/snps-dw-apb-uart.yaml          |  1 +
 drivers/tty/serial/8250/8250_dw.c                  | 32 ++++++++++++++++++++++
 2 files changed, 33 insertions(+)
---
base-commit: 34cf6dafc47441dfb6b356a095b89c3585a93714
change-id: 20261007-cv75-uart-44a6029b6c31

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

