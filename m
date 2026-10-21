From: Han Gao <gaohan@iscas.ac.cn>
Date: Thu, 22 Oct 2026 03:53:37 +0800
Subject: [PATCH 17/18] riscv: defconfig: enable A210 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-a210-init-v1-17-5e438f972d24@iscas.ac.cn>
References: <20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn>
In-Reply-To: <20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Icenowy Zheng <uwu@icenowy.me>, 
 Drew Fustini <fustini@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792612403; l=1130;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=dnd96ga447dSomCEFGKgHYHO1dgeChmNdmNaEUIrQdc=;
 b=4oI+L0gaFzDPLPpdDhyxx3Mn6LIC9zoATjnBz6K1sg/1+RbNn1u3FS1JPzIuujkKpmHF9PBPd
 QgUh9R+ImaCBrNIwb3pBWor/y7MvG78CUjod+4dHnHByEJTEUiZxHoS
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable A210 platform drivers and reserve ten 8250 UART ports.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 arch/riscv/configs/defconfig | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/riscv/configs/defconfig b/arch/riscv/configs/defconfig
index 04ae305d5511..b9b3bca12089 100644
--- a/arch/riscv/configs/defconfig
+++ b/arch/riscv/configs/defconfig
@@ -33,6 +33,7 @@ CONFIG_SOC_STARFIVE=y
 CONFIG_ARCH_SUNXI=y
 CONFIG_ARCH_TENSTORRENT=y
 CONFIG_ARCH_THEAD=y
+CONFIG_ARCH_ZHIHE=y
 CONFIG_ARCH_ULTRARISC=y
 CONFIG_ARCH_VIRT=y
 CONFIG_ARCH_CANAAN=y
@@ -149,6 +150,8 @@ CONFIG_KEYBOARD_GPIO=y
 CONFIG_KEYBOARD_SUN4I_LRADC=m
 CONFIG_SERIAL_8250=y
 CONFIG_SERIAL_8250_CONSOLE=y
+CONFIG_SERIAL_8250_NR_UARTS=10
+CONFIG_SERIAL_8250_RUNTIME_UARTS=10
 CONFIG_SERIAL_8250_DW=y
 CONFIG_SERIAL_OF_PLATFORM=y
 CONFIG_SERIAL_EARLYCON_RISCV_SBI=y
@@ -167,6 +170,7 @@ CONFIG_SPI_PL022=m
 CONFIG_SPI_SIFIVE=y
 CONFIG_SPI_SUN6I=y
 # CONFIG_PTP_1588_CLOCK is not set
+CONFIG_PINCTRL_A210=y
 CONFIG_PINCTRL_TH1520=y
 CONFIG_PINCTRL_SOPHGO_CV1800B=y
 CONFIG_PINCTRL_SOPHGO_CV1812H=y

-- 
2.55.0

