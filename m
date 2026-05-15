From: Jia Wang <wangjia@ultrarisc.com>
Date: Fri, 15 May 2026 09:18:05 +0800
Subject: [PATCH 9/9] riscv: defconfig: enable ARCH_ULTRARISC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-ultrarisc-pinctrl-v1-9-bf559589ea8a@ultrarisc.com>
References: <20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com>
In-Reply-To: <20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>
Cc: Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778807890; l=681;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=mQUrNpHmImAQll8Ku4hP3FOcTP1mWHcrN/GQ55X+mwU=;
 b=rW2qhP7IrKxExw+g4gJleU/MrAUEhaKmMhuGcdOG+RtY0KMyatlMSfNTeHSuSxbWMM36rDjGg
 hsqzqaDJQN0BUcaVrGPI7kuRezqEaJ8TXYPwir9hh3/UGPzd5k3Q2ZQ
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable `ARCH_ULTRARISC` in the default RISC-V defconfig.

Link: https://lore.kernel.org/lkml/20260427-ultrarisc-pcie-v4-1-98935f6cdfb5@ultrarisc.com/

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 arch/riscv/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/riscv/configs/defconfig b/arch/riscv/configs/defconfig
index c2c37327b987..9fdc4d1831ed 100644
--- a/arch/riscv/configs/defconfig
+++ b/arch/riscv/configs/defconfig
@@ -32,6 +32,7 @@ CONFIG_SOC_STARFIVE=y
 CONFIG_ARCH_SUNXI=y
 CONFIG_ARCH_TENSTORRENT=y
 CONFIG_ARCH_THEAD=y
+CONFIG_ARCH_ULTRARISC=y
 CONFIG_ARCH_VIRT=y
 CONFIG_ARCH_CANAAN=y
 CONFIG_SMP=y

-- 
2.34.1

