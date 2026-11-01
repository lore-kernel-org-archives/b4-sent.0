From: Han Gao <gaohan@iscas.ac.cn>
Subject: [PATCH 0/2] riscv: dts: sifive: Add the missing FU740 CLINT
Date: Sun, 01 Nov 2026 21:35:30 +0800
Message-Id: <20261101-b4-sifive-fu740-clint-v1-0-b4821199a733@iscas.ac.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACNA52oC/x3MwQrCMAyA4VcZORtoarHOV5EdZk00IJ00WxHK3
 n3F43f4/wbGRdngNjQoXNV0yR10GiC95/xi1Gc3eOcvRI7wEdBUtDLKFoPD9NG8Yhqj52uQM0W
 C3n4Li/7+3/u07wddh7XwZwAAAA==
X-Change-ID: 20261101-b4-sifive-fu740-clint-c972e84f3171
To: Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Anup Patel <anup@brainfault.org>, 
 Conor Dooley <conor@kernel.org>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: Yao Zi <me@ziyao.cc>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Han Gao <rabenda.cn@gmail.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793540132; l=659;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=zbiSOQWLdGE5tt0JW6MLdKrOIrFoJPTWAw/TL/wVUds=;
 b=HiUmzTmHTD+hCzm1soKt+gVyAuz6OzLSGaBME2Y8KVey3oK63FqARxKpGB4WVNO4kQgONpIw/
 g6yZvvpQZPXAnV4tdPN6zzPRMc/F2GB0hcJjkJ6stm1a9txHQFvLPij
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

coreboot and U-Boot already describe the FU740 CLINT for OpenSBI.
Add the missing node to the Linux device tree and document its
compatible.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
Han Gao (2):
      dt-bindings: timer: add the FU740 CLINT
      riscv: dts: sifive: describe the FU740 CLINT

 Documentation/devicetree/bindings/timer/sifive,clint.yaml |  1 +
 arch/riscv/boot/dts/sifive/fu740-c000.dtsi                | 11 +++++++++++
 2 files changed, 12 insertions(+)
---
base-commit: cbbddb6b08cc9900a87cccaa9b22bbe06aa4f50a
change-id: 20261101-b4-sifive-fu740-clint-c972e84f3171

Best regards,
-- 
Han Gao <gaohan@iscas.ac.cn>

