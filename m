From: Han Gao <gaohan@iscas.ac.cn>
Subject: [PATCH v2 0/2] clk: sophgo: sg2042: Keep gates used by firmware
 enabled
Date: Sun, 22 Nov 2026 02:18:03 +0800
Message-Id: <20261122-b4-sg2042-efi-rtc-v2-0-6d087e03e4e8@iscas.ac.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NwQ6CMBBEf4Xs2SV0LQqe/A/DoZQV1gOYbiUaw
 r9b8O7xZWbeLKAchBUu2QKBZ1GZxgR0yMAPbuwZpUsMVNDJGDLYWtSeCkvId8EQPbLtSiIqzdE
 xpN0zpOS9O2/Nj/XVPtjHTbQ1BtE4hc9+Oput988/GyzQ1FVdtZXrbH2+inqnufO5H6FZ1/ULo
 QssGcYAAAA=
X-Change-ID: 20261121-b4-sg2042-efi-rtc-e4d5222513ae
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen Wang <chen.wang@linux.dev>, 
 Inochi Amaoto <inochiama@gmail.com>, Yao Zi <me@ziyao.cc>
Cc: Chen Wang <unicorn_wang@outlook.com>, Han Gao <rabenda.cn@gmail.com>, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 sophgo@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795285099; l=2101;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=JKiIHEduS5hiyWa/DdSePRqv7K8ib23Oio2mSrLYzzE=;
 b=XWWBF8jXOUX1HUf4l5WASPoIi5NGWrSK+caiEitu8JsDdG/2CvTfkI2bnU89QdZszlgeJapa8
 IJlfO1uGxpxBmw3X+sg0e100TBClDGnH9+QrWivGNSMX6UySEyjD9ab
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Milk-V Pioneer, firmware uses I2C0 for the EFI RTC and the serial
flash for its own image and EFI variables. Both sit behind clock gates
shared with devices Linux drives, so runtime PM on the Linux side can
turn them off under the firmware, and GetTime() returns EFI_NOT_READY.

Let firmware list such gates in protected-clocks on the clkgen node,
and keep them enabled.

qcom, the only current user of protected-clocks, does not register such
clocks at all. That would break the I2C controllers Linux uses, as the
DesignWare driver needs the clock rate, so here they stay registered and
are only kept on. I'm not sure this fits the intended use; suggestions
welcome.

Tested on Milk-V Pioneer.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
Changes in v2:
- Drop the EFI MMIO patch, Ard is taking it through the EFI tree
- Use protected-clocks instead of scanning reserved nodes under /soc
  (Krzysztof)
- Document protected-clocks in the binding
- Link to v1: https://patch.msgid.link/20261121-b4-sg2042-efi-rtc-v1-0-19898b8ad497@iscas.ac.cn

To: Stephen Boyd <sboyd@kernel.org>
To: Brian Masney <bmasney+clk@redhat.com>
To: Jerome Brunet <jbrunet+clk@baylibre.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Chen Wang <chen.wang@linux.dev>
To: Inochi Amaoto <inochiama@gmail.com>
Cc: Chen Wang <unicorn_wang@outlook.com>
Cc: linux-clk@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: sophgo@lists.linux.dev
Cc: linux-kernel@vger.kernel.org

---
Han Gao (2):
      dt-bindings: clock: sophgo: Allow protected gate clocks on SG2042
      clk: sophgo: Keep SG2042 gates listed in protected-clocks enabled

 .../devicetree/bindings/clock/sophgo,sg2042-clkgen.yaml  |  2 ++
 drivers/clk/sophgo/clk-sg2042-clkgen.c                   | 16 ++++++++++++++--
 2 files changed, 16 insertions(+), 2 deletions(-)
---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261121-b4-sg2042-efi-rtc-e4d5222513ae

Best regards,
--  
Han Gao <gaohan@iscas.ac.cn>

