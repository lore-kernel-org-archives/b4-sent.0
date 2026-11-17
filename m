From: Han Gao <gaohan@iscas.ac.cn>
Subject: [PATCH 0/2] riscv: eswin: Add Milk-V Megrez board support
Date: Wed, 18 Nov 2026 03:55:30 +0800
Message-Id: <20261118-eic7700-megrez-v1-0-af8334b88336@iscas.ac.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADKx/GoC/x3MQQqAIBBA0avIrBMcQY2uEi1CR5tFFgoRhXdPW
 r7F/y9UKkwVJvFCoYsrH7kDBwF+W3MiyaEbtNIWEUdJ7J1TSu6UCj0SrTLOR29NiNCjs1Dk+x/
 OS2sfrrnwOWAAAAA=
X-Change-ID: 20261118-eic7700-megrez-16057cfc65df
To: Min Lin <linmin@eswincomputing.com>, 
 Pinkesh Vaghela <pinkesh.vaghela@einfochips.com>, 
 Pritesh Patel <pritesh.patel@einfochips.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: Han Gao <rabenda.cn@gmail.com>, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794945342; l=739;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=s70wK3Auzgo6TLA/RXGdm+I3YntJAM80eQtRuGWOSC0=;
 b=oZFjfqk5hUK3/iCI+Qr7pcvtX1sRDc8ZbKiPQR1MMGhKZHiCb4UJArfcFl28fe1Lx4Tv4Wz+S
 Q+YOnpJDuv8Au4nHUIInINehCJNei+kZoZ/tbppfDh9EvJv86Vcw+JY
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Milk-V Megrez is a Mini-ITX board based on the ESWIN EIC7700X SoC.

This series documents the board compatible and adds a minimal device
tree that enables UART0 on the USB-C debug port as the serial console.

---
Han Gao (2):
      dt-bindings: riscv: eswin: Add Milk-V Megrez
      riscv: dts: eswin: Add Milk-V Megrez board

 Documentation/devicetree/bindings/riscv/eswin.yaml |  1 +
 arch/riscv/boot/dts/eswin/Makefile                 |  1 +
 arch/riscv/boot/dts/eswin/eic7700-milkv-megrez.dts | 25 ++++++++++++++++++++++
 3 files changed, 27 insertions(+)
---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261118-eic7700-megrez-16057cfc65df

Best regards,
-- 
Han Gao <gaohan@iscas.ac.cn>

