From: Han Gao <gaohan@iscas.ac.cn>
Subject: [PATCH 0/2] riscv: dts: sophgo: Enable the RTC on SG2042 EVB v1/v2
Date: Sun, 22 Nov 2026 21:33:50 +0800
Message-Id: <20261122-sg2042-evb-rtc-v1-0-f222c64cc7b9@iscas.ac.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD7vAmsC/x3MQQqAIBBA0avErBvIoUy6SrTIGms2FhoSiHdPW
 r7F/xkiB+EIU5MhcJIol69QbQPbufqDUfZqoI60UkQYD+p6Qk4Ww7OhsdqSHdxoBoYa3YGdvP9
 wXkr5AKcMWRtgAAAA
X-Change-ID: 20261122-sg2042-evb-rtc-8b6b2b5f785e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Chen Wang <chen.wang@linux.dev>, 
 Inochi Amaoto <inochiama@gmail.com>
Cc: Han Gao <rabenda.cn@gmail.com>, devicetree@vger.kernel.org, 
 sophgo@lists.linux.dev, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795354439; l=724;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=0g/iv1tZgTdpWri/xql23J0iaDx4fUB3t4ZFsEz3YN4=;
 b=+5BwCbRV7xK/ReufgCCIT6UzmxknvULqgSgcG+xyvC6vOI7S0jEuMmD18uEGiD1Je+eiuaHCt
 rRquTEvpn5BDC8eQ5IWRVv6NUO3WiNZRlI+VTwGcvpYze/OF3cpsml3
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both SG2042 EVB boards have a PT7C4307 RTC on I2C0, same as the
Milk-V Pioneer. Enable it on both.

Datasheet: https://datasheet.octopart.com/PT7C4307WE-Diodes-Inc.-datasheet-180988416.pdf

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
Han Gao (2):
      riscv: dts: sophgo: Enable the RTC on SG2042 EVB v1
      riscv: dts: sophgo: Enable the RTC on SG2042 EVB v2

 arch/riscv/boot/dts/sophgo/sg2042-evb-v1.dts | 21 +++++++++++++++++++++
 arch/riscv/boot/dts/sophgo/sg2042-evb-v2.dts | 21 +++++++++++++++++++++
 2 files changed, 42 insertions(+)
---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261122-sg2042-evb-rtc-8b6b2b5f785e

Best regards,
-- 
Han Gao <gaohan@iscas.ac.cn>

