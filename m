From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH v2 0/2] serial: 8250_dw: Add support for UltraRISC DP1000
 uart
Date: Mon, 16 Mar 2026 14:33:21 +0800
Message-Id: <20260316-ultrarisc-serial-v2-0-6ab3e7fa891c@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADGkt2kC/2WNwQ6CMBAFf4Xs2ZrSYg2e/A/DoZatrEEgbWk0h
 H+3RePF4yTz5i3g0RF6OBULOIzkaRwSiF0BptPDDRm1iUFwobjkNZv74LQjb1he6p6pylolj9h
 aoSDNJoeWnlvy0nzYz9c7mpA72ejIh9G9ts9YZu+bL9V/PpaMM1OlF4m1lPpw/il7Mz6gWdf1D
 ZrpnmvGAAAA
X-Change-ID: 20260309-ultrarisc-serial-64ff637edf26
To: =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-riscv@lists.infradead.org, devicetree@vger.kernel.org, 
 Jia Wang <wangjia@ultrarisc.com>, Yao Zi <me@ziyao.cc>, 
 Zhang Xincheng <zhangxincheng@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773642814; l=1529;
 i=wangjia@ultrarisc.com; s=20260309; h=from:subject:message-id;
 bh=djv1u2JNf9x0lGNw7u4dJc88RxbiQVxfUiQI1JdoKw8=;
 b=gfIW1chPaStqWtJUPKcrjAUVN4EHB+jkMVfWtWMQwkmMqfWBb+AQRgDtE21J180xBTs2tmFwu
 gUitd1zpKnYDozapFw5ml8C+MNA4RZuaJIBgJrvMzhej6L/3rdKgSFB
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=XvYkrelqJIIzobY7j+nIg8rsfv5kzaOzuc1UPhd087U=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260309 with auth_id=682
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is version 2 of the patch series.  
Previous version was sent via local SMTP, some recipients received it.  
This series is now sent via official web endpoint.

This patch series adds support for the UltraRISC DP1000 UART controller.

The series includes two patches:
1. Update device tree bindings to document the DP1000 UART compatible string
   and required properties.
2. Add driver support in the 8250_dw driver by handling the DP1000-specific
   initialization and configuration.

The patches have been tested on Ultrarisc DP1000 development board with
Linux v7.0-rc2, verifying basic UART functionality and runtime suspend/resume.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
Changes in v2:
- Rebased on Linux v7.0-rc4 (previously on v7.0-rc2).
- Reordered patch series: DT binding patch comes before driver changes.
- Updated commit message for DT binding patch.
- Link to v1: https://patch.msgid.link/20260316-ultrarisc-serial-v1-0-c464f3e933a5@ultrarisc.com

---
Jia Wang (1):
      dt-bindings: serial: update bindings of ultrarisc dp1000 uart

Zhang Xincheng (1):
      riscv: ultrarisc: 8250_dw: support DP1000 uart

 .../devicetree/bindings/serial/snps-dw-apb-uart.yaml         |  2 ++
 drivers/tty/serial/8250/8250_dw.c                            | 12 ++++++++++++
 2 files changed, 14 insertions(+)
---
base-commit: f338e77383789c0cae23ca3d48adcc5e9e137e3c
change-id: 20260309-ultrarisc-serial-64ff637edf26

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

